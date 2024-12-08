module log2bad (
	input  wire clk_in, 
	input  wire [31:0] log_in,
	output logic [7:0]  log_out
);
	//Combinatorial... hopefully
	//The lack of constant select is such a pain.

	//This is the bad way to do log2
	//5 MSB are just the location of the first one
	//3 LSB are the next three digits 
	//the output is unsigned.
	//0s output 0 (so does 1).
	
	logic [34:0] extend_in;
	logic [31:0] shifted_in_4;
	logic [31:0] shifted_in_3;
	logic [31:0] shifted_in_2;
	logic [31:0] shifted_in_1;
	logic index_4;
	logic index_3;
	logic index_2;
	logic index_1;
	logic index_0;
	logic [4:0] index;
	
	always_comb begin
		index_4 = ((log_in & 32'b1111_1111_1111_1111_0000_0000_0000_0000) != 0)       ? 1'b1 : 1'b0;
		shifted_in_4 = (index_4 == 1'b1) ? log_in >> 16 : log_in;
		index_3 = ((shifted_in_4 & 32'b1111_1111_0000_0000_1111_1111_0000_0000) != 0) ? 1'b1 : 1'b0;
		shifted_in_3 = (index_3 == 1'b1) ? shifted_in_4 >> 8 : shifted_in_4;
		index_2 = ((shifted_in_3 & 32'b1111_0000_1111_0000_1111_0000_1111_0000) != 0) ? 1'b1 : 1'b0;
		shifted_in_2 = (index_2 == 1'b1) ? shifted_in_3 >> 4 : shifted_in_3;
		index_1 = ((shifted_in_2 & 32'b1100_1100_1100_1100_1100_1100_1100_1100) != 0) ? 1'b1 : 1'b0;
		shifted_in_1 = (index_1 == 1'b1) ? shifted_in_2 >> 2 : shifted_in_2;
		index_0 = ((shifted_in_1 & 32'b1010_1010_1010_1010_1010_1010_1010_1010) != 0) ? 1'b1 : 1'b0;
		index = {index_4,index_3,index_2,index_1,index_0};
		extend_in = {log_in,3'b000};
	end

	always_ff @(posedge clk_in) begin
		log_out <= {index, extend_in[index +: 3]};
		//log_out <= {index,3'b000};
	end


/*	
	assign possible_log_out[0] = {0,extend_in[0 +: 2]};
	assign possible_log_out[1] = {1,extend_in[1 +: 2]};
	assign possible_log_out[2] = {2,extend_in[2 +: 2]};
	assign possible_log_out[3] = {3,extend_in[3 +: 2]};
	assign possible_log_out[4] = {4,extend_in[4 +: 2]};
	assign possible_log_out[5] = {5,extend_in[5 +: 2]};
	assign possible_log_out[6] = {6,extend_in[6 +: 2]};
	assign possible_log_out[7] = {7,extend_in[7 +: 2]};	
	assign possible_log_out[8] = {8,extend_in[8 +: 2]};
	assign possible_log_out[9] = {9,extend_in[9 +: 2]};
	assign possible_log_out[10] = {10,extend_in[10 +: 2]};
	assign possible_log_out[11] = {11,extend_in[11 +: 2]};
	assign possible_log_out[12] = {12,extend_in[12 +: 2]};
	assign possible_log_out[13] = {13,extend_in[13 +: 2]};
	assign possible_log_out[14] = {14,extend_in[14 +: 2]};
	assign possible_log_out[15] = {15,extend_in[15 +: 2]};
	assign possible_log_out[16] = {16,extend_in[16 +: 2]};
	assign possible_log_out[17] = {17,extend_in[17 +: 2]};
	assign possible_log_out[18] = {18,extend_in[18 +: 2]};
	assign possible_log_out[19] = {19,extend_in[19 +: 2]};
	assign possible_log_out[20] = {20,extend_in[20 +: 2]};
	assign possible_log_out[21] = {21,extend_in[21 +: 2]};
	assign possible_log_out[22] = {22,extend_in[22 +: 2]};
	assign possible_log_out[23] = {23,extend_in[23 +: 2]};
	assign possible_log_out[24] = {24,extend_in[24 +: 2]};
	assign possible_log_out[25] = {25,extend_in[25 +: 2]};
	assign possible_log_out[26] = {26,extend_in[26 +: 2]};
	assign possible_log_out[27] = {27,extend_in[27 +: 2]};
	assign possible_log_out[28] = {28,extend_in[28 +: 2]};
	assign possible_log_out[29] = {29,extend_in[29 +: 2]};
	assign possible_log_out[30] = {30,extend_in[30 +: 2]};
	assign possible_log_out[31] = {31,extend_in[31 +: 2]};
	
	always_ff begin
	if (log_in[31:16] == 0) begin
		if (log_in[15:8] == 0) begin
			if (log_in[7:4] == 0) begin
				if (log_in[3:2] == 0) begin
					if (log_in[1] == 0) begin
						assign log_out = possible_log_out[0];
					end else 
						assign log_out = possible_log_out[1];
				end else 
					if (log_in[3] == 0) begin
						assign log_out = possible_log_out[2];
					end else 
						assign log_out = possible_log_out[3];
			end else 
				if (log_in[7:6] == 0) begin
					if (log_in[5] == 0) begin
						assign log_out = possible_log_out[4];
					end else 
						assign log_out = possible_log_out[5];
				end else 
					if (log_in[7] == 0) begin
						assign log_out = possible_log_out[6];
					end else 
						assign log_out = possible_log_out[7];
		end else 
			if (log_in[15:12] == 0) begin
				if (log_in[11:10] == 0) begin
					if (log_in[9] == 0) begin
						assign log_out = possible_log_out[8];
					end else 
						assign log_out = possible_log_out[9];
				end else 
					if (log_in[11] == 0) begin
						assign log_out = possible_log_out[10];
					end else 
						assign log_out = possible_log_out[11];
			end else 
				if (log_in[15:14] == 0) begin
					if (log_in[13] == 0) begin
						assign log_out = possible_log_out[12];
					end else 
						assign log_out = possible_log_out[13];
				end else 
					if (log_in[15] == 0) begin
						assign log_out = possible_log_out[14];
					end else 
						assign log_out = possible_log_out[15];
	end else 
		if (log_in[31:24] == 0) begin
			if (log_in[23:20] == 0) begin
				if (log_in[19:18] == 0) begin
					if (log_in[17] == 0) begin
						assign log_out = possible_log_out[16];
					end else 
						assign log_out = possible_log_out[17];
				end else 
					if (log_in[19] == 0) begin
						assign log_out = possible_log_out[18];
					end else 
						assign log_out = possible_log_out[19];
			end else 
				if (log_in[23:22] == 0) begin
					if (log_in[21] == 0) begin
						assign log_out = possible_log_out[20];
					end else 
						assign log_out = possible_log_out[21];
				end else 
					if (log_in[23] == 0) begin
						assign log_out = possible_log_out[22];
					end else 
						assign log_out = possible_log_out[23];
		end else 
			if (log_in[31:28] == 0) begin
				if (log_in[27:26] == 0) begin
					if (log_in[25] == 0) begin
						assign log_out = possible_log_out[24];
					end else 
						assign log_out = possible_log_out[25];
				end else 
					if (log_in[27] == 0) begin
						assign log_out = possible_log_out[26];
					end else 
						assign log_out = possible_log_out[27];
			end else 
				if (log_in[31:30] == 0) begin
					if (log_in[29] == 0) begin
						assign log_out = possible_log_out[28];
					end else 
						assign log_out = possible_log_out[29];
				end else 
					if (log_in[31] == 0) begin
						assign log_out = possible_log_out[30];
					end else 
						assign log_out = possible_log_out[31];	
	end
*/
endmodule
