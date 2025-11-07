module ov5640_lcd_hdmi(    
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    //摄像头接口                       
    input                 cam_pclk     ,  //cmos 数据像素时钟
    input                 cam_vsync    ,  //cmos 场同步信号
    input                 cam_href     ,  //cmos 行同步信号
    input   [7:0]         cam_data     ,  //cmos 数据
    output                cam_rst_n    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //cmos SCCB_SCL线
    inout                 cam_sda      ,  //cmos SCCB_SDA线       
    // DDR3                            
    inout   [31:0]        ddr3_dq      ,  //DDR3 数据
    inout   [3:0]         ddr3_dqs_n   ,  //DDR3 dqs负
    inout   [3:0]         ddr3_dqs_p   ,  //DDR3 dqs正  
    output  [13:0]        ddr3_addr    ,  //DDR3 地址   
    output  [2:0]         ddr3_ba      ,  //DDR3 banck 选择
    output                ddr3_ras_n   ,  //DDR3 行选择
    output                ddr3_cas_n   ,  //DDR3 列选择
    output                ddr3_we_n    ,  //DDR3 读写选择
    output                ddr3_reset_n ,  //DDR3 复位
    output  [0:0]         ddr3_ck_p    ,  //DDR3 时钟正
    output  [0:0]         ddr3_ck_n    ,  //DDR3 时钟负
    output  [0:0]         ddr3_cke     ,  //DDR3 时钟使能
    output  [0:0]         ddr3_cs_n    ,  //DDR3 片选
    output  [3:0]         ddr3_dm      ,  //DDR3_dm
    output  [0:0]         ddr3_odt     ,  //DDR3_odt        
    //LCD接口                           
    output                lcd_hs       ,  //LCD 行同步信号
    output                lcd_vs       ,  //LCD 场同步信号
    output                lcd_de       ,  //LCD 数据输入使能
    inout   [23:0]        lcd_rgb      ,  //LCD 颜色数据
    output                lcd_bl       ,  //LCD 背光控制信号
    output                lcd_rst      ,  //LCD 复位信号
    output                lcd_pclk     ,  //LCD 采样时钟
    //HDMI接口                           
    output                tmds_clk_p   ,  // TMDS 时钟通道
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  // TMDS 数据通道
    output  [2:0]         tmds_data_n  
    );     
                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列    
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; //CMOS分辨率--列
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;                                               
                               
//wire define                          
wire         clk_50m                   ;  //50mhz时钟
wire         clk_200m                  ;  //DDR3参考时钟
wire         pixel_clk                 ;  //HDMI像素时钟
wire         pixel_clk_5x              ;  //HDMI 5倍像素时钟
wire         lcd_clk                   ;  //LCD时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位                                     
wire         init_calib_complete       ;  //DDR3初始化完成
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire  [15:0] lcd_id                    ;  //LCD屏ID

// 摄像头采集信号 - 原始数据
wire         cmos_frame_vsync          ;  //帧有效场同步信号
wire         cmos_frame_href           ;  //帧有效行同步信号 
wire         cmos_frame_valid          ;  //数据有效使能信号
wire  [15:0] cmos_frame_data           ;  //有效数据

// VIP边缘检测信号 - 处理后数据
wire         post_frame_vsync          ;  //处理后的场信号
wire         post_frame_de             ;  //处理后数据有效使能 
wire  [15:0] post_rgb                  ;  //处理后图像数据

// DDR3接口信号 - HDMI读取通道
wire  [15:0] ddr3_rd_data              ;  //DDR3读出数据（边缘检测后，供HDMI）
wire         ddr3_rdata_req            ;  //DDR3读数据请求

// HDMI显示信号
wire         hdmi_vsync                ;  //HDMI场同步
wire  [10:0] hdmi_pixel_xpos           ;  //HDMI像素横坐标
wire  [10:0] hdmi_pixel_ypos           ;  //HDMI像素纵坐标

// LCD显示信号  
wire         lcd_vsync                 ;  //LCD场同步
wire  [10:0] lcd_h_disp                ;  //LCD水平分辨率
wire  [10:0] lcd_v_disp                ;  //LCD垂直分辨率
wire         lcd_data_req              ;  //LCD数据请求

// LCD原始数据FIFO信号 - 用于缓存原始摄像头数据
wire  [15:0] lcd_fifo_dout             ;  //LCD FIFO读出数据（原始图像）
wire         lcd_fifo_empty             ;  //LCD FIFO空标志
wire         lcd_fifo_rd_en            ;  //LCD FIFO读使能
wire         lcd_fifo_full              ;  //LCD FIFO满标志（用于监控，可选）
//待时钟锁定后，撤销复位信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = init_calib_complete;

