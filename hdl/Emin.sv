module emin #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter NU_VALUES = 3) 
(	input wire clk_in,
	input wire rst_in,
	input wire [$clog2(I)-1:0] i,
	input wire input_valid,
	input wire [BIT_WIDTH-1:0] T_resp [0:NU_VALUES-1],
	output wire [$clog2(I)-1:0] T_req,
	output wire [$clog2(I)-1:0] j,
	output wire [BIT_WIDTH-1:0] data,
    output wire output_valid
);
	// assumes all of T is computed in T_bram
	// on first cycle of input valid: receive i
	// then E_min requests T(x, i)
	// then we begin main loop over all j
	// - request T(x, j)
	// - when it comes back, do math with T(x, j) and T(x, i)
	// - compute Emin(j+1, i)
	// - then output Emin(j+1, i) to write to correct buffer
	// PIPELINE ABOVE SOMEHOW
	// don't forget delay on T_resp is 2 cycles w.r.t. T_req

	// We need values of T(nu, i)
	
	
endmodule 