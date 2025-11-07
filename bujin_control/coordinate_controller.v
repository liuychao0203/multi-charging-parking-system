// ============================================================================
// 坐标控制系统模块
// 功能：实现自动坐标导航，顺序执行 X→Y→停顿→复位
// 支持钓鱼电机的自动控制
// ============================================================================

module coordinate_controller(
    input        clk,               // 系统时钟 50MHz
    input        rst_n,             // 复位信号
    
    // 坐标命令输入
    input        coord_cmd_valid,   // 坐标命令有效标志
    input  [1:0] target_x,          // 目标X坐标 (0-3)
    input  [1:0] target_y,          // 目标Y坐标 (0-3)
    
    // X轴控制输出
    output reg   x_run,             // X轴运行信号
    output reg   x_dir,             // X轴方向信号
    
    // Y轴控制输出
    output reg   y_run,             // Y轴运行信号
    output reg   y_dir,             // Y轴方向信号
    
    // 钓鱼电机控制输出
    output reg   motor_ctrl_enable, // 钓鱼电机控制使能
    output reg [1:0] motor_state,   // 钓鱼电机状态
    
    // 状态输出
    output reg   coord_enable       // 坐标控制模式使能
);

// 时间参数定义（50MHz时钟）
localparam integer X_TIME_PER_UNIT = 32'd98_350_000;   // X轴每单位时间：1.967秒
localparam integer Y_TIME_PER_UNIT = 32'd136_650_000;  // Y轴每单位时间：2.733秒
localparam integer PAUSE_TIME = 32'd3_000_000_000;     // 停顿时间：60秒
localparam integer FISHING_MOTOR_TIME = 32'd1_450_000_000;  // 钓鱼电机动作时间：29秒

// 状态机定义（独热码编码优化 - One-Hot Encoding）
// 优势：状态判断快速、时序优良、减少译码逻辑
localparam [5:0] COORD_IDLE      = 6'b000001;  // 空闲状态
localparam [5:0] COORD_MOVE_X    = 6'b000010;  // X轴移动到目标
localparam [5:0] COORD_MOVE_Y    = 6'b000100;  // Y轴移动到目标
localparam [5:0] COORD_PAUSE     = 6'b001000;  // 停顿60秒
localparam [5:0] COORD_RETURN_X  = 6'b010000;  // X轴回原点
localparam [5:0] COORD_RETURN_Y  = 6'b100000;  // Y轴回原点

// 电机状态定义
localparam [1:0] MOTOR_STOP    = 2'b00;
localparam [1:0] MOTOR_FORWARD = 2'b01;
localparam [1:0] MOTOR_REVERSE = 2'b10;

// 内部信号
reg [5:0] coord_state;  // 独热码编码：6位状态寄存器
reg [1:0] current_x, current_y;
reg [1:0] target_x_reg, target_y_reg;
reg [31:0] move_timer;
reg [31:0] pause_timer;

// 预计算的目标时间值（避免实时乘法运算，优化时序）
reg [31:0] target_time;

// 优化：添加输出寄存器流水线
reg x_run_r, x_dir_r;
reg y_run_r, y_dir_r;
reg motor_ctrl_enable_r;
reg [1:0] motor_state_r;

// 时序优化：添加比较结果寄存器（将比较逻辑从关键路径中分离）
reg timer_done_stage1;
reg timer_done_stage2;
reg pause_phase1_stage1;  // pause_timer < FISHING_MOTOR_TIME
reg pause_phase2_stage1;  // pause_timer < 2*FISHING_MOTOR_TIME
reg pause_done_stage1;    // pause_timer >= PAUSE_TIME

// 时序优化：将大计数器的增量运算流水线化
reg [31:0] move_timer_next;
reg [31:0] pause_timer_next;

// X轴时间查找表
function [31:0] get_x_time;
    input [1:0] units;
    begin
        case(units)
            2'd0: get_x_time = 32'd0;
            2'd1: get_x_time = X_TIME_PER_UNIT;
            2'd2: get_x_time = X_TIME_PER_UNIT * 2;
            2'd3: get_x_time = X_TIME_PER_UNIT * 3;
        endcase
    end
endfunction

