module pwm(   input wire clk_in,
              input wire rst_in,
              input wire [7:0] dc_in,
              output logic sig_out);
 
    logic [31:0] count;
    counter mc (.clk_in(clk_in),
                .rst_in(rst_in),
                .period_in(255),
                .count_out(count));
    assign sig_out = {count[0],count[1],count[2],count[3],count[4],count[5],count[6],count[7]}<dc_in; //very simple threshold check
endmodule