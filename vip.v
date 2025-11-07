
//****************************************************************************************//

module vip(
    //module clock
    input           clk            ,    // ʱ���ź�
    input           rst_n          ,    // ��λ�źţ�����Ч��

    //ͼ����ǰ�����ݽӿ�
    input           pre_frame_vsync,
    input           pre_frame_href ,
    input           pre_frame_de   ,
    input    [15:0] pre_rgb        ,

    //ͼ���������ݽӿ�
    output          post_frame_vsync,   // ��ͬ���ź�
    output          post_frame_href ,   // ��ͬ���ź�
    output          post_frame_de   ,   // ��������ʹ��
    output   [15:0] post_rgb            // RGB565��ɫ����
);

//parameter define
parameter  SOBEL_THRESHOLD = 128; //sobel��ֵ

//wire define
wire   [ 7:0]         img_y;
wire   [ 7:0]         post_img_y;
wire                  pe_frame_vsync;
wire                  pe_frame_href;
wire                  pe_frame_clken;
wire                  ycbcr_vsync;
wire                  ycbcr_href;
wire                  ycbcr_de;
wire                  post_img_bit;

//*****************************************************
//**                    main code
//*****************************************************

assign  post_rgb = {16{~post_img_bit}};

//RGBתYCbCrģ��
rgb2ycbcr u_rgb2ycbcr(
    //module clock
    .clk             (clk    ),            // ʱ���ź�
    .rst_n           (rst_n  ),            // ��λ�źţ�����Ч��
    //ͼ����ǰ�����ݽӿ�
    .pre_frame_vsync (pre_frame_vsync),    // vsync�ź�
    .pre_frame_href  (pre_frame_href ),    // href�ź�
    .pre_frame_de    (pre_frame_de   ),    // data enable�ź�
    .img_red         (pre_rgb[15:11] ),
    .img_green       (pre_rgb[10:5 ] ),
    .img_blue        (pre_rgb[ 4:0 ] ),
    //ͼ���������ݽӿ�
    .post_frame_vsync(pe_frame_vsync),     // vsync�ź�
    .post_frame_href (pe_frame_href ),     // href�ź�
    .post_frame_de   (pe_frame_clken),     // data enable�ź�
    .img_y           (img_y),              //�Ҷ�����
    .img_cb          (),
    .img_cr          ()
);

vip_sobel_edge_detector
    #(
    .SOBEL_THRESHOLD  (SOBEL_THRESHOLD)    //sobel��ֵ
    )
u_vip_sobel_edge_detector(
    .clk (clk),   
    .rst_n (rst_n),  
    
    //����ǰ����
    .pre_frame_vsync (pe_frame_vsync),    //����ǰ֡��Ч�ź�
    .pre_frame_href  (pe_frame_href),     //����ǰ����Ч�ź�
    .pre_frame_clken (pe_frame_clken),    //����ǰͼ��ʹ���ź�
    .pre_img_y       (img_y),             //����ǰ����Ҷ�����
    
    //����������
    .post_frame_vsync (post_frame_vsync), //�����֡��Ч�ź�
    .post_frame_href  (post_frame_href),  //���������Ч�ź�
    .post_frame_clken (post_frame_de),    //���ʹ���ź�
    .post_img_bit     (post_img_bit)      //�������
);

endmodule