// OV5640驱动模块
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (init_calib_complete),
    .cmos_h_pixel      (H_CMOS_DISP),
    .cmos_v_pixel      (V_CMOS_DISP),
    .total_h_pixel     (TOTAL_H_PIXEL),
    .total_v_pixel     (TOTAL_V_PIXEL),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (cmos_frame_href),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (cmos_frame_data)
    );   

// 图像处理模块 - Sobel边缘检测（处理摄像头实时数据）
vip u_vip(
    //module clock
    .clk              (cam_pclk),          // 时钟信号
    .rst_n            (rst_n ),            // 复位信号，低电平有效
    //图像处理前数据接口
    .pre_frame_vsync  (cmos_frame_vsync),
    .pre_frame_href   (cmos_frame_href),
    .pre_frame_de     (cmos_frame_valid),
    .pre_rgb          (cmos_frame_data),
    //图像处理后数据接口
    .post_frame_vsync (post_frame_vsync),  // 处理后的场信号
    .post_frame_href  ( ),                 // 处理后行信号
    .post_frame_de    (post_frame_de),     // 处理后数据有效使能 
    .post_rgb         (post_rgb)           // 处理后图像数据
);  

// DDR3顶层模块 - 存储边缘检测后的数据，供LCD和HDMI显示
ddr3_top u_ddr3_top (
    .rst_n               (rst_n),                     //复位,低电平有效
    .init_calib_complete (init_calib_complete),       //ddr3初始化完成信号    
    //ddr3接口信号       
    .app_addr_rd_min     (28'd0),                     //读DDR3的起始地址
    .app_addr_rd_max     (24'd786432),                //读DDR3的结束地址 (1024*768)
    .rd_bust_len         (H_CMOS_DISP[10:4]),         //从DDR3中读数据时的突发长度
    .app_addr_wr_min     (28'd0),                     //写DDR3的起始地址
    .app_addr_wr_max     (24'd786432),                //写DDR3的结束地址
    .wr_bust_len         (H_CMOS_DISP[10:4]),         //向DDR3中写数据时的突发长度   
    // DDR3 IO接口              
    .ddr3_dq             (ddr3_dq),                   //DDR3 数据
    .ddr3_dqs_n          (ddr3_dqs_n),                //DDR3 dqs负
    .ddr3_dqs_p          (ddr3_dqs_p),                //DDR3 dqs正  
    .ddr3_addr           (ddr3_addr),                 //DDR3 地址   
    .ddr3_ba             (ddr3_ba),                   //DDR3 banck 选择
    .ddr3_ras_n          (ddr3_ras_n),                //DDR3 行选择
    .ddr3_cas_n          (ddr3_cas_n),                //DDR3 列选择
    .ddr3_we_n           (ddr3_we_n),                 //DDR3 读写选择
    .ddr3_reset_n        (ddr3_reset_n),              //DDR3 复位
    .ddr3_ck_p           (ddr3_ck_p),                 //DDR3 时钟正
    .ddr3_ck_n           (ddr3_ck_n),                 //DDR3 时钟负  
    .ddr3_cke            (ddr3_cke),                  //DDR3 时钟使能
    .ddr3_cs_n           (ddr3_cs_n),                 //DDR3 片选
    .ddr3_dm             (ddr3_dm),                   //DDR3_dm
    .ddr3_odt            (ddr3_odt),                  //DDR3_odt
    // System Clock Ports                            
    .sys_clk_i           (clk_200m),   
    // Reference Clock Ports                         
    .clk_ref_i           (clk_200m), 
    //用户接口 - 写入VIP处理后的数据                                           
    .ddr3_read_valid     (1'b1),                      //DDR3 读使能
    .ddr3_pingpang_en    (1'b1),                      //DDR3 乒乓操作使能
    .wr_clk              (cam_pclk),                  //写时钟
    .wr_load             (post_frame_vsync),          //输入源场同步信号   
    .wr_en               (post_frame_de),             //数据有效使能信号
    .wrdata              (post_rgb),                  //VIP处理后的数据 
    .rd_clk              (pixel_clk),                 //读时钟 - HDMI像素时钟
    .rd_load             (hdmi_vsync),                //输出源场同步信号    
    .rddata              (ddr3_rd_data),              //rfifo输出数据
    .rdata_req           (ddr3_rdata_req)             //请求像素点颜色数据   
);                    

// 时钟生成模块
clk_wiz_0 u_clk_wiz_0(
    // Clock out ports
    .clk_out1              (clk_200m),       // 200MHz - DDR3参考时钟
    .clk_out2              (clk_50m),        // 50MHz - 配置时钟
    .clk_out3              (pixel_clk_5x),   // HDMI 5倍像素时钟
    .clk_out4              (pixel_clk),      // HDMI像素时钟
    // Status and control signals
    .reset                 (~sys_rst_n), 
    .locked                (locked),       
    // Clock in ports
    .clk_in1               (sys_clk)
);     
 
// HDMI顶层显示模块 - 显示边缘检测后的画面   
hdmi_top u_hdmi_top(
    .pixel_clk            (pixel_clk),
    .pixel_clk_5x         (pixel_clk_5x),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi接口                
    .tmds_clk_p           (tmds_clk_p),    // TMDS 时钟通道
    .tmds_clk_n           (tmds_clk_n),
    .tmds_data_p          (tmds_data_p),   // TMDS 数据通道
    .tmds_data_n          (tmds_data_n),
    //用户接口 
    .video_vs             (hdmi_vsync),         //HDMI场信号     
    .pixel_xpos           (hdmi_pixel_xpos),    //像素点横坐标
    .pixel_ypos           (hdmi_pixel_ypos),          
    .data_in              (ddr3_rd_data),       //输入边缘检测后的数据 
    .data_req             (ddr3_rdata_req)      //请求像素点颜色数据   
);   

// LCD原始数据FIFO - 缓存摄像头原始图像数据，供LCD显示
// 写时钟：cam_pclk（摄像头像素时钟）
// 读时钟：lcd_clk（LCD驱动时钟）
lcd_data_fifo u_lcd_data_fifo (
    .rst        (~rst_n),                      //复位信号（高电平有效）
    .wr_clk     (cam_pclk),                    //写时钟 - 摄像头像素时钟
    .rd_clk     (lcd_clk),                     //读时钟 - LCD驱动时钟
    .din        (cmos_frame_data),             //写数据 - 摄像头原始RGB565数据
    .wr_en      (cmos_frame_valid),            //写使能 - 摄像头数据有效信号
    .rd_en      (lcd_fifo_rd_en),             //读使能 - LCD数据请求信号
    .dout       (lcd_fifo_dout),               //读数据 - 输出到LCD的原始图像数据
    .full       (lcd_fifo_full),               //FIFO满标志
    .empty      (lcd_fifo_empty),               //FIFO空标志
    .rd_data_count(),                          //读数据计数（未使用）
    .wr_rst_busy(),                            //写复位忙信号（未使用）
    .rd_rst_busy()                             //读复位忙信号（未使用）
);

// LCD FIFO读使能逻辑：当LCD请求数据且FIFO非空时，允许读取
assign lcd_fifo_rd_en = lcd_data_req & ~lcd_fifo_empty;

// LCD顶层显示模块 - 显示原始摄像头图像
// 数据流：摄像头原始数据 → FIFO → LCD（显示原始监控画面）
// 说明：LCD显示原始图像，HDMI显示边缘检测画面
//      使用clk_50m作为sys_clk，让内部clk_div正常工作生成lcd_clk
lcd_rgb_top u_lcd_rgb_top(
    .sys_clk               (clk_50m),          //使用clk_50m作为系统时钟
    .sys_rst_n             (rst_n),
    .sys_init_done         (sys_init_done),        
    //lcd接口 
    .lcd_id                (lcd_id),           //LCD屏幕ID 
    .lcd_hs                (lcd_hs),           //LCD 行同步信号
    .lcd_vs                (lcd_vs),           //LCD 场同步信号
    .lcd_de                (lcd_de),           //LCD 数据输入使能
    .lcd_rgb               (lcd_rgb),          //LCD 颜色数据
    .lcd_bl                (lcd_bl),           //LCD 背光控制信号
    .lcd_rst               (lcd_rst),          //LCD 复位信号
    .lcd_pclk              (lcd_pclk),         //LCD 采样时钟
    .lcd_clk               (lcd_clk),            //LCD驱动时钟（由内部clk_div生成）
    //用户接口 - 从FIFO读取原始数据                       
    .out_vsync             (lcd_vsync),        //lcd场信号
    .h_disp                (lcd_h_disp),       //行分辨率  
    .v_disp                (lcd_v_disp),       //列分辨率  
    .pixel_xpos            (),
    .pixel_ypos            (),       
    .data_in               (lcd_fifo_dout),     //从FIFO读取原始摄像头数据
    .data_req              (lcd_data_req)      //请求像素点颜色数据
);   

endmodule
