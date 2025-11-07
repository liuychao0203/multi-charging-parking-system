

`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input           rst_n            ,  //��λ�ź�
    input           wr_clk           ,  //wfifoʱ��
    input           rd_clk           ,  //rfifoʱ��
    input           ui_clk           ,  //�û�ʱ��
    input           wr_en            ,  //������Чʹ���ź�
    input  [15:0]   wrdata           ,  //��Ч����
    input  [255:0]  rfifo_din        ,  //�û�������
    input           rdata_req        ,  //�������ص���ɫ�������� 
    input           rfifo_wren       ,  //��ddr3�������ݵ���Чʹ��
    input           wfifo_rden       ,  //wfifo��ʹ��
    input           rd_load          ,  //���Դ���ź�
    input           wr_load          ,  //����Դ���ź�          

    output [255:0]  wfifo_dout       ,  //�û�д����
    output [10:0]   rfifo_wcount     ,  //rfifoʣ�����ݼ���
    output [10:0]   wfifo_rcount     ,  //wfifoд�����ݼ���
    output reg [15:0]   rddata         //����Ч����     	
    );
           
//reg define
reg  [255:0] wrdata_t          ;  //��16bit����Դ������λƴ�ӵõ�
reg  [3:0]   byte_cnt          ;  //д������λ������
reg  [3:0]   i                 ;  //��������λ������       
reg          wfifo_wren        ;  //wfifoдʹ���ź�
reg          rd_load_d0        ;
reg          rdfifo_rst_h      ;  //rfifo��λ�źţ�����Ч
reg          wr_load_d0        ;
reg          wr_load_d1        ;
reg          wfifo_rst_h       ;  //wfifo��λ�źţ�����Ч
reg  [15:0]  wr_load_d         ;  //������Դ���ź���λƴ�ӵõ�
reg  [15:0]  rd_load_d         ;  //�����Դ���ź���λƴ�ӵõ�    
 
//wire define 
wire [255:0] rfifo_dout        ;  //rfifo�������    
wire [255:0] wfifo_din         ;  //wfifoд����
wire [15:0]  dataout[0:15]     ;  //����������ݵĶ�ά����
wire         rfifo_rden        ;  //rfifo�Ķ�ʹ��

//*****************************************************
//**                    main code
//*****************************************************  

//rfifo��������ݴ浽��ά����
assign dataout[0] = rfifo_dout[255:240];
assign dataout[1] = rfifo_dout[239:224];
assign dataout[2] = rfifo_dout[223:208];
assign dataout[3] = rfifo_dout[207:192];
assign dataout[4] = rfifo_dout[191:176];
assign dataout[5] = rfifo_dout[175:160];
assign dataout[6] = rfifo_dout[159:144];
assign dataout[7] = rfifo_dout[143:128];
assign dataout[8] = rfifo_dout[127:112];
assign dataout[9] = rfifo_dout[111:96];
assign dataout[10] = rfifo_dout[95:80];
assign dataout[11] = rfifo_dout[79:64];
assign dataout[12] = rfifo_dout[63:48];
assign dataout[13] = rfifo_dout[47:32];
assign dataout[14] = rfifo_dout[31:16];
assign dataout[15] = rfifo_dout[15:0];

assign wfifo_din = wrdata_t ;

//��λ�Ĵ�������ʱ����rfifo����һ������
assign rfifo_rden = (rdata_req && (i==15)) ? 1'b1  :  1'b0; 

//16λ����ת256λRGB565����        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        wrdata_t <= 0;
        byte_cnt <= 0;
    end
    else if(wr_en) begin
        if(byte_cnt == 15)begin
            byte_cnt <= 0;
            wrdata_t <= {wrdata_t[239:0],wrdata};
        end
        else begin
            byte_cnt <= byte_cnt + 1;
            wrdata_t <= {wrdata_t[239:0],wrdata};
        end
    end
    else begin
        byte_cnt <= byte_cnt;
        wrdata_t <= wrdata_t;
    end    
end 

//wfifoдʹ�ܲ���
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 0;
    else if(wfifo_wren == 1)
        wfifo_wren <= 0;
    else if(byte_cnt == 15 && wr_en)  //����Դ���ݴ���8�Σ�дʹ������һ��
        wfifo_wren <= 1;
    else 
        wfifo_wren <= 0;
 end   

//��rfifo������128bit���ݲ���16��16bit����
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        rddata <= 16'b0;
        i <=0;
    end
    else if(rdata_req) begin
        if(i == 15)begin
            rddata <= dataout[i];
            i <= 0;
        end
        else begin
            rddata <= dataout[i];
            i <= i + 1;
        end
    end 
    else begin
        rddata <= rddata;
        i <=0;
    end
end  

always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rd_load_d0 <= 1'b0;
    else
        rd_load_d0 <= rd_load;      
end 

//�����Դ���źŽ�����λ�Ĵ�
always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rd_load_d <= 1'b0;
    else
        rd_load_d <= {rd_load_d[14:0],rd_load_d0};       
end 

//����һ�θ�λ��ƽ������fifo��λʱ��  
always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rdfifo_rst_h <= 1'b0;
    else if(rd_load_d[0] && !rd_load_d[14])
        rdfifo_rst_h <= 1'b1;   
    else
        rdfifo_rst_h <= 1'b0;              
end  

//������Դ���źŽ�����λ�Ĵ�
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_load_d0 <= 1'b0;
        wr_load_d  <= 16'b0;        
    end     
    else begin
        wr_load_d0 <= wr_load;
        wr_load_d <= {wr_load_d[14:0],wr_load_d0};      
    end                 
end  

//����һ�θ�λ��ƽ������fifo��λʱ�� 
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
      wfifo_rst_h <= 1'b0;          
    else if(wr_load_d[0] && !wr_load_d[15])
      wfifo_rst_h <= 1'b1;       
    else
      wfifo_rst_h <= 1'b0;                      
end   

rd_fifo u_rd_fifo (
  .rst               (~rst_n|rdfifo_rst_h),                    
  .wr_clk            (ui_clk),   
  .rd_clk            (rd_clk),    
  .din               (rfifo_din), 
  .wr_en             (rfifo_wren),
  .rd_en             (rfifo_rden),
  .dout              (rfifo_dout),
  .full              (),          
  .empty             (),          
  .rd_data_count     (),  
  .wr_data_count     (rfifo_wcount),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()      
);

wr_fifo u_wr_fifo (
  .rst               (~rst_n|wfifo_rst_h),
  .wr_clk            (wr_clk),            
  .rd_clk            (ui_clk),           
  .din               (wfifo_din),         
  .wr_en             (wfifo_wren),        
  .rd_en             (wfifo_rden),        
  .dout              (wfifo_dout ),       
  .full              (),                  
  .empty             (),                  
  .rd_data_count     (wfifo_rcount),  
  .wr_data_count     (),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()    
);

endmodule 

