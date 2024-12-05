module #(
    BIT_WIDTH = 32, 
    I = 160, 
    FORMANTS = 5, 
    NU_VALUES = 3
) 
phi (
	input wire clk_in,
	input wire rst_in,
    input wire [BIT_WIDTH-1:0] T_vals [0:NU_VALUES-1],
    input wire input_valid,
    output wire [BIT_WIDTH-1:0] output [0:FORMANTS-1],
    output wire output_valid,
);


endmodule 