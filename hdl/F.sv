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
	// assumes E_min(j+1,i) has finished calculating
	// when begin_iter is pulsed:
	//	read in i
	// 	loop on k in 1 ... FORMANTS:
	//   loop on j in k-2 ... i-1:
	//    request k_req = k, j_req = j
	//	  two cycles later receive back E(j+1,i), F(k-1,j), F(k,i)
	//	  compute new value of F(k,i) and B(k,i)
	//	  send k_write = k, f_data = F(k,i), b_data = B(k,i) with output_valid
	//	when finished, output iter_done
	// don't forget delay on e_prev, f_prev, f_old is 2 cycles after k_req,


endmodule 