module uart_rx(
    input        clk,           // 系统时钟50MHz
    input        rst_n,         // 复位信号
    input        uart_rx,       // UART接收引脚
    
    output reg   rx_done,       // 接收完成标志
    output reg [7:0] rx_data    // 接收到的数据
);

// 波特率9600，时钟50MHz
// 每个bit的时钟周期数 = 50MHz / 9600 = 5208
parameter BAUD_CNT = 5208;
parameter BAUD_CNT_HALF = 2604;

// 状态定义
parameter IDLE      = 3'b000;
parameter START_BIT = 3'b001;
parameter DATA_BITS = 3'b010;
parameter STOP_BIT  = 3'b011;

reg [2:0] state;
reg [2:0] next_state;
reg [15:0] baud_cnt;
reg [2:0] bit_cnt;
reg [7:0] rx_data_reg;
reg uart_rx_d1, uart_rx_d2;

// 输入信号同步化，防止亚稳态
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        uart_rx_d1 <= 1'b1;
        uart_rx_d2 <= 1'b1;
    end else begin
        uart_rx_d1 <= uart_rx;
        uart_rx_d2 <= uart_rx_d1;
    end
end

// 检测下降沿（起始位）
wire start_flag = uart_rx_d2 && (~uart_rx_d1);

// 状态机时序逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 状态机组合逻辑
always @(*) begin
    case (state)
        IDLE: begin
            if (start_flag)
                next_state = START_BIT;
            else
                next_state = IDLE;
        end
        
        START_BIT: begin
            if (baud_cnt == BAUD_CNT - 1)
                next_state = DATA_BITS;
            else
                next_state = START_BIT;
        end
        
        DATA_BITS: begin
            if ((bit_cnt == 7) && (baud_cnt == BAUD_CNT - 1))
                next_state = STOP_BIT;
            else
                next_state = DATA_BITS;
        end
        
        STOP_BIT: begin
            if (baud_cnt == BAUD_CNT - 1)
                next_state = IDLE;
            else
                next_state = STOP_BIT;
        end
        
        default: next_state = IDLE;
    endcase
end

// 波特率计数器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_cnt <= 16'd0;
    end else begin
        if ((state == START_BIT) || (state == DATA_BITS) || (state == STOP_BIT)) begin
            if (baud_cnt == BAUD_CNT - 1)
                baud_cnt <= 16'd0;
            else
                baud_cnt <= baud_cnt + 1'b1;
        end else begin
            baud_cnt <= 16'd0;
        end
    end
end

// 数据位计数器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 3'd0;
    end else begin
        if (state == DATA_BITS) begin
            if (baud_cnt == BAUD_CNT - 1)
                bit_cnt <= bit_cnt + 1'b1;
        end else begin
            bit_cnt <= 3'd0;
        end
    end
end

// 数据接收
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_reg <= 8'd0;
    end else begin
        if ((state == DATA_BITS) && (baud_cnt == BAUD_CNT_HALF)) begin
            rx_data_reg[bit_cnt] <= uart_rx_d2;
        end
    end
end

// 接收完成标志
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_done <= 1'b0;
        rx_data <= 8'd0;
    end else begin
        if ((state == STOP_BIT) && (baud_cnt == BAUD_CNT - 1)) begin
            rx_done <= 1'b1;
            rx_data <= rx_data_reg;
        end else begin
            rx_done <= 1'b0;
        end
    end
end

endmodule