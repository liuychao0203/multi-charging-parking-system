

module lcd_rgb_top(
    input           sys_clk      ,  //ϵͳʱ��
    input           sys_rst_n,      //��λ�ź�  
    input           sys_init_done, 
    //lcd�ӿ�  
    output          lcd_clk,        //LCD����ʱ��    
    output          lcd_hs,         //LCD ��ͬ���ź�
    output          lcd_vs,         //LCD ��ͬ���ź�
    output          lcd_de,         //LCD ��������ʹ��
    inout  [23:0]   lcd_rgb,        //LCD RGB��ɫ����
    output          lcd_bl,         //LCD ��������ź�
    output          lcd_rst,        //LCD ��λ�ź�
    output          lcd_pclk,       //LCD ����ʱ��
    output  [15:0]  lcd_id,         //LCD��ID  
    output          out_vsync,      //lcd���ź� 
    output  [10:0]  pixel_xpos,     //���ص������
    output  [10:0]  pixel_ypos,     //���ص�������        
    output  [10:0]  h_disp,         //LCD��ˮƽ�ֱ���
    output  [10:0]  v_disp,         //LCD����ֱ�ֱ���         
    input   [15:0]  data_in,        //��������   
    output          data_req        //������������
    
    );

//wire define
wire  [15:0] lcd_rgb_565;           //�����16λlcd����
wire  [23:0] lcd_rgb_o ;            //LCD �����ɫ����
wire  [23:0] lcd_rgb_i ;            //LCD ������ɫ����
//*****************************************************
//**                    main code
//***************************************************** 
//������ͷ16bit����ת��Ϊ24bit��lcd����
assign lcd_rgb_o = {lcd_rgb_565[15:11],3'b000,lcd_rgb_565[10:5],2'b00,
                    lcd_rgb_565[4:0],3'b000};          

//�������ݷ����л�
assign lcd_rgb = lcd_de ?  lcd_rgb_o :  {24{1'bz}};
assign lcd_rgb_i = lcd_rgb;
            
//ʱ�ӷ�Ƶģ��    
clk_div u_clk_div(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_id                 (lcd_id   ),
    .lcd_pclk               (lcd_clk  )
    );  

//��LCD IDģ��
rd_id u_rd_id(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_rgb                (lcd_rgb_i),
    .lcd_id                 (lcd_id   )
    );  

//lcd����ģ��
lcd_driver u_lcd_driver(           
    .lcd_clk        (lcd_clk),    
    .rst_n          (sys_rst_n & sys_init_done), 
    .lcd_id         (lcd_id),   

    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_rgb        (lcd_rgb_565),
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_pclk       (lcd_pclk),
    
    .pixel_data     (data_in), 
    .data_req       (data_req),
    .out_vsync      (out_vsync),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos), 
    .pixel_ypos     (pixel_ypos)
    ); 
                 
endmodule 