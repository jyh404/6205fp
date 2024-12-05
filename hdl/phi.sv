module #(BIT_WIDTH = 32, FORMANTS = 5) f(
	input wire clk_in,
	input wire rst_in,
    input wire [BIT_WIDTH-1:0] left [0:2],
    input wire [BIT_WIDTH-1:0] right [0:2],
    input wire input_valid,
    output wire [BIT_WIDTH-1:0] phi [0:FORMANTS],
    output wire output_valid,
);


endmodule 