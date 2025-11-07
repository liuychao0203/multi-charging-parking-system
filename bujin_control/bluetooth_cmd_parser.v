module bluetooth_cmd_parser(
    input        clk,           // 系统时钟
    input        rst_n,         // 复位信号
    input        rx_done,       // UART接收完成标志
    input [7:0]  rx_data,       // UART接收数据
    
    // 坐标控制输出
    output reg   coord_cmd_valid,  // 坐标命令有效标志
    output reg [1:0] target_x,     // 目标X坐标 (0-3)
    output reg [1:0] target_y,     // 目标Y坐标 (0-3)
    
    // 兼容旧的控制输出（保持向后兼容）
    output reg   x_forward_cmd,  // X轴正转命令
    output reg   x_reverse_cmd,  // X轴反转命令
    output reg   x_stop_cmd,     // X轴停止命令
    output reg   y_forward_cmd,  // Y轴正转命令
    output reg   y_reverse_cmd,  // Y轴反转命令
    output reg   y_stop_cmd,     // Y轴停止命令
    
    // 电机控制输出
    output reg   motor_forward_cmd,  // 电机正转命令
    output reg   motor_reverse_cmd,  // 电机反转命令
    output reg   motor_stop_cmd,     // 电机停止命令
    
    // SG90舵机控制输出
    output reg   servo_ccw_cmd,      // 舵机逆时针转90度命令
    output reg   servo_cw_cmd        // 舵机顺时针转90度命令
);

// 解析状态定义
localparam [2:0] IDLE       = 3'b000;  // 空闲状态
localparam [2:0] WAIT_X     = 3'b001;  // 等待X坐标
localparam [2:0] WAIT_COMMA = 3'b010;  // 等待逗号
localparam [2:0] WAIT_Y     = 3'b011;  // 等待Y坐标
localparam [2:0] WAIT_CLOSE = 3'b100;  // 等待右括号

// 字符定义
parameter CHAR_OPEN_PAREN  = 8'h28;  // '(' = 0x28
parameter CHAR_CLOSE_PAREN = 8'h29;  // ')' = 0x29
parameter CHAR_COMMA       = 8'h2C;  // ',' = 0x2C
parameter CHAR_0           = 8'h30;  // '0' = 0x30
parameter CHAR_1           = 8'h31;  // '1' = 0x31
parameter CHAR_2           = 8'h32;  // '2' = 0x32
parameter CHAR_3           = 8'h33;  // '3' = 0x33

// 兼容旧命令定义
parameter CMD_X_FORWARD = 8'h01;  // 0x01 - X轴正转
parameter CMD_X_REVERSE = 8'h02;  // 0x02 - X轴反转
parameter CMD_Y_FORWARD = 8'h03;  // 0x03 - Y轴正转
parameter CMD_Y_REVERSE = 8'h04;  // 0x04 - Y轴反转
parameter CMD_ALL_STOP  = 8'h00;  // 0x00 - 全部停止

// 电机控制命令定义
parameter CMD_MOTOR_FORWARD = 8'h08;  // 0x08 - 电机正转
parameter CMD_MOTOR_REVERSE = 8'h09;  // 0x09 - 电机反转
parameter CMD_MOTOR_STOP    = 8'h10;  // 0x10 - 电机停止

// SG90舵机控制命令定义
parameter CMD_SERVO_CCW     = 8'h15;  // 0x15 - 舵机逆时针转90度
parameter CMD_SERVO_CW      = 8'h16;  // 0x16 - 舵机顺时针转90度

// 状态机寄存器
reg [2:0] parse_state;
reg [1:0] temp_x, temp_y;

// 命令脉冲生成
reg rx_done_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_done_d1 <= 1'b0;
    end else begin
        rx_done_d1 <= rx_done;
    end
end

// 检测rx_done上升沿
wire rx_done_pulse = rx_done && (~rx_done_d1);