// Y轴时间查找表
function [31:0] get_y_time;
    input [1:0] units;
    begin
        case(units)
            2'd0: get_y_time = 32'd0;
            2'd1: get_y_time = Y_TIME_PER_UNIT;
            2'd2: get_y_time = Y_TIME_PER_UNIT * 2;
            2'd3: get_y_time = Y_TIME_PER_UNIT * 3;
        endcase
    end
endfunction

// ============================================================================
// 时序优化：流水线比较器（第1级 - 计算下一个计数值）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        move_timer_next <= 32'd0;
        pause_timer_next <= 32'd0;
    end else begin
        move_timer_next <= move_timer + 1'b1;
        pause_timer_next <= pause_timer + 1'b1;
    end
end

// ============================================================================
// 时序优化：流水线比较器（第2级 - 比较操作）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        timer_done_stage1 <= 1'b0;
        timer_done_stage2 <= 1'b0;
        pause_phase1_stage1 <= 1'b0;
        pause_phase2_stage1 <= 1'b0;
        pause_done_stage1 <= 1'b0;
    end else begin
        // 移动定时器比较（使用预增量值）
        timer_done_stage1 <= (move_timer_next >= target_time);
        timer_done_stage2 <= timer_done_stage1;
        
        // 暂停定时器比较（使用预增量值）
        pause_phase1_stage1 <= (pause_timer_next < FISHING_MOTOR_TIME);
        pause_phase2_stage1 <= (pause_timer_next < (FISHING_MOTOR_TIME + FISHING_MOTOR_TIME));
        pause_done_stage1 <= (pause_timer_next >= PAUSE_TIME);
    end
end

