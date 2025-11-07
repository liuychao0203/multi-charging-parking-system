// ============================================================================
// ����ģ�飨ģ�黯�ع��汾��
// ��Ŀ�����ܳ�λ��������ϵͳ
// ���ܣ�����������ģ�飬�ṩ���Ķ���ӿ�
// ============================================================================

module top_key_bujing_new(
    input        sys_clk,           // ϵͳʱ�� 50MHz
    input        sys_rst_n,         // ��λ�ź�
    
    // ��������
    input        key1,              // X����ת����
    input        key2,              // X�ᷴת����
    input        touchkey,          // Y����ת����
    input        j14_sensor,        // J14���������루���ƶ����
    
    // ����ģ��ӿ�
    input        bt_rx,             // ��������
    
    // �������ӿ�
  
    input        rain_sensor,       // ��ˮ������
    input        flame_sensor,      // ���洫����
    input        x_limit_switch,    // X����λ����
    
    // ������
    output       beep,              // ���������
    
    // X�Ჽ���������
    output       EA1,               // X��ʹ��
    output       DIR1,              // X�᷽��
    output       pwm_out1,          // X������
    
    // Y�Ჽ���������
    output       EA2,               // Y��ʹ��
    output       DIR2,              // Y�᷽��
    output       pwm_out_y,         // Y������
    
    // LED״ָ̬ʾ
    output       led_status1,       // ����״̬
    output       led_status2,       // ����״̬
    output       led_status3,       // ����״̬
    
    // ��������˿�
    output       pwm_out2,
    output       pwm_out3,
    output       pwm_out4,
    output       output_a,
    output       output_b,
    
    // ֱ��������ƣ�Y7��Y9��
    output       motor_y7,          // �������Y7
    output       motor_y9,          // �������Y9
    
    // SG90�������
    output       servo_pwm         // ���PWM�ź�
    

);

// ============================================================================
// �ڲ��źŶ���
// ============================================================================

// ���������ź�
wire key_value1, key_flag1;
wire key_value2, key_flag2;
wire touchkey_value, touchkey_flag;

// ��������ź�
wire bt_rx_done;
wire [7:0] bt_rx_data;
wire bt_coord_cmd_valid;
wire [1:0] bt_target_x, bt_target_y;
wire bt_x_forward_cmd, bt_x_reverse_cmd, bt_x_stop_cmd;
wire bt_y_forward_cmd, bt_y_reverse_cmd, bt_y_stop_cmd;
wire bt_motor_forward_cmd, bt_motor_reverse_cmd, bt_motor_stop_cmd;
wire bt_servo_ccw_cmd, bt_servo_cw_cmd;

// DHT11�������ź�
wire [7:0] dht11_humidity_int, dht11_humidity_dec;
wire [7:0] dht11_temperature_int, dht11_temperature_dec;
wire dht11_data_valid, dht11_read_error;
wire [3:0] debug_state;

// ��������ź�
wire coord_enable;
wire coord_x_run, coord_x_dir;
wire coord_y_run, coord_y_dir;
wire coord_motor_enable;
wire [1:0] coord_motor_state;

// �������״̬
wire x_running, y_running;
wire motor_step_x, motor_step_y;