// 坐标解析状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parse_state <= IDLE;
        temp_x <= 2'b00;
        temp_y <= 2'b00;
        coord_cmd_valid <= 1'b0;
        target_x <= 2'b00;
        target_y <= 2'b00;
    end else begin
        // 默认清除坐标命令有效标志
        coord_cmd_valid <= 1'b0;
        
        if (rx_done_pulse) begin
            case (parse_state)
                IDLE: begin
                    if (rx_data == CHAR_OPEN_PAREN) begin
                        parse_state <= WAIT_X;
                        temp_x <= 2'b00;
                        temp_y <= 2'b00;
                    end
                end
                
                WAIT_X: begin
                    if (rx_data >= CHAR_0 && rx_data <= CHAR_3) begin
                        temp_x <= rx_data[1:0];  // 提取低2位作为坐标值
                        parse_state <= WAIT_COMMA;
                    end else begin
                        parse_state <= IDLE;  // 无效字符，重置
                    end
                end
                
                WAIT_COMMA: begin
                    if (rx_data == CHAR_COMMA) begin
                        parse_state <= WAIT_Y;
                    end else begin
                        parse_state <= IDLE;  // 无效字符，重置
                    end
                end
                
                WAIT_Y: begin
                    if (rx_data >= CHAR_0 && rx_data <= CHAR_3) begin
                        temp_y <= rx_data[1:0];  // 提取低2位作为坐标值
                        parse_state <= WAIT_CLOSE;
                    end else begin
                        parse_state <= IDLE;  // 无效字符，重置
                    end
                end
                
                WAIT_CLOSE: begin
                    if (rx_data == CHAR_CLOSE_PAREN) begin
                        // 成功解析完整坐标
                        target_x <= temp_x;
                        target_y <= temp_y;
                        coord_cmd_valid <= 1'b1;
                        parse_state <= IDLE;
                    end else begin
                        parse_state <= IDLE;  // 无效字符，重置
                    end
                end
                
                default: begin
                    parse_state <= IDLE;
                end
            endcase
        end
    end
end

// 兼容旧命令解析（保持向后兼容）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_forward_cmd <= 1'b0;
        x_reverse_cmd <= 1'b0;
        x_stop_cmd    <= 1'b0;
        y_forward_cmd <= 1'b0;
        y_reverse_cmd <= 1'b0;
        y_stop_cmd    <= 1'b0;
        motor_forward_cmd <= 1'b0;
        motor_reverse_cmd <= 1'b0;
        motor_stop_cmd    <= 1'b0;
        servo_ccw_cmd     <= 1'b0;
        servo_cw_cmd      <= 1'b0;
    end else begin
        // 默认清除所有命令
        x_forward_cmd <= 1'b0;
        x_reverse_cmd <= 1'b0;
        x_stop_cmd    <= 1'b0;
        y_forward_cmd <= 1'b0;
        y_reverse_cmd <= 1'b0;
        y_stop_cmd    <= 1'b0;
        motor_forward_cmd <= 1'b0;
        motor_reverse_cmd <= 1'b0;
        motor_stop_cmd    <= 1'b0;
        servo_ccw_cmd     <= 1'b0;
        servo_cw_cmd      <= 1'b0;
        
        // 当接收到新数据时解析旧格式命令
        if (rx_done_pulse && parse_state == IDLE) begin
            case (rx_data)
                CMD_X_FORWARD: x_forward_cmd <= 1'b1;  // X轴正转
                CMD_X_REVERSE: x_reverse_cmd <= 1'b1;  // X轴反转
                CMD_Y_FORWARD: y_forward_cmd <= 1'b1;  // Y轴正转
                CMD_Y_REVERSE: y_reverse_cmd <= 1'b1;  // Y轴反转
                CMD_ALL_STOP: begin                    // 全部停止
                    x_stop_cmd <= 1'b1;
                    y_stop_cmd <= 1'b1;
                end
                CMD_MOTOR_FORWARD: motor_forward_cmd <= 1'b1;  // 电机正转
                CMD_MOTOR_REVERSE: motor_reverse_cmd <= 1'b1;  // 电机反转
                CMD_MOTOR_STOP: motor_stop_cmd <= 1'b1;        // 电机停止
                CMD_SERVO_CCW: servo_ccw_cmd <= 1'b1;          // 舵机逆时针转90度
                CMD_SERVO_CW: servo_cw_cmd <= 1'b1;            // 舵机顺时针转90度
                default: begin
                    // 无效命令，不执行任何操作
                end
            endcase
        end
    end
end

endmodule