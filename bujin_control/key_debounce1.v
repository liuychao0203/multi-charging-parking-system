module key_debounce1(
    input            sys_clk,          //external 50M clock
    input            sys_rst_n,        //external reset signal, active low
    
    input            key1,              //external key input
    output reg       key_flag1,         //key data valid signal
    output reg       key_value1         //key debounced data  
    );

//reg define    
reg [31:0] delay_cnt;
reg        key_reg;
reg        first_cycle; //flag to prevent false trigger in first cycle after reset

//*****************************************************
//**                    main code
//*****************************************************
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        key_reg   <= 1'b1;
        delay_cnt <= 32'd0;
        first_cycle <= 1'b1;
    end
    else begin
        key_reg <= key1;
        first_cycle <= 1'b0;
        if(key_reg != key1 && !first_cycle)  //once key state change detected and not first cycle
            delay_cnt <= 32'd1000000;  //reload delay counter (20ms count time)
        else if(key_reg == key1) begin  //when key state is stable, counter decrements
                 if(delay_cnt > 32'd0)
                     delay_cnt <= delay_cnt - 1'b1;
                 else
                     delay_cnt <= delay_cnt;
             end           
    end   
end

always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        key_flag1  <= 1'b0;
        key_value1 <= 1'b1;          
    end
    else begin
        if(delay_cnt == 32'd1) begin   //when counter decrements to 1, key stable for 20ms
            key_flag1  <= 1'b1;         //debounce process complete, give one clock cycle flag
            key_value1 <= key1;          //register the key value
        end
        else begin
            key_flag1  <= 1'b0;
            key_value1 <= key_value1; 
        end  
    end   
end
    
endmodule
