module #(BIT_WIDTH = 32, I = 160, FORMANTS = 5) f(
	input wire clk_in,
	input wire rst_in,
	input wire begin_iter,
	input wire [$clog2(I)-1:0] i, // decide when to begin processing i, needs Emin to finish
	input wire [BIT_WIDTH-1:0] e_prev, // E(j+1,i)
	input wire [BIT_WIDTH-1:0] f_prev, // F(k-1,j)
	input wire [BIT_WIDTH-1:0] f_old, // old F(k,i)
	output wire [$clog2(FORMANTS)-1:0] k_req,
	output wire [$clog2(I)-1:0] j_req,
	output wire [$clog2(FORMANTS)-1:0] k_write,
	output wire [BIT_WIDTH-1:0] f_data,
	output wire [BIT_WIDTH-1:0] b_data,
    output wire output_valid,
	output wire iter_done, // pulse when iteration for i is done
);
	// don't forget delay on e_prev, f_prev, f_old is 2 cycles after k_req,


endmodule 