// 坐标控制状态机（优化版：输出使用流水线寄存器）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        coord_state <= COORD_IDLE;
        current_x <= 2'b00;
        current_y <= 2'b00;
        target_x_reg <= 2'b00;
        target_y_reg <= 2'b00;
        move_timer <= 32'd0;
        pause_timer <= 32'd0;
        target_time <= 32'd0;
        coord_enable <= 1'b0;
        x_run_r <= 1'b0;
        x_dir_r <= 1'b0;
        y_run_r <= 1'b0;
        y_dir_r <= 1'b0;
        motor_ctrl_enable_r <= 1'b0;
        motor_state_r <= MOTOR_STOP;
    end else begin
        case (coord_state)
            COORD_IDLE: begin
                x_run_r <= 1'b0;
                y_run_r <= 1'b0;
                coord_enable <= 1'b0;
                motor_ctrl_enable_r <= 1'b0;
                motor_state_r <= MOTOR_STOP;
                
                if (coord_cmd_valid) begin
                    target_x_reg <= target_x;
                    target_y_reg <= target_y;
                    coord_enable <= 1'b1;
                    move_timer <= 32'd0;
                    
                    // 开始X轴移动
                    if (target_x != current_x) begin
                        coord_state <= COORD_MOVE_X;
                        x_run_r <= 1'b1;
                        x_dir_r <= (target_x > current_x) ? 1'b1 : 1'b0;
                        // 预计算X轴移动时间
                        if (target_x > current_x)
                            target_time <= get_x_time(target_x - current_x);
                        else
                            target_time <= get_x_time(current_x - target_x);
                    end else if (target_y != current_y) begin
                        coord_state <= COORD_MOVE_Y;
                        y_run_r <= 1'b1;
                        y_dir_r <= (target_y > current_y) ? 1'b0 : 1'b1;
                        // 预计算Y轴移动时间
                        if (target_y > current_y)
                            target_time <= get_y_time(target_y - current_y);
                        else
                            target_time <= get_y_time(current_y - target_y);
                    end else begin
                        coord_state <= COORD_PAUSE;
                        pause_timer <= 32'd0;
                    end
                end
            end
            
            COORD_MOVE_X: begin
                move_timer <= move_timer_next;
                
                // 使用流水线比较结果（优化时序：减少关键路径）
                if (timer_done_stage2) begin
                    x_run_r <= 1'b0;
                    current_x <= target_x_reg;
                    move_timer <= 32'd0;
                    
                    if (target_y_reg != current_y) begin
                        coord_state <= COORD_MOVE_Y;
                        y_run_r <= 1'b1;
                        y_dir_r <= (target_y_reg > current_y) ? 1'b0 : 1'b1;
                        // 预计算Y轴移动时间
                        if (target_y_reg > current_y)
                            target_time <= get_y_time(target_y_reg - current_y);
                        else
                            target_time <= get_y_time(current_y - target_y_reg);
                    end else begin
                        coord_state <= COORD_PAUSE;
                        pause_timer <= 32'd0;
                    end
                end
            end
            
            COORD_MOVE_Y: begin
                move_timer <= move_timer_next;
                
                // 使用流水线比较结果（优化时序：减少关键路径）
                if (timer_done_stage2) begin
                    y_run_r <= 1'b0;
                    current_y <= target_y_reg;
                    coord_state <= COORD_PAUSE;
                    pause_timer <= 32'd0;
                end
            end
            
            COORD_PAUSE: begin
                pause_timer <= pause_timer_next;
                x_run_r <= 1'b0;
                y_run_r <= 1'b0;
                
                // 钓鱼电机控制逻辑（优化：使用流水线比较结果）
                motor_ctrl_enable_r <= 1'b1;
                if (pause_phase1_stage1) begin
                    motor_state_r <= MOTOR_REVERSE;  // 前29秒反转
                end else if (pause_phase2_stage1) begin
                    motor_state_r <= MOTOR_FORWARD;  // 29-58秒正转
                end else begin
                    motor_state_r <= MOTOR_STOP;     // 58-60秒停止
                end
                
                // 停顿60秒后开始复位（使用流水线比较结果）
                if (pause_done_stage1) begin
                    move_timer <= 32'd0;
                    motor_ctrl_enable_r <= 1'b0;
                    motor_state_r <= MOTOR_STOP;
                    
                    if (current_x != 2'b00) begin
                        coord_state <= COORD_RETURN_X;
                        x_run_r <= 1'b1;
                        x_dir_r <= 1'b0;  // 回原点正转
                        // 预计算X轴复位时间
                        target_time <= get_x_time(current_x);
                    end else if (current_y != 2'b00) begin
                        coord_state <= COORD_RETURN_Y;
                        y_run_r <= 1'b1;
                        y_dir_r <= 1'b1;  // 回原点反转
                        // 预计算Y轴复位时间
                        target_time <= get_y_time(current_y);
                    end else begin
                        coord_state <= COORD_IDLE;
                        coord_enable <= 1'b0;
                    end
                end
            end
            
            COORD_RETURN_X: begin
                move_timer <= move_timer_next;
                
                // 使用流水线比较结果（优化时序：减少关键路径）
                if (timer_done_stage2) begin
                    x_run_r <= 1'b0;
                    current_x <= 2'b00;
                    move_timer <= 32'd0;
                    
                    if (current_y != 2'b00) begin
                        coord_state <= COORD_RETURN_Y;
                        y_run_r <= 1'b1;
                        y_dir_r <= 1'b1;
                        // 预计算Y轴复位时间
                        target_time <= get_y_time(current_y);
                    end else begin
                        coord_state <= COORD_IDLE;
                        coord_enable <= 1'b0;
                    end
                end
            end
            
            COORD_RETURN_Y: begin
                move_timer <= move_timer_next;
                
                // 使用流水线比较结果（优化时序：减少关键路径）
                if (timer_done_stage2) begin
                    y_run_r <= 1'b0;
                    current_y <= 2'b00;
                    coord_state <= COORD_IDLE;
                    coord_enable <= 1'b0;
                end
            end
            
            default: begin
                coord_state <= COORD_IDLE;
                coord_enable <= 1'b0;
                x_run_r <= 1'b0;
                y_run_r <= 1'b0;
            end
        endcase
    end
end

// ============================================================================
// 输出流水线寄存器（优化：改善时序，减少扇出）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_run <= 1'b0;
        x_dir <= 1'b0;
        y_run <= 1'b0;
        y_dir <= 1'b0;
        motor_ctrl_enable <= 1'b0;
        motor_state <= MOTOR_STOP;
    end else begin
        x_run <= x_run_r;
        x_dir <= x_dir_r;
        y_run <= y_run_r;
        y_dir <= y_dir_r;
        motor_ctrl_enable <= motor_ctrl_enable_r;
        motor_state <= motor_state_r;
    end
end

endmodule


