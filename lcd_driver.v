

module lcd_driver(
    input               lcd_clk,      //lcdģ������ʱ��
    input               rst_n,    //��λ�ź�
    input   [15:0]      lcd_id,       //LCD��ID
    input   [15:0]      pixel_data,   //���ص�����
    output  reg         data_req  ,   //�������ص���ɫ�������� 
    output  reg [10:0]  pixel_xpos,   //���ص������
    output  reg [10:0]  pixel_ypos,   //���ص�������
    output  reg [10:0]  h_disp,       //LCD��ˮƽ�ֱ���
    output  reg [10:0]  v_disp,       //LCD����ֱ�ֱ��� 
    output              out_vsync,    //֡��λ������Ч   
    //RGB LCD�ӿ�                          
    output              lcd_hs,       //LCD ��ͬ���ź�
    output              lcd_vs,       //LCD ��ͬ���ź�
    output  reg         lcd_de,       //LCD ��������ʹ��
    output  [15:0]      lcd_rgb,      //LCD RGB565��ɫ����
    output              lcd_bl,       //LCD ��������ź�
    output              lcd_rst,      //LCD ��λ�ź�
    output              lcd_pclk      //LCD ����ʱ��   
    );                             
                                                        
//parameter define  
// 4.3' 480*272
parameter  H_SYNC_4342   =  11'd41;     //��ͬ��
parameter  H_BACK_4342   =  11'd2;      //����ʾ����
parameter  H_DISP_4342   =  11'd480;    //����Ч����
parameter  H_FRONT_4342  =  11'd2;      //����ʾǰ��
parameter  H_TOTAL_4342  =  11'd525;    //��ɨ������
   
parameter  V_SYNC_4342   =  11'd10;     //��ͬ��
parameter  V_BACK_4342   =  11'd2;      //����ʾ����
parameter  V_DISP_4342   =  11'd272;    //����Ч����
parameter  V_FRONT_4342  =  11'd2;      //����ʾǰ��
parameter  V_TOTAL_4342  =  11'd286;    //��ɨ������
   
// 7' 800*480   
parameter  H_SYNC_7084   =  11'd128;    //��ͬ��
parameter  H_BACK_7084   =  11'd88;     //����ʾ����
parameter  H_DISP_7084   =  11'd800;    //����Ч����
parameter  H_FRONT_7084  =  11'd40;     //����ʾǰ��
parameter  H_TOTAL_7084  =  11'd1056;   //��ɨ������
   
parameter  V_SYNC_7084   =  11'd2;      //��ͬ��
parameter  V_BACK_7084   =  11'd33;     //����ʾ����
parameter  V_DISP_7084   =  11'd480;    //����Ч����
parameter  V_FRONT_7084  =  11'd10;     //����ʾǰ��
parameter  V_TOTAL_7084  =  11'd525;    //��ɨ������       
   
// 7' 1024*600   
parameter  H_SYNC_7016   =  11'd20;     //��ͬ��
parameter  H_BACK_7016   =  11'd140;    //����ʾ����
parameter  H_DISP_7016   =  11'd1024;   //����Ч����
parameter  H_FRONT_7016  =  11'd160;    //����ʾǰ��
parameter  H_TOTAL_7016  =  11'd1344;   //��ɨ������
   
parameter  V_SYNC_7016   =  11'd3;      //��ͬ��
parameter  V_BACK_7016   =  11'd20;     //����ʾ����
parameter  V_DISP_7016   =  11'd600;    //����Ч����
parameter  V_FRONT_7016  =  11'd12;     //����ʾǰ��
parameter  V_TOTAL_7016  =  11'd635;    //��ɨ������
   
// 10.1' 1280*800   
parameter  H_SYNC_1018   =  11'd10;     //��ͬ��
parameter  H_BACK_1018   =  11'd80;     //����ʾ����
parameter  H_DISP_1018   =  11'd1280;   //����Ч����
parameter  H_FRONT_1018  =  11'd70;     //����ʾǰ��
parameter  H_TOTAL_1018  =  11'd1440;   //��ɨ������
   
parameter  V_SYNC_1018   =  11'd3;      //��ͬ��
parameter  V_BACK_1018   =  11'd10;     //����ʾ����
parameter  V_DISP_1018   =  11'd800;    //����Ч����
parameter  V_FRONT_1018  =  11'd10;     //����ʾǰ��
parameter  V_TOTAL_1018  =  11'd823;    //��ɨ������

// 4.3' 800*480   
parameter  H_SYNC_4384   =  11'd128;    //��ͬ��
parameter  H_BACK_4384   =  11'd88;     //����ʾ����
parameter  H_DISP_4384   =  11'd800;    //����Ч����
parameter  H_FRONT_4384  =  11'd40;     //����ʾǰ��
parameter  H_TOTAL_4384  =  11'd1056;   //��ɨ������
   
parameter  V_SYNC_4384   =  11'd2;      //��ͬ��
parameter  V_BACK_4384   =  11'd33;     //����ʾ����
parameter  V_DISP_4384   =  11'd480;    //����Ч����
parameter  V_FRONT_4384  =  11'd10;     //����ʾǰ��
parameter  V_TOTAL_4384  =  11'd525;    //��ɨ������    

