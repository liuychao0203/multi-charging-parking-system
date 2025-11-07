// ============================================================================
// 直流电机控制器模块 (Y7和Y9控制)
// 功能：控制直流电机的正转、反转和停止
// 支持手动蓝牙控制和坐标系统自动控制
// ============================================================================

module dc_motor_controller(
    input        clk,               // 系统时钟 50MHz
    input        rst_n,             // 复位信号
    
    // 手动控制命令
    input        forward_cmd,       // 正转命令
    input        reverse_cmd,       // 反转命令
    input        stop_cmd,          // 停止命令
    
    // 坐标控制信号
    input        coord_enable,      // 坐标控制使能
    input  [1:0] coord_state,       // 坐标模式下的电机状态
    
    // 电机输出
    output       motor_pin1,        // 电机引脚1 (Y7)
    output       motor_pin2         // 电机引脚2 (Y9)
);

// 电机状态定义
localparam [1:0] MOTOR_STOP    = 2'b00;  // 停止
localparam [1:0] MOTOR_FORWARD = 2'b01;  // 正转
localparam [1:0] MOTOR_REVERSE = 2'b10;  // 反转

// 内部信号
reg [1:0] motor_state;
reg motor_y7_reg, motor_y9_reg;

// 电机状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        motor_state <= MOTOR_STOP;
    end else begin
        // 坐标控制模式优先
        if (coord_enable) begin
            motor_state <= coord_state;
        end else begin
            // 手动蓝牙控制模式
            if (forward_cmd) begin
                motor_state <= MOTOR_FORWARD;
            end else if (reverse_cmd) begin
                motor_state <= MOTOR_REVERSE;
            end else if (stop_cmd) begin
                motor_state <= MOTOR_STOP;
            end
        end
    end
end

// 电机输出逻辑
// 正转: Y7高电平, Y9低电平
// 反转: Y7低电平, Y9高电平
// 停止: Y7低电平, Y9低电平
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        motor_y7_reg <= 1'b0;
        motor_y9_reg <= 1'b0;
    end else begin
        case (motor_state)
            MOTOR_FORWARD: begin
                motor_y7_reg <= 1'b1;  // Y7 = 高电平
                motor_y9_reg <= 1'b0;  // Y9 = 低电平
            end
            
            MOTOR_REVERSE: begin
                motor_y7_reg <= 1'b0;  // Y7 = 低电平
                motor_y9_reg <= 1'b1;  // Y9 = 高电平
            end
            
            MOTOR_STOP: begin
                motor_y7_reg <= 1'b0;  // Y7 = 低电平
                motor_y9_reg <= 1'b0;  // Y9 = 低电平
            end
            
            default: begin
                motor_y7_reg <= 1'b0;
                motor_y9_reg <= 1'b0;
            end
        endcase
    end
end

// 输出赋值
assign motor_pin1 = motor_y7_reg;
assign motor_pin2 = motor_y9_reg;

endmodule


