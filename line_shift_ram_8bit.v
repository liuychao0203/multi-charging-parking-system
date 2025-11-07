
module line_shift_ram_8bit(
    input          clock,   
    input          clken,
    input          pre_frame_href,
    
    input   [7:0]  shiftin,  
    output  [7:0]  taps0x,   
    output  [7:0]  taps1x    
);

//reg define
reg  [2:0]  clken_dly;
reg  [9:0]  ram_rd_addr;
reg  [9:0]  ram_rd_addr_d0;
reg  [9:0]  ram_rd_addr_d1;
reg  [7:0]  shiftin_d0;
reg  [7:0]  shiftin_d1;
reg  [7:0]  shiftin_d2;
reg  [7:0]  taps0x_d0;

//*****************************************************
//**                    main code
//*****************************************************

//����������ʱ��ram��ַ�ۼ�
always@(posedge clock)begin
    if(pre_frame_href)
        if(clken)
            ram_rd_addr <= ram_rd_addr + 1 ;
        else
            ram_rd_addr <= ram_rd_addr ;
    else
        ram_rd_addr <= 0 ;
end

//ʱ��ʹ���ź��ӳ�����
always@(posedge clock) begin
    clken_dly <= { clken_dly[1:0] , clken };
end

//��ram��ַ�ӳٶ���
always@(posedge clock ) begin
    ram_rd_addr_d0 <= ram_rd_addr;
    ram_rd_addr_d1 <= ram_rd_addr_d0;
end

//���������ӳ�����
always@(posedge clock)begin
    shiftin_d0 <= shiftin;
    shiftin_d1 <= shiftin_d0;
    shiftin_d2 <= shiftin_d1;
end

//���ڴ洢ǰһ��ͼ���RAM
blk_mem_gen_0  u_ram_1024x8_0(    
    .clka   (clock), 
    .wea   (clken_dly[2]),    //���ӳٵĵ�����ʱ�����ڣ���ǰ�е�����д��RAM0
    .addra (ram_rd_addr_d1),
    .dina  (shiftin_d2),
    .clkb  (clock),
    .addrb (ram_rd_addr),
    .doutb (taps0x)           //�ӳ�һ��ʱ�����ڣ����RAM0��ǰһ��ͼ�������
); 

//���ڴ洢ǰǰһ��ͼ���RAM
blk_mem_gen_0  u_ram_1024x8_1(    
    .clka   (clock),           
    .wea   (clken_dly[2]),    //���ӳٵĵ�����ʱ�����ڣ���ǰһ��ͼ�������д��RAM1
    .addra (ram_rd_addr_d1),
    .dina  (taps0x),
    .clkb  (clock),
    .addrb (ram_rd_addr),
    .doutb (taps1x)           //�ӳ�һ��ʱ�����ڣ����RAM1��ǰǰһ��ͼ�������
); 

endmodule 