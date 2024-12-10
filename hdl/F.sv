module f #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter FORMANTS = 5
)(	input wire clk_in,
	input wire rst_in,
	input wire begin_iter,
	input wire [$clog2(I)-1:0] i, // decide when to begin processing i, needs Emin to finish
	input wire [BIT_WIDTH-1:0] e_prev, // E(j+1,i)
	input wire [BIT_WIDTH-1:0] f_prev, // F(k-1,j)
	input wire [BIT_WIDTH-1:0] f_old, // old F(k,i)
	output logic [$clog2(FORMANTS)-1:0] k_req,
	output logic [$clog2(I)-1:0] j_req,
	output logic [$clog2(FORMANTS)-1:0] k_write,
	output logic [BIT_WIDTH-1:0] f_data,
	output logic [BIT_WIDTH-1:0] b_data,
    output logic output_valid, // only on when f_data, b_data is correct
	output logic iter_done // pulse when iteration for i is done
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
	// don't forget delay on e_prev, f_prev, f_old is 2 cycles after k_req
	// somehow PIPELINE
	
	typedef enum {START, REQ_F, CALC} poss_state;
	poss_state state;

	logic [$clog2(I)-1:0] i_reg;
	logic [BIT_WIDTH-1:0] old_f;
	logic [1:0] delay;

	parameter NUM_STAGES = 4;
	signed logic [$clog2(I):0] j_pipeline [0:NUM_STAGES-1];
	logic [$clog(FORMANTS)-1:0] k_pipeline [0:NUM_STAGES-1];
	// 0: send in k, j
	// 1:
	// 2: receive F(k-1,j), Emin(j+1,i), write F(k,i), B(k,i)
	// 3: keep k, j to do analysis later

	logic valid_pipeline [0:NUM_STAGES-1];
	// keep track of when pipeline is still calculating

	assign j_req = j_pipeline[0];

	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			state <= START;
			valid_pipeline[0] <= 1'b0;
			output_valid <= 1'b0;
			iter_done <= 1'b0;
		end else begin
			case (state)
				START: begin
					output_valid <= 1'b0;
					if (begin_iter) begin
						i_reg <= i;
						state <= REQ_F;
						k_req <= 1;
						delay <= 2'b10;
					end
				end
				REQ_F: begin
					if (delay) begin
						delay <= delay - 1;
					end else begin
						old_f <= f_old;
						state <= CALC;
						j_pipeline[0] <= k_req - 2;
						k_pipeline[0] <= k_req;
						valid_pipeline[0] <= 1'b1;
						b_data <= 0;
					end
				end
				CALC: begin
					if (j_pipeline[0] == i-1) begin
						valid_pipeline[0] <= 1'b0;
					end else begin
						j_pipeline[0] <= j_pipeline[0] + 1;
						valid_pipeline[0] <= 1'b1;
					end
					for (integer stage = 1; stage < NUM_STAGES; ++stage) begin
						j_pipeline[stage] <= j_pipeline[stage-1];
						k_pipeline[stage] <= k_pipeline[stage-1];
						valid_pipeline[stage] <= valid_pipeline[stage-1];
					end
					if (valid_pipeline[2]) begin
						if (j_pipeline[2] == -1 && k_pipeline[2] == 1) begin
							// case of F(0, -1)
							if (e_prev < old_f) begin
								old_f <= e_prev;
								b_data <= j_pipeline[2];
							end
						end else if (k_pipeline[2] > 1 && e_prev + f_prev < old_f) begin
							old_f <= e_prev + f_prev;
							b_data <= j_pipeline[2];
						end
					end
					if (j_pipeline[3] == i-1 && valid_pipeline[3]) begin
						// reached the end
						k_write <= k_req;
						f_data <= old_f;
						output_valid <= 1'b1;
						if (k_req == i+1 || k_req == FORMANTS) begin
							state <= START;
						end else begin
							k_req <= k_req + 1;
							delay <= 2'b10;
							state <= REQ_F;
						end
					end else begin
						output_valid <= 1'b0;
					end
				end
			endcase
		end
	end
	
endmodule 