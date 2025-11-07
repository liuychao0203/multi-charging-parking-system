// ============================================================================
// SG90舵机控制器模块
// 功能：控制舵机在0°、90°、180°之间旋转
// 支持蓝牙命令控制和传感器触发控制
// ============================================================================

module servo_controller(
    input        clk,               // 系统时钟 50MHz
    input        rst_n,             // 复位信号
    
    // 传感器输入
    input        sensor_trigger,    // 传感器触发信号（J14，低电平触发）
    
    // 蓝牙控制命令
    input        ccw_cmd,           // 逆时针旋转90度命令
    input        cw_cmd,            // 顺时针旋转90度命令
    
    // 舵机PWM输出
    output       servo_pwm          // 舵机PWM控制信号
);

// SG90舵机PWM参数定义（50MHz时钟）
// PWM周期：20ms = 1,000,000 时钟周期
// 0度：0.5ms = 25,000 时钟周期
// 90度：1.5ms = 75,000 时钟周期
// 180度：2.5ms = 125,000 时钟周期
localparam integer SERVO_PERIOD  = 32'd1_000_000;  // 20ms周期
localparam integer SERVO_0_DEG   = 32'd25_000;     // 0度位置
localparam integer SERVO_90_DEG  = 32'd75_000;     // 90度位置
localparam integer SERVO_180_DEG = 32'd125_000;    // 180度位置
localparam integer J14_HOLD_TIME = 32'd200_000_000; // 传感器保持时间：4秒

// 舵机位置状态定义
localparam [1:0] SERVO_POS_90  = 2'b00;  // 中间位置 (90度)
localparam [1:0] SERVO_POS_0   = 2'b01;  // 逆时针位置 (0度)
localparam [1:0] SERVO_POS_180 = 2'b10;  // 顺时针位置 (180度)

// 内部信号
reg [1:0] servo_pos_state;
reg [31:0] servo_pwm_cnt;
reg [31:0] servo_pulse_width;
reg servo_pwm_out;

// 时序优化：添加流水线比较寄存器
reg [31:0] servo_pwm_cnt_next;
reg pwm_period_done;
reg pwm_pulse_done;

// 传感器防抖
reg [15:0] sensor_debounce_cnt;
reg sensor_stable;
reg sensor_last_stable;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sensor_debounce_cnt <= 16'd0;
        sensor_stable <= 1'b0;
        sensor_last_stable <= 1'b0;
    end else begin
        sensor_last_stable <= sensor_stable;
        
        if (sensor_trigger == sensor_stable) begin
            sensor_debounce_cnt <= 16'd0;
        end else begin
            if (sensor_debounce_cnt >= 16'd1000) begin
                sensor_stable <= sensor_trigger;
                sensor_debounce_cnt <= 16'd0;
            end else begin
                sensor_debounce_cnt <= sensor_debounce_cnt + 1'b1;
            end
        end
    end
end

// 传感器触发保持逻辑
reg [31:0] sensor_hold_timer;
reg sensor_triggered;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sensor_hold_timer <= 32'd0;
        sensor_triggered <= 1'b0;
    end else begin
        // 检测到低电平且未触发：立即触发
        if (!sensor_stable && !sensor_triggered) begin
            sensor_triggered <= 1'b1;
            sensor_hold_timer <= 32'd0;
        end 
        // 已触发：开始计时
        else if (sensor_triggered) begin
            if (sensor_hold_timer >= J14_HOLD_TIME) begin
                // 4秒时间到，复位
                sensor_triggered <= 1'b0;
                sensor_hold_timer <= 32'd0;
            end else begin
                sensor_hold_timer <= sensor_hold_timer + 1'b1;
            end
        end
    end
end

// 舵机位置状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        servo_pos_state <= SERVO_POS_90;  // 复位时回到中间位置
    end else begin
        // 传感器控制（优先级最高）
        if (!sensor_stable && !sensor_triggered) begin
            servo_pos_state <= SERVO_POS_180;  // 检测到低电平立即转到180度
        end else if (sensor_triggered && sensor_hold_timer >= J14_HOLD_TIME) begin
            servo_pos_state <= SERVO_POS_90;   // 4秒后转回90度
        end
        // 蓝牙命令控制（传感器触发期间无效）
        else if (!sensor_triggered) begin
            if (ccw_cmd) begin
                // 逆时针转90度
                case (servo_pos_state)
                    SERVO_POS_180: servo_pos_state <= SERVO_POS_90;
                    SERVO_POS_90:  servo_pos_state <= SERVO_POS_0;
                    SERVO_POS_0:   servo_pos_state <= SERVO_POS_0;  // 已到极限
                    default:       servo_pos_state <= SERVO_POS_90;
                endcase
            end else if (cw_cmd) begin
                // 顺时针转90度
                case (servo_pos_state)
                    SERVO_POS_0:   servo_pos_state <= SERVO_POS_90;
                    SERVO_POS_90:  servo_pos_state <= SERVO_POS_180;
                    SERVO_POS_180: servo_pos_state <= SERVO_POS_180; // 已到极限
                    default:       servo_pos_state <= SERVO_POS_90;
                endcase
            end
        end
    end
end

// 根据位置状态设置脉宽
always @(*) begin
    case (servo_pos_state)
        SERVO_POS_0:   servo_pulse_width = SERVO_0_DEG;
        SERVO_POS_90:  servo_pulse_width = SERVO_90_DEG;
        SERVO_POS_180: servo_pulse_width = SERVO_180_DEG;
        default:       servo_pulse_width = SERVO_90_DEG;
    endcase
end

// 时序优化：PWM计数器流水线（减少32位加法器和比较器的关键路径）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        servo_pwm_cnt_next <= 32'd0;
    end else begin
        servo_pwm_cnt_next <= servo_pwm_cnt + 1'b1;
    end
end

// 时序优化：流水线比较器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_period_done <= 1'b0;
        pwm_pulse_done <= 1'b0;
    end else begin
        pwm_period_done <= (servo_pwm_cnt_next >= SERVO_PERIOD);
        pwm_pulse_done <= (servo_pwm_cnt_next >= servo_pulse_width);
    end
end

// PWM信号生成（使用流水线比较结果）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        servo_pwm_cnt <= 32'd0;
        servo_pwm_out <= 1'b0;
    end else begin
        if (pwm_period_done) begin
            servo_pwm_cnt <= 32'd0;
            servo_pwm_out <= 1'b1;
        end else begin
            servo_pwm_cnt <= servo_pwm_cnt_next;
            
            if (pwm_pulse_done) begin
                servo_pwm_out <= 1'b0;
            end
        end
    end
end

// 输出赋值
assign servo_pwm = servo_pwm_out;

endmodule


