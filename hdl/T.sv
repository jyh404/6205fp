module #(BIT_WIDTH = 32, I = 160, NU_VALUES = 3) t(
	input wire clk_in,
	input wire rst_in,
	input wire fft_valid,
	input wire [BIT_WIDTH-1:0] fft_data,
    output wire [BIT_WIDTH-1:0] output_written [0:NU_VALUES-1],
	output wire output_valid,
	output wire [$clog2(I)-1:0] output_address,
);
	// receives fft data sequentially (I = 160 samples)
	// computes T(0, i) and outputs them sequentially to be stored in BRAM


endmodule 