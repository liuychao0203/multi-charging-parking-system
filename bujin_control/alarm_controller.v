// ============================================================================
// 告警控制器模块
// 功能：根据传感器状态控制蜂鸣器告警
// 监控：湿度传感器、雨水传感器、火焰传感器、限位开关
// ============================================================================

module alarm_controller(
    input        clk,               // 系统时钟 50MHz
    input        rst_n,             // 复位信号
    
    // DHT11温湿度传感器信号
    input  [7:0] humidity_int,      // 湿度整数部分
    input        humidity_valid,    // 湿度数据有效
    
    // 传感器输入
    input        rain_sensor,       // 雨水传感器
    input        flame_sensor,      // 火焰传感器
    input        limit_switch,      // 限位开关
    
    // 蜂鸣器输出
    output       beep               // 蜂鸣器控制信号
);

// 湿度阈值定义
localparam [7:0] HUMIDITY_THRESHOLD = 8'd60;  // 湿度阈值60%

// 启动延时参数（防止上电时误触发）
localparam [31:0] STARTUP_DELAY = 32'd250_000_000;  // 5秒延时

// 内部信号
reg [31:0] startup_cnt;
reg system_ready;

// 时序优化：添加流水线计数器
reg [31:0] startup_cnt_next;
reg startup_done;

// 时序优化：流水线计数器（第1级）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        startup_cnt_next <= 32'd0;
    end else begin
        startup_cnt_next <= startup_cnt + 1'b1;
    end
end

// 时序优化：流水线比较器（第2级）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        startup_done <= 1'b0;
    end else begin
        startup_done <= (startup_cnt_next >= STARTUP_DELAY);
    end
end

// 系统启动延时计数器（使用流水线结果）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        startup_cnt <= 32'd0;
        system_ready <= 1'b0;
    end else begin
        if (!startup_done) begin
            startup_cnt <= startup_cnt_next;
            system_ready <= 1'b0;
        end else begin
            system_ready <= 1'b1;
        end
    end
end

// 告警条件判断
wire humidity_high = (system_ready && humidity_valid && (humidity_int >= HUMIDITY_THRESHOLD));
wire rain_detected = 1'b0;  // 暂时禁用
wire flame_detected = 1'b0; // 暂时禁用
wire limit_triggered = (system_ready && ~limit_switch);  // 限位开关低电平触发

// 蜂鸣器控制逻辑
assign beep = humidity_high || rain_detected || flame_detected || limit_triggered;

endmodule


