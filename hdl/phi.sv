module phi #(
    parameter BIT_WIDTH = 32, 
    parameter I = 160, 
    parameter FORMANTS = 5, 
    parameter NU_VALUES = 3
) ( input wire clk_in,
	input wire rst_in,
    input wire [BIT_WIDTH-1:0] T_vals [0:NU_VALUES-1],
    input wire input_start,
    input wire input_valid,
    output logic [BIT_WIDTH-1:0] output_data [0:FORMANTS-1],
    output logic output_valid
);
    // assumes that segments have been calculated already
    // when input_start is pulsed
    // on the kth time we see input_valid, we read in T_vals
    //  we interpret this as T_vals at the right end of the kth interval
    // we save these T_vals locally
    // then do math with local values and output all phi values at once

	assign output_data[0] = 0;
	assign output_valid = 0;
endmodule 