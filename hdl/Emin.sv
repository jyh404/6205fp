module emin #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter NU_VALUES = 3) 
(	input wire clk_in,
	input wire rst_in,
	input wire [$clog2(I)-1:0] i,
	input wire input_valid,
	input wire [BIT_WIDTH-1:0] T_resp0,
	input wire [BIT_WIDTH-1:0] T_resp1,
	input wire [BIT_WIDTH-1:0] T_resp2,
	output logic [$clog2(I)-1:0] T_req,
	output logic [$clog2(I)-1:0] j_out,
	output logic [BIT_WIDTH-1:0] data_out,
    output logic output_valid,
	output logic iter_done
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
	// split up T_resp because iverilog
	logic [BIT_WIDTH-1:0] T_resp [0:NU_VALUES-1];
	assign T_resp[0] = T_resp0;
	assign T_resp[1] = T_resp1;
	assign T_resp[2] = T_resp2;
	
	logic [$clog2(I)-1:0] i_reg;
	logic [$clog2(I)-1:0] j_reg;
	logic [1:0] delay;

	parameter NUM_STAGES = 70;
	logic signed [BIT_WIDTH-1:0] pipeline [0:NUM_STAGES-1][0:3];
	logic sign_pipeline[0:NUM_STAGES-1][0:2];
	// 0: 0 = j
	// 1:
	// 2: 1 = r(0, j-1, i), 2 = r(1, j-1, i), 3 = r(2, j-1, i)
	// 3: compute alpha_k_num, beta_k_num, denom
	// 4: make alpha_k_num, beta_k_num, denom unsigned, send to dividers
	//	  (alpha_k_num/denom), (beta_k_num/denom) sent to dividers
	//	  divider is unsigned, so need to save signs in pipeline
	// 68: dividers done, write E_min to output
	
	logic valid_pipeline [0:NUM_STAGES-1];
	// keep track of when pipeline is still calculating

	logic signed [BIT_WIDTH-1:0] r0, r1, r2;
	assign r0 = (pipeline[1][0]) ? ($signed(T_i[0]) - $signed(T_resp[0])) : $signed(T_i[0]);
	assign r1 = (pipeline[1][0]) ? ($signed(T_i[1]) - $signed(T_resp[1])) : $signed(T_i[1]);
	assign r2 = (pipeline[1][0]) ? ($signed(T_i[2]) - $signed(T_resp[2])) : $signed(T_i[2]);

	logic [2*BIT_WIDTH-1:0] dividend_a, dividend_b;
	logic [2*BIT_WIDTH-1:0] quotient_a, quotient_b;
	logic [2*BIT_WIDTH-1:0] divisor;

	divider3 #(
		.WIDTH(2*BIT_WIDTH)
	)
	divider_a (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.dividend_in(dividend_a),
		.divisor_in(divisor),
		.data_valid_in(1'b1),
		.quotient_out(quotient_a),
		.remainder_out(),
		.data_valid_out(),
		.error_out(),
		.busy_out()
	);

	divider3 #(
		.WIDTH(2*BIT_WIDTH)
	)
	divider_b (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.dividend_in(dividend_b),
		.divisor_in(divisor),
		.data_valid_in(1'b1),
		.quotient_out(quotient_b),
		.remainder_out(),
		.data_valid_out(),
		.error_out(),
		.busy_out()
	);

	parameter NUM_MULTS = 7;
	logic signed [BIT_WIDTH-1:0] a_factor [0:NUM_MULTS-1];
	logic signed [BIT_WIDTH-1:0] b_factor [0:NUM_MULTS-1];
	logic signed [BIT_WIDTH-1:0] mult_res [0:NUM_MULTS-1];

	// for purposes of visualizing on gtkwave
	logic signed [BIT_WIDTH-1:0] afactor0;
	logic signed [BIT_WIDTH-1:0] bfactor0;
	assign afactor0 = a_factor[0];
	assign bfactor0 = b_factor[0];
	logic signed [BIT_WIDTH-1:0] mult_res_0;
	logic signed [BIT_WIDTH-1:0] mult_res_1;
	logic signed [BIT_WIDTH-1:0] mult_res_2;
	logic signed [BIT_WIDTH-1:0] mult_res_3;
	assign mult_res_0 = mult_res[0];
	assign mult_res_1 = mult_res[1];
	assign mult_res_2 = mult_res[2];
	assign mult_res_3 = mult_res[3];

	generate
		genvar f;
		for (f = 0; f < NUM_MULTS; ++f) begin
			//precision losing
			Multiply_re_extra_shift #(
				.WIDTH(BIT_WIDTH-8)
			)
			multiplier (
				.a_re(a_factor[f][BIT_WIDTH-1:8]),
				.b_re(b_factor[f][BIT_WIDTH-1:8]),
				.m_re(mult_res[f][BIT_WIDTH-1:8])
			);
			assign mult_res[f][7:0] = 0;
		end
	endgenerate

	// now assign our multipliers
	// 0 is stage 2 r(0) r(1)
	// 1 is stage 2 r(1) r(2)
	// 2 is stage 2 r(0) r(0)
	// 3 is stage 2 r(1) r(1)
	// 4 is stage 2 r(0) r(2)
	// 5 is stage 67 r(1) alpha_k
	// 6 is stage 67 r(2) beta_k
	assign a_factor[0] = pipeline[2][1];
	assign a_factor[1] = pipeline[2][2];
	assign a_factor[2] = pipeline[2][1];
	assign a_factor[3] = pipeline[2][2];
	assign a_factor[4] = pipeline[2][1];
	assign a_factor[5] = pipeline[69][2];
	assign a_factor[6] = pipeline[69][3];
	
	assign b_factor[0] = pipeline[2][2];
	assign b_factor[1] = pipeline[2][3];
	assign b_factor[2] = pipeline[2][1];
	assign b_factor[3] = pipeline[2][2];
	assign b_factor[4] = pipeline[2][3];
	assign b_factor[5] = alpha_k_pipeline;
	assign b_factor[6] = beta_k_pipeline;

	// we are guaranteed (empirically) that alpha_k, beta_k are between -2 and 2
	// given non-shifted values of num and denom
	// so we shift num by 32 for more precision, then submit to divider
	// then we expect only bottom 33 bits to be useful, we take the highest amount
	// we are also guaranteed denom is positive: r(0) is largest in absolute value compared to r(1), r(2)

	// we add another stage to the pipeline here since timing constraints

	logic signed [BIT_WIDTH-1:0] alpha_k_num;
	logic signed [BIT_WIDTH-1:0] beta_k_num;
	logic signed [BIT_WIDTH-1:0] alpha_k_num_pipeline;
	logic signed [BIT_WIDTH-1:0] beta_k_num_pipeline;
	logic signed [BIT_WIDTH-1:0] abs_alpha_k_num;
	logic signed [BIT_WIDTH-1:0] abs_beta_k_num;
	logic signed [BIT_WIDTH-1:0] denom;
	logic signed [BIT_WIDTH-1:0] denom_pipeline;
	logic signed [BIT_WIDTH-1:0] abs_alpha_k;
	logic signed [BIT_WIDTH-1:0] abs_beta_k;
	logic signed [BIT_WIDTH-1:0] alpha_k;
	logic signed [BIT_WIDTH-1:0] beta_k;
	logic signed [BIT_WIDTH-1:0] alpha_k_pipeline;
	logic signed [BIT_WIDTH-1:0] beta_k_pipeline;
	logic signed [BIT_WIDTH-1:0] emin_val;
	
	assign alpha_k_num = $signed(mult_res[0]) - $signed(mult_res[1]);
	assign beta_k_num = $signed(mult_res[4]) - $signed(mult_res[3]);
	assign denom = $signed(mult_res[2]) - $signed(mult_res[3]);

	always_ff @(posedge clk_in) begin
		alpha_k_num_pipeline <= alpha_k_num;
		beta_k_num_pipeline <= beta_k_num;
		denom_pipeline <= denom;
	end

	assign abs_alpha_k_num = (alpha_k_num_pipeline[31]) ? $signed(-$signed(alpha_k_num_pipeline)) : $signed(alpha_k_num_pipeline);
	assign abs_beta_k_num = (beta_k_num_pipeline[31]) ? $signed(-$signed(beta_k_num_pipeline)) : $signed(beta_k_num_pipeline);
	assign dividend_a = {1'b0, abs_alpha_k_num[30:0], 32'b0};
	assign dividend_b = {1'b0, abs_beta_k_num[30:0], 32'b0};
	assign divisor = (denom_pipeline) ? {32'b0, denom_pipeline} : 64'b1;

	// now we calculate emin_val
	// we need to be careful to not overflow on the arithmetic 
	assign abs_alpha_k = $signed({1'b0, quotient_a[32:2]});
	assign abs_beta_k = $signed({1'b0, quotient_b[32:2]}); 
	assign alpha_k = (sign_pipeline[68][0]) ? $signed(-abs_alpha_k) : $signed(abs_alpha_k);
	assign beta_k = (sign_pipeline[68][1]) ? $signed(-abs_beta_k) : $signed(abs_beta_k);
	always_ff @(posedge clk_in) begin
		alpha_k_pipeline <= alpha_k;
		beta_k_pipeline <= beta_k;
	end
	assign emin_val = ($signed(pipeline[69][1]) >>> 2) - $signed(mult_res[5]) - $signed(mult_res[6]);
	
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
			iter_done <= 1'b0;
		end else begin
			case (state)
				START: begin
					iter_done <= 1'b0;
					output_valid <= 1'b0;
					if (input_valid) begin
						i_reg <= i;
						T_req <= i;
						state <= REQ_I;
						delay <= 2'b10; // delay = 1 means 2 cycles later
					end //delay now +1 for proposed address to move in formant.sv
				end
				REQ_I: begin
					if (delay > 0) begin
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
						//T_req <= j_reg - 1; 
						T_req <= j_reg;
						j_reg <= j_reg + 1;
						pipeline[0][0] <= j_reg;
						for (integer entry = 1; entry <= 5; ++entry) begin
							pipeline[0][entry] <= 0;
						end
						valid_pipeline[0] <= 1'b1;
					end else begin
						valid_pipeline[0] <= 1'b0;
					end
					for (integer stage = 1; stage < NUM_STAGES; ++stage) begin
						if (stage != 2 && stage != 3) begin
							// pass on value
							// pipeline[stage] <= pipeline[stage-1]; doesn't work on cocotb
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= pipeline[stage-1][1];
							pipeline[stage][2] <= pipeline[stage-1][2];
							pipeline[stage][3] <= pipeline[stage-1][3];
							sign_pipeline[stage][0] <= sign_pipeline[stage-1][0];
							sign_pipeline[stage][1] <= sign_pipeline[stage-1][1];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end else if (stage == 2) begin
							// calculate values from T_resp which just came in
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= r0;
							pipeline[stage][2] <= r1;
							pipeline[stage][3] <= r2;
							sign_pipeline[stage][0] <= sign_pipeline[stage-1][0];
							sign_pipeline[stage][1] <= sign_pipeline[stage-1][1];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end else begin
							// stage == 3, calculate alpha_k num, beta_k num
							pipeline[stage][0] <= pipeline[stage-1][0];
							pipeline[stage][1] <= pipeline[stage-1][1];
							pipeline[stage][2] <= pipeline[stage-1][2];
							pipeline[stage][3] <= pipeline[stage-1][3];
							sign_pipeline[stage][0] <= alpha_k_num[31];
							sign_pipeline[stage][1] <= beta_k_num[31];
							valid_pipeline[stage] <= valid_pipeline[stage-1];
						end
					end
					if (valid_pipeline[NUM_STAGES-1]) begin
						j_out <= pipeline[NUM_STAGES-1][0];
						data_out <= emin_val;
						output_valid <= 1'b1;
						if (pipeline[NUM_STAGES-1][0] == i) begin // we output the last one
							state <= START;
							iter_done <= 1'b1;
						end
					end else begin
						output_valid <= 1'b0;
					end
				end
			endcase
		end
	end
	
endmodule 