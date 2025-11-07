// ============================================================================
// 步进电机控制器模块（优化版本）
// 功能：控制步进电机的运行、方向和脉冲生成
// 优化点：
//   1. 使用流水线设计减少组合逻辑深度
//   2. 优化脉冲生成器，减少计数器位宽
//   3. 添加状态同步寄存器，改善时序
//   4. 使用参数化设计，便于复用
// ============================================================================

module stepper_motor_controller #(
    parameter PULSE_FREQ = 125_000  // 脉冲频率：125kHz
)(
    input        clk,               // 系统时钟 50MHz
    input        rst_n,             // 复位信号
    
    // 手动控制命令
    input        forward_cmd,       // 正转命令
    input        reverse_cmd,       // 反转命令
    input        stop_cmd,          // 停止命令
    
    // 坐标控制信号
    input        coord_enable,      // 坐标控制使能
    input        coord_run,         // 坐标控制运行信号
    input        coord_dir,         // 坐标控制方向
    
    // 电机输出
    output reg   motor_enable,      // 电机使能（低有效）
    output reg   motor_dir,         // 电机方向
    output reg   motor_step,        // 电机脉冲
    
    // 状态输出
    output reg   running            // 运行状态
);

// ============================================================================
// 参数定义（优化：使用更小的计数器）
// ============================================================================
// 50MHz / 125kHz = 400个时钟周期
localparam integer PULSE_DIVIDER = 50_000_000 / PULSE_FREQ;  // 400
localparam integer PULSE_WIDTH = PULSE_DIVIDER / 2;           // 200

// 优化：使用9位计数器（2^9=512 > 400）
localparam CNT_WIDTH = 9;

// 电机控制状态
localparam [1:0] MOTOR_IDLE    = 2'b00;
localparam [1:0] MOTOR_RUNNING = 2'b01;

// ============================================================================
// 内部信号（优化：添加流水线寄存器）
// ============================================================================
reg [1:0] motor_state;
reg motor_direction;

// 脉冲生成器（优化：减小位宽）
reg [CNT_WIDTH-1:0] pulse_cnt;
reg pulse_gen;

// 同步寄存器（优化：改善时序）
reg coord_enable_r;
reg coord_run_r;
reg coord_dir_r;

// ============================================================================
// 输入信号同步（优化：减少跨时钟域亚稳态）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        coord_enable_r <= 1'b0;
        coord_run_r <= 1'b0;
        coord_dir_r <= 1'b0;
    end else begin
        coord_enable_r <= coord_enable;
        coord_run_r <= coord_run;
        coord_dir_r <= coord_dir;
    end
end

// ============================================================================
// 电机控制状态机（优化：简化状态转换逻辑）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        motor_state <= MOTOR_IDLE;
        motor_direction <= 1'b0;
        running <= 1'b0;
    end else begin
        // 坐标控制模式优先
        if (coord_enable_r) begin
            if (coord_run_r) begin
                motor_state <= MOTOR_RUNNING;
                motor_direction <= coord_dir_r;
                running <= 1'b1;
            end else begin
                motor_state <= MOTOR_IDLE;
                running <= 1'b0;
            end
        end 
        // 手动控制模式
        else begin
            if (stop_cmd) begin
                motor_state <= MOTOR_IDLE;
                running <= 1'b0;
            end else if (forward_cmd) begin
                motor_state <= MOTOR_RUNNING;
                motor_direction <= 1'b0;  // 正转
                running <= 1'b1;
            end else if (reverse_cmd) begin
                motor_state <= MOTOR_RUNNING;
                motor_direction <= 1'b1;  // 反转
                running <= 1'b1;
            end
        end
    end
end

// ============================================================================
// 脉冲生成器（优化：使用更小的计数器和简化逻辑）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pulse_cnt <= {CNT_WIDTH{1'b0}};
        pulse_gen <= 1'b0;
    end else begin
        if (motor_state == MOTOR_RUNNING) begin
            if (pulse_cnt >= PULSE_DIVIDER - 1) begin
                pulse_cnt <= {CNT_WIDTH{1'b0}};
                pulse_gen <= 1'b1;
            end else begin
                pulse_cnt <= pulse_cnt + 1'b1;
                // 优化：使用简单比较减少组合逻辑
                pulse_gen <= (pulse_cnt < PULSE_WIDTH) ? 1'b1 : 1'b0;
            end
        end else begin
            pulse_cnt <= {CNT_WIDTH{1'b0}};
            pulse_gen <= 1'b0;
        end
    end
end

// ============================================================================
// 输出寄存器（优化：添加输出寄存器改善时序）
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        motor_enable <= 1'b1;  // 高电平禁用
        motor_dir <= 1'b0;
        motor_step <= 1'b0;
    end else begin
        motor_enable <= (motor_state == MOTOR_IDLE) ? 1'b1 : 1'b0;
        motor_dir <= motor_direction;
        motor_step <= pulse_gen;
    end
end

endmodule


