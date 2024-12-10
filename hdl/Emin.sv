module emin #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter NU_VALUES = 3) 
(	input wire clk_in,
	input wire rst_in,
	input wire [$clog2(I)-1:0] i,
	input wire input_valid,
	input wire [BIT_WIDTH-1:0] T_resp [0:NU_VALUES-1],
	output logic [$clog2(I)-1:0] T_req,
	output logic [$clog2(I)-1:0] j_out,
	output logic [BIT_WIDTH-1:0] data_out,
    output logic output_valid
);
	// assumes all of T is computed in T_bram
	// on first cycle of input valid: receive i
	// then E_min requests T(x, i)
	// then we begin main loop over all j
	// - request T(x, j-1)
	// - when it comes back, do math with T(x, j-1) and T(x, i)
	// - compute Emin(j, i)
	// - then output Emin(j, i) to write to correct buffer
	// PIPELINE ABOVE SOMEHOW
	// don't forget delay on T_resp is 2 cycles w.r.t. T_req

	typedef enum {START, REQ_I, CALC} poss_state;
	poss_state state;
	
	logic signed [BIT_WIDTH-1:0] T_i [0:NU_VALUES-1];
	logic [$clog2(I)-1:0] i_reg;
	logic [$clog2(I)-1:0] j_reg;
	logic delay;

	parameter NUM_STAGES = 20;
	logic [BIT_WIDTH-1:0] pipeline [0:NUM_STAGES-1][0:5];
	// 0: 0 = j
	// 1:
	// 2: 1 = r(0, j-1, i), 2 = r(1, j-1, i), 3 = r(2, j-1, i)
	// 3: 4 = alpha_k num, 5 = beta_k num
	// 19: 4 = alpha_k, 5 = beta_k
	// then write E_min to output

	logic sign_pipeline [0:NUM_STAGES-1];
	// because our division algorithm is unsigned
	// just keep track of sign of the dividend
	
	logic valid_pipeline [0:NUM_STAGES-1];
	// keep track of when pipeline is still calculating

	logic [BIT_WIDTH-1:0] r0, r1, r2, stage2j;
	assign stage2j = pipeline[1][0];
	assign r0 = (pipeline[1][0]) ? ($signed(T_i[0]) - $signed(T_resp[0])) : $signed(T_i[0]);
	assign r1 = (pipeline[1][0]) ? ($signed(T_i[1]) - $signed(T_resp[1])) : $signed(T_i[1]);
	assign r2 = (pipeline[1][0]) ? ($signed(T_i[2]) - $signed(T_resp[2])) : $signed(T_i[2]);

	logic [BIT_WIDTH-1:0] divisor;
	logic [BIT_WIDTH-1:0] quotient;

	divider4 #(
		.WIDTH(BIT_WIDTH)
	)
	divider (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.dividend_in(1<<(BIT_WIDTH-1)),
		.divisor_in(divisor),
		.data_valid_in(1'b1),
		.quotient_out(quotient),
		.remainder_out(),
		.data_valid_out(),
		.error_out(),
		.busy_out()
	);

	parameter NUM_MULTS = 9;
	logic signed [BIT_WIDTH-1:0] a_factor [0:NUM_MULTS-1];
	logic signed [BIT_WIDTH-1:0] b_factor [0:NUM_MULTS-1];
	logic signed [BIT_WIDTH-1:0] mult_res [0:NUM_MULTS-1];
	generate
		// we need seven multipliers for our pipeline
		genvar f;
		for (f = 0; f < NUM_MULTS; ++f) begin
			Multiply_re #(
				.WIDTH(BIT_WIDTH)
			)
			multiplier (
				.a_re(a_factor[f]),
				.b_re(b_factor[f]),
				.m_re(mult_res[f])
			);
		end
	endgenerate

	// now assign our multipliers
	// 0 is stage 2 r(0) r(1)
	// 1 is stage 2 r(1) r(2)
	// 2 is stage 2 r(0) r(0)
	// 3 is stage 2 r(1) r(1)
	// 4 is stage 2 r(0) r(2)
	// 5 is stage 19 r(1) alpha_k
	// 6 is stage 19 r(2) beta_k
	// 7 is stage 18 alpha_k_num (1/denom*sign)
	// 8 is stage 18 beta_k_num (1/denom*sign)
	assign a_factor[0] = pipeline[2][1];
	assign a_factor[1] = pipeline[2][2];
	assign a_factor[2] = pipeline[2][1];
	assign a_factor[3] = pipeline[2][2];
	assign a_factor[4] = pipeline[2][1];
	assign a_factor[5] = pipeline[19][2];
	assign a_factor[6] = pipeline[19][3];
	assign a_factor[7] = pipeline[18][4];
	assign a_factor[8] = pipeline[18][5];
	
	assign b_factor[0] = pipeline[2][2];
	assign b_factor[1] = pipeline[2][3];
	assign b_factor[2] = pipeline[2][1];
	assign b_factor[3] = pipeline[2][2];
	assign b_factor[4] = pipeline[2][3];
	assign b_factor[5] = pipeline[19][4];
	assign b_factor[6] = pipeline[19][5];
	assign b_factor[7] = signed_quotient;
	assign b_factor[8] = signed_quotient;

	logic signed [BIT_WIDTH-1:0] alpha_k_num;
	logic signed [BIT_WIDTH-1:0] beta_k_num;
	logic signed [BIT_WIDTH-1:0] denom;
	logic signed [BIT_WIDTH-1:0] abs_denom;
	logic signed [BIT_WIDTH-1:0] signed_quotient;
	logic signed [BIT_WIDTH-2:0] flipped_quotient;

	assign alpha_k_num = $signed(mult_res[0]) - $signed(mult_res[1]);
	assign beta_k_num = $signed(mult_res[4]) - $signed(mult_res[3]);
	assign denom = $signed(mult_res[2]) - $signed(mult_res[3]);
	
	assign abs_denom = (denom[31]) ? denom : ~denom + 1;

	// combine quotient with sign_pipeline[18]
	// assume quotient[31] is 0,
	// i.e. it's actually <= 31 bit unsigned integer, so flip as normal
	assign flipped_quotient = ~quotient[30:0] + 1; // need to split into two steps bc cocotb
	assign signed_quotient = (sign_pipeline[18]) ? $signed({1'b1, flipped_quotient}) : $signed({1'b0, quotient[30:0]});

	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			integer b;
			for (b = 0; b < NU_VALUES; ++b) begin
				T_i[b] <= 0;
			end
			state <= START;
			for (b = 0; b < NUM_STAGES; ++b) begin
				valid_pipeline[b] <= 1'b0;
			end
			output_valid <= 1'b0;
		end else begin
			case (state)
				START: begin
					output_valid <= 1'b0;
					if (input_valid) begin
						i_reg <= i;
						T_req <= i;
						state <= REQ_I;
						delay <= 1'b1; // delay = 1 means 2 cycles later
					end
				end
				REQ_I: begin
					if (delay) begin
						delay <= delay - 1;
					end else begin
						// received
						// T_i <= T_resp; cocotb can't simulate this
						for (integer b = 0; b < NU_VALUES; ++b) begin
							T_i[b] <= T_resp[b];
						end
						j_reg <= 0;
						state <= CALC;
					end
				end
				CALC: begin
					if (j_reg <= i) begin
						// send in a request
						T_req <= j_reg - 1; 
						j_reg <= j_reg + 1;
						pipeline[0][0] <= j_reg;
						for (integer entry = 1; entry <= 5; ++entry) begin
							pipeline[0][entry] <= 0;
						end
						sign_pipeline[0] <= 1'b0;
						valid_pipeline[0] <= 1'b1;
					end else begin
						sign_pipeline[0] <= 1'b0;
						valid_pipeline[0] <= 1'b0;
					end
					for (integer stage = 1; stage < NUM_STAGES; ++stage) begin
						if (stage != 2 && stage != 3 && stage != 19) begin
							// pass on value
							// pipeline[stage] <= pipeline[stage-1]; doesn't work on cocotb
							for (integer entry = 0; entry <= 5; ++entry) begin
								pipeline[stage][entry] <= pipeline[stage-1][entry];
							end
							sign_pipeline[stage] <= sign_pipeline[stage-1];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end else if (stage == 2) begin
							// calculate values from T_resp which just came in
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= r0;
							pipeline[stage][2] <= r1;
							pipeline[stage][3] <= r2;
							pipeline[stage][4] <= pipeline[stage-1][4];
							pipeline[stage][5] <= pipeline[stage-1][5];
							sign_pipeline[stage] <= sign_pipeline[stage-1];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end else if (stage == 3) begin
							// calculate alpha_k num, beta_k num, denom to divisor
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= pipeline[stage-1][1];
							pipeline[stage][2] <= pipeline[stage-1][2];
							pipeline[stage][3] <= pipeline[stage-1][3];
							pipeline[stage][4] <= alpha_k_num;
							pipeline[stage][5] <= beta_k_num;
							sign_pipeline[stage] <= denom[31];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
							divisor <= (abs_denom) ? abs_denom : 1; // avoid problem with 1
						end else begin
							// stage == 19, form alpha_k, beta_k
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= pipeline[stage-1][1];
							pipeline[stage][2] <= pipeline[stage-1][2];
							pipeline[stage][3] <= pipeline[stage-1][3];
							pipeline[stage][4] <= mult_res[7];
							pipeline[stage][5] <= mult_res[8];
							sign_pipeline[stage] <= sign_pipeline[stage-1];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end
					end
					if (valid_pipeline[NUM_STAGES-1]) begin
						j_out <= pipeline[NUM_STAGES-1][0];
						data_out <= $signed(pipeline[NUM_STAGES-1][1]) - $signed(mult_res[5]) - $signed(mult_res[6]);
						output_valid <= 1'b1;
						if (pipeline[NUM_STAGES-1][0] == i) begin // we output the last one
							state <= START;
						end
					end else begin
						output_valid <= 1'b0;
					end
				end
			endcase
		end
	end
	
endmodule 