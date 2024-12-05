module sqrt #(
	parameter BIT_WIDTH=16
)(
	input clk_in,
	input valid_in,
	input [BIT_WIDTH-1:0] sqrt_in,
	output [BIT_WIDTH-1:0] sqrt_out,
	output valid_out
);

localparam LAYERS = BIT_WIDTH/2+1;
logic valid_buffer [0:LAYERS];
logic [BIT_WIDTH-1:0] sqrt_in_buffer [0:LAYERS];
logic [BIT_WIDTH-1:0] sqrt_out_buffer [0:LAYERS];
logic [BIT_WIDTH-1:0] sqrt_out_sq_buffer [0:LAYERS];

always_ff @(posedge clk_in) begin
	valid_buffer[0] <= valid_in;
	sqrt_in_buffer[0] <= sqrt_in;
	sqrt_out_buffer[0] <= 0;
	sqrt_out_sq_buffer[0] <= 0;
	for (int i=1; i<LAYERS; i++) begin
		sqrt_in_buffer[i] <= sqrt_in_buffer[i-1];
		// sqrt_out_buffer[i] <= sqrt_out_buffer[i-1] + 
		//	((sqrt_in_buffer[i-1]-(sqrt_out_buffer[i-1]*sqrt_out_buffer[i-1]))
		//	>>(1+$clog2(sqrt_out_buffer[i-1])));
		sqrt_out_buffer[i] <= ((sqrt_out_sq_buffer[i-1]+(sqrt_out_buffer[i-1]<<(LAYERS-i))+(1<<((LAYERS-i-1)<<1))) <= sqrt_in_buffer[i-1])
			? sqrt_out_buffer[i-1]+(1<<(LAYERS-i-1)) : sqrt_out_buffer[i-1];
		sqrt_out_sq_buffer[i] <= ((sqrt_out_sq_buffer[i-1]+(sqrt_out_buffer[i-1]<<(LAYERS-i))+(1<<((LAYERS-i-1)<<1))) <= sqrt_in_buffer[i-1])
			? (sqrt_out_sq_buffer[i-1]+(sqrt_out_buffer[i-1]<<(LAYERS-i))+(1<<((LAYERS-i-1)<<1))) : sqrt_out_sq_buffer[i-1];	
		valid_buffer[i] <= valid_buffer[i-1];
	end
end

assign sqrt_out = sqrt_out_buffer[LAYERS-1];
assign valid_out = valid_buffer[LAYERS-1];

endmodule