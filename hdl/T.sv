module T #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter NU_VALUES = 3)
(
	input wire clk_in,
	input wire rst_in,
	input wire fft_valid, //valid for 160 cycles
	input wire [BIT_WIDTH-1:0] fft_data, //take the 160 cycles where its valid
    output logic [BIT_WIDTH-1:0] output_written_0,
    output logic [BIT_WIDTH-1:0] output_written_1,
    output logic [BIT_WIDTH-1:0] output_written_2,
	output logic output_valid,
	output logic [$clog2(I)-1:0] output_address
);
	// receives fft data sequentially (I = 160 samples)
	// computes T(0, i) and outputs them sequentially to be stored in BRAM

	localparam SCALE = 4; //we divide by 4 here to not overflow.

	logic [BIT_WIDTH-1:0] running_sums [0:NU_VALUES-1]; //running total
	logic [BIT_WIDTH-1:0] partial_sums [0:NU_VALUES-1]; //the thing(s) to add to the running total
	logic [BIT_WIDTH-1:0] cosine_value [0:NU_VALUES-1]; //the cosine value to multiply to fft_data
	logic [8:0] counter_indx; //the tracker of which value we are on (next)
	logic [8:0] counter_indx_buffer [0:1];
	logic [BIT_WIDTH-1:0] fft_data_buffer; //for reasons.
	logic fft_valid_buffer [0:1];
	//assign cosine_value[0] = 1<<(BIT_WIDTH-8);
	
	//Counter and buffers
	always_ff @(posedge clk_in) begin
		fft_data_buffer <= fft_data;
		if (fft_valid) begin
			counter_indx <= counter_indx + 1;
		end else begin
			counter_indx <= 0;
		end
	end
	
	//1 clock cycle
	CosineLookup for_multiply(
		.clock(clk_in),
		.addr1(counter_indx),
		.addr2(counter_indx<<1),
		.res1(cosine_value[1]),
		.res2(cosine_value[2])
	);
	
	logic [2*BIT_WIDTH-1:0] temp_partial_0;
	assign temp_partial_0 = (fft_data_buffer*(32'h00cccccc<<SCALE));

	//1 clock cycle for time safety.
	logic [BIT_WIDTH-1:0] temp_partial_1;
	Multiply_re #(.WIDTH(BIT_WIDTH-8)) cos_mult_1(
		.a_re(fft_data_buffer[BIT_WIDTH-1-SCALE:8-SCALE]),
		.b_re(cosine_value[1][BIT_WIDTH-1:8]),
		.m_re(temp_partial_1[BIT_WIDTH-1:8])
	);
	assign temp_partial_1[7:0] = 0;
	
	logic [BIT_WIDTH-1:0] temp_partial_2;
	Multiply_re #(.WIDTH(BIT_WIDTH)) cos_mult_2(
		.a_re(fft_data_buffer[BIT_WIDTH-1-SCALE:8-SCALE]),
		.b_re(cosine_value[2][BIT_WIDTH-1:8]),
		.m_re(temp_partial_2[BIT_WIDTH-1:8])
	);
	assign temp_partial_2[7:0] = 0;
	
	always_ff @(posedge clk_in) begin
		partial_sums[0] <= temp_partial_0[62:31];
		partial_sums[1] <= temp_partial_1;
		partial_sums[2] <= temp_partial_2;
		fft_valid_buffer[0] <= fft_valid;
		fft_valid_buffer[1] <= fft_valid_buffer[0]; 
		counter_indx_buffer[0] <= counter_indx;
		counter_indx_buffer[1] <= counter_indx_buffer[0];
		// All of these should be realigned.
		
		output_written_0 <= (fft_valid_buffer[1] == 1'b1) ? running_sums[0] + partial_sums[0] : 0;
		output_written_1 <= (fft_valid_buffer[1] == 1'b1) ? running_sums[1] + partial_sums[1] : 0;
		output_written_2 <= (fft_valid_buffer[1] == 1'b1) ? running_sums[2] + partial_sums[2] : 0;
		output_address <= counter_indx_buffer[1];
		output_valid <= fft_valid_buffer[1];
		
		for (int i=0; i<NU_VALUES; i++) begin
			running_sums[i] <= (fft_valid_buffer[1] == 1'b1) ? running_sums[i] + partial_sums[i] : 0;
		end
		
	end
	
/*
	generate
		genvar i;
		for (i = 0; i < NU_VALUES; ++i) begin
			Multiply_re #(
				.WIDTH = BIT_WIDTH
			)
			cos_multiplier
			(
				.a_re(),
				.b_re(),
				.m_re()
			);
		end
	endgenerate
*/
endmodule 