// ��λ�ȶ��ź�
reg [15:0] reset_stable_cnt;
reg reset_stable;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        reset_stable_cnt <= 16'd0;
        reset_stable <= 1'b0;
    end else begin
        if (reset_stable_cnt < 16'd1000) begin
            reset_stable_cnt <= reset_stable_cnt + 1'b1;
            reset_stable <= 1'b0;
        end else begin
            reset_stable <= 1'b1;
        end
    end
end

// ����������������
wire x_forward_pulse = (reset_stable && key_flag1 && (~key_value1)) || bt_x_forward_cmd;
wire x_reverse_pulse = (reset_stable && key_flag2 && (~key_value2)) || bt_x_reverse_cmd;
wire x_stop_pulse = bt_x_stop_cmd;

wire y_forward_pulse = (reset_stable && touchkey_flag && (~touchkey_value)) || bt_y_forward_cmd;
wire y_reverse_pulse = bt_y_reverse_cmd;
wire y_stop_pulse = bt_y_stop_cmd;

// ============================================================================
// ģ��ʵ����
// ============================================================================

// ---------- ��������ģ�� ----------
key_debounce1 u_key_debounce1(
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .key1       (key1),
    .key_flag1  (key_flag1),
    .key_value1 (key_value1)
);

key_debounce2 u_key_debounce2(
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .key2       (key2),
    .key_flag2  (key_flag2),
    .key_value2 (key_value2)
);

key_debounce3 u_key_debounce_touchkey(
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .key3       (touchkey),
    .key_flag3  (touchkey_flag),
    .key_value3 (touchkey_value)
);

// ---------- ����ͨ��ģ�� ----------
uart_rx u_uart_rx(
    .clk      (sys_clk),
    .rst_n    (sys_rst_n),
    .uart_rx  (bt_rx),
    .rx_done  (bt_rx_done),
    .rx_data  (bt_rx_data)
);

bluetooth_cmd_parser u_bluetooth_cmd_parser(
    .clk               (sys_clk),
    .rst_n             (sys_rst_n),
    .rx_done           (bt_rx_done),
    .rx_data           (bt_rx_data),
    .coord_cmd_valid   (bt_coord_cmd_valid),
    .target_x          (bt_target_x),
    .target_y          (bt_target_y),
    .x_forward_cmd     (bt_x_forward_cmd),
    .x_reverse_cmd     (bt_x_reverse_cmd),
    .x_stop_cmd        (bt_x_stop_cmd),
    .y_forward_cmd     (bt_y_forward_cmd),
    .y_reverse_cmd     (bt_y_reverse_cmd),
    .y_stop_cmd        (bt_y_stop_cmd),
    .motor_forward_cmd (bt_motor_forward_cmd),
    .motor_reverse_cmd (bt_motor_reverse_cmd),
    .motor_stop_cmd    (bt_motor_stop_cmd),
    .servo_ccw_cmd     (bt_servo_ccw_cmd),
    .servo_cw_cmd      (bt_servo_cw_cmd)
);


// ---------- �������ϵͳģ�� ----------
coordinate_controller u_coordinate_controller(
    .clk               (sys_clk),
    .rst_n             (sys_rst_n),
    .coord_cmd_valid   (bt_coord_cmd_valid),
    .target_x          (bt_target_x),
    .target_y          (bt_target_y),
    .x_run             (coord_x_run),
    .x_dir             (coord_x_dir),
    .y_run             (coord_y_run),
    .y_dir             (coord_y_dir),
    .motor_ctrl_enable (coord_motor_enable),
    .motor_state       (coord_motor_state),
    .coord_enable      (coord_enable)
);

// ---------- X�Ჽ����������� ----------
stepper_motor_controller u_stepper_x(
    .clk           (sys_clk),
    .rst_n         (sys_rst_n),
    .forward_cmd   (x_forward_pulse),
    .reverse_cmd   (x_reverse_pulse),
    .stop_cmd      (x_stop_pulse),
    .coord_enable  (coord_enable),
    .coord_run     (coord_x_run),
    .coord_dir     (coord_x_dir),
    .motor_enable  (EA1),
    .motor_dir     (DIR1),
    .motor_step    (pwm_out1),
    .running       (x_running)
);

// ---------- Y�Ჽ����������� ----------
stepper_motor_controller u_stepper_y(
    .clk           (sys_clk),
    .rst_n         (sys_rst_n),
    .forward_cmd   (y_forward_pulse),
    .reverse_cmd   (y_reverse_pulse),
    .stop_cmd      (y_stop_pulse),
    .coord_enable  (coord_enable),
    .coord_run     (coord_y_run),
    .coord_dir     (coord_y_dir),
    .motor_enable  (EA2),
    .motor_dir     (DIR2),
    .motor_step    (pwm_out_y),
    .running       (y_running)
);

// ---------- ֱ�������������Y7/Y9��----------
dc_motor_controller u_dc_motor(
    .clk           (sys_clk),
    .rst_n         (sys_rst_n),
    .forward_cmd   (bt_motor_forward_cmd),
    .reverse_cmd   (bt_motor_reverse_cmd),
    .stop_cmd      (bt_motor_stop_cmd),
    .coord_enable  (coord_motor_enable),
    .coord_state   (coord_motor_state),
    .motor_pin1    (motor_y7),
    .motor_pin2    (motor_y9)
);

// ---------- SG90��������� ----------
servo_controller u_servo(
    .clk            (sys_clk),
    .rst_n          (sys_rst_n),
    .sensor_trigger (j14_sensor),
    .ccw_cmd        (bt_servo_ccw_cmd),
    .cw_cmd         (bt_servo_cw_cmd),
    .servo_pwm      (servo_pwm)
);

// ---------- �澯������ ----------
alarm_controller u_alarm(
    .clk             (sys_clk),
    .rst_n           (sys_rst_n),
    .humidity_int    (dht11_humidity_int),
    .humidity_valid  (dht11_data_valid),
    .rain_sensor     (rain_sensor),
    .flame_sensor    (flame_sensor),
    .limit_switch    (x_limit_switch),
    .beep            (beep)
);




// ============================================================================
// LED״ָ̬ʾ
// ============================================================================
assign led_status1 = x_running || y_running;  // ����״̬
assign led_status2 = bt_rx_done;              // ��������ָʾ
assign led_status3 = pwm_out1 || pwm_out_y || (bt_x_forward_cmd || bt_x_reverse_cmd || bt_y_forward_cmd || bt_y_reverse_cmd);

// ============================================================================
// ��������˿�
// ============================================================================
assign pwm_out2 = 1'b0;
assign pwm_out3 = 1'b0;
assign pwm_out4 = 1'b0;
assign output_a = 1'b0;
assign output_b = 1'b0;

endmodule
