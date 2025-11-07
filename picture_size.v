

module picture_size (
    input              rst_n         ,
    input              clk           ,         
    input       [15:0] lcd_id        ,
             
    output reg  [12:0] cmos_h_pixel  ,
    output reg  [12:0] cmos_v_pixel  ,   
    output reg  [12:0] total_h_pixel ,
    output reg  [12:0] total_v_pixel ,
    output reg  [12:0] y_addr_st,
    output reg  [12:0] y_addr_end,
    output reg  [27:0] ddr3_addr_max
);

//*****************************************************
//**                    main code                      
//*****************************************************

//��������ͷ����ߴ�Ĵ�С
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        cmos_h_pixel <= 13'b0;
        cmos_v_pixel <= 13'd0;
        ddr3_addr_max <= 23'd0;        
    end 
    else begin    
        case(lcd_id ) 
            16'h4342 : begin
                cmos_h_pixel   <= 13'd480;    
                cmos_v_pixel   <= 13'd272;
                ddr3_addr_max  <= 23'd130560;
            end 
            16'h7084 : begin
                cmos_h_pixel   <= 13'd800;    
                cmos_v_pixel   <= 13'd480;           
                ddr3_addr_max  <= 23'd384000;
            end 
            16'h7016 : begin
                cmos_h_pixel   <= 13'd1024;    
                cmos_v_pixel   <= 13'd600;           
                ddr3_addr_max  <= 23'd614400;
            end    
            16'h1018 : begin
                cmos_h_pixel   <= 13'd1280;    
                cmos_v_pixel   <= 13'd800;           
                ddr3_addr_max  <= 23'd1024000;
            end 
            16'h4384 : begin
                cmos_h_pixel   <= 13'd800;    
                cmos_v_pixel   <= 13'd480;           
                ddr3_addr_max  <= 23'd384000;
            end
            default : begin
                cmos_h_pixel   <= 13'd480;    
                cmos_v_pixel   <= 13'd272;           
                ddr3_addr_max  <= 23'd384000;
            end
        endcase
    end    
end 

//��HTS��VTS�����û�Ӱ������ͷ���ͼ���֡��
always @(*) begin
    case(lcd_id)
        16'h4342 : begin 
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
        16'h7084 : begin  
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
        16'h7016 : begin  
            total_h_pixel = 13'd2200;
            total_v_pixel = 13'd1000;
        end 
        16'h1018 : begin 
            total_h_pixel = 13'd2570;
            total_v_pixel = 13'd980;
        end 
        16'h4384 : begin  
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end
        default : begin
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
    endcase
end 

//����LCD��Ļ�ķֱ��ʱ��������OV5640Ԥ���Ŵ��ڴ�С�����⻭������
always @(*) begin
    case(lcd_id)
        16'h4342 : begin 
            y_addr_st  = 13'd228;
            y_addr_end = 13'd1723;
        end 
        16'h7084 : begin  
            y_addr_st  = 13'd187;
            y_addr_end = 13'd1763;
        end 
        16'h7016 : begin  
            y_addr_st  = 13'd201;
            y_addr_end = 13'd1749;
        end 
        16'h1018 : begin 
            y_addr_st  = 13'd153;
            y_addr_end = 13'd1798;
        end 
        16'h4384 : begin  
            y_addr_st  = 13'd187;
            y_addr_end = 13'd1763;
        end 
        default : begin
            y_addr_st  = 13'd228;
            y_addr_end = 13'd1723;
        end 
    endcase
end 

endmodule 