//reg define
reg  [10:0] h_sync ;
reg  [10:0] h_back ;
reg  [10:0] h_total;
reg  [10:0] v_sync ;
reg  [10:0] v_back ;
reg  [10:0] v_total;
reg  [10:0] h_cnt  ;
reg  [10:0] v_cnt  ;

//wire define
wire       lcd_en;

//*****************************************************
//**                    main code
//*****************************************************

assign lcd_bl   = 1'b1;           //RGB LCD��ʾģ�鱳������ź�
assign lcd_rst  = 1'b1;           //RGB LCD��ʾģ��ϵͳ��λ�ź�
assign lcd_pclk = lcd_clk;        //RGB LCD��ʾģ�����ʱ��

//RGB LCD ������������ʹ���ź�ͬ��ʱ���г�ͬ���ź���Ҫ����
assign lcd_hs  = 1'b1;
assign lcd_vs  = 1'b1;

//ʹ��RGB565�������
assign  lcd_en = ((h_cnt >= h_sync + h_back) && (h_cnt < h_sync + h_back + h_disp)
                  && (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp)) 
                  ? 1'b1 : 1'b0;
 
//֡��λ������Ч               
assign out_vsync = ((h_cnt <= 100) && (v_cnt == 1)) ? 1'b1 : 1'b0;

//RGB565�������
assign lcd_rgb = lcd_de ? pixel_data : 16'd0;

//���ص�����
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)
        pixel_xpos <= 11'd0;
    else if(data_req)
        pixel_xpos <= h_cnt + 2'd2 - h_sync - h_back ;
    else 
        pixel_xpos <= 11'd0;
end
       
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)
        pixel_ypos <= 11'd0;
    else if(v_cnt >= (v_sync + v_back)&&v_cnt < (v_sync + v_back + v_disp))
        pixel_ypos <= v_cnt + 1'b1 - (v_sync + v_back) ;
    else 
        pixel_ypos <= 11'd0;
end

//�г�ʱ�����
always @(posedge lcd_clk) begin
    case(lcd_id)
        16'h4342 : begin
            h_sync  <= H_SYNC_4342; 
            h_back  <= H_BACK_4342; 
            h_disp  <= H_DISP_4342; 
            h_total <= H_TOTAL_4342;
            v_sync  <= V_SYNC_4342; 
            v_back  <= V_BACK_4342; 
            v_disp  <= V_DISP_4342; 
            v_total <= V_TOTAL_4342;            
        end
        16'h7084 : begin
            h_sync  <= H_SYNC_7084; 
            h_back  <= H_BACK_7084; 
            h_disp  <= H_DISP_7084; 
            h_total <= H_TOTAL_7084;
            v_sync  <= V_SYNC_7084; 
            v_back  <= V_BACK_7084; 
            v_disp  <= V_DISP_7084; 
            v_total <= V_TOTAL_7084;        
        end
        16'h7016 : begin
            h_sync  <= H_SYNC_7016; 
            h_back  <= H_BACK_7016; 
            h_disp  <= H_DISP_7016; 
            h_total <= H_TOTAL_7016;
            v_sync  <= V_SYNC_7016; 
            v_back  <= V_BACK_7016; 
            v_disp  <= V_DISP_7016; 
            v_total <= V_TOTAL_7016;            
        end
        16'h4384 : begin
            h_sync  <= H_SYNC_4384; 
            h_back  <= H_BACK_4384; 
            h_disp  <= H_DISP_4384; 
            h_total <= H_TOTAL_4384;
            v_sync  <= V_SYNC_4384; 
            v_back  <= V_BACK_4384; 
            v_disp  <= V_DISP_4384; 
            v_total <= V_TOTAL_4384;             
        end        
        16'h1018 : begin
            h_sync  <= H_SYNC_1018; 
            h_back  <= H_BACK_1018; 
            h_disp  <= H_DISP_1018; 
            h_total <= H_TOTAL_1018;
            v_sync  <= V_SYNC_1018; 
            v_back  <= V_BACK_1018; 
            v_disp  <= V_DISP_1018; 
            v_total <= V_TOTAL_1018;        
        end
        default : begin
            h_sync  <= H_SYNC_4342; 
            h_back  <= H_BACK_4342; 
            h_disp  <= H_DISP_4342; 
            h_total <= H_TOTAL_4342;
            v_sync  <= V_SYNC_4342; 
            v_back  <= V_BACK_4342; 
            v_disp  <= V_DISP_4342; 
            v_total <= V_TOTAL_4342;          
        end
    endcase	
end

//����ʹ���ź�		
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)	
		lcd_de <= 1'b0;
	else
		lcd_de <= data_req;
end
				  
//�������ص���ɫ��������  
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)	
		data_req <= 1'b0;
	else if((h_cnt >= h_sync + h_back - 2'd2) && (h_cnt < h_sync + h_back + h_disp - 2'd2)
             && (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp))
		data_req <= 1'b1;
	else
		data_req <= 1'b0;
end

//�м�����������ʱ�Ӽ���
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) 
        h_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1)
            h_cnt <= 11'd0;
        else
            h_cnt <= h_cnt + 1'b1;           
    end
end

//�����������м���
always@ (posedge lcd_clk or negedge rst_n) begin
    if(!rst_n) 
        v_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1) begin
            if(v_cnt == v_total - 1'b1)
                v_cnt <= 11'd0;
            else
                v_cnt <= v_cnt + 1'b1;    
        end
    end    
end
 
endmodule 