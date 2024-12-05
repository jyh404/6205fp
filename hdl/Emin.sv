module #(BIT_WIDTH = 32, I = 160, NU_VALUES = 3) emin(
	input wire clk_in,
	input wire rst_in,
	input wire [$clog2(I)-1:0] i,
	input wire [BIT_WIDTH-1:0] T_resp [0:NU_VALUES-1],
	input wire input_valid,
	output wire [$clog2(I)-1:0] T_req,
	output wire buffer,
	output wire [$clog2(I)-1:0] j,
	output wire [BIT_WIDTH-1:0] data,
    output wire output_valid
);
	// don't forget delay on T_resp is 2 cycles w.r.t. T_req


endmodule 