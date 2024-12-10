// Directly find the gap that's closest
// Then interpolate between the 2
// Answer is scaled to 5000 automatically

// START: DUMB COMMENTS
// A binary search algo for arccos
// Specialized to 32 bit input and 32 bit output
// Outputs as 7FFF = pi and 8000 = -pi
// This is kinda useful for later.

// Approx 32 cycle delay probably
// END: DUMB COMMENTS

module acos (
	input wire clk_in,
	input wire [31:0] acos_in,
	input wire valid_in,
	output logic [31:0] acos_out
);

logic [31:0] acos_vals [0:256]; //initialized below

//find the bounds of acos(in)
logic [23:0] acos_min, acos_max;
always_ff @(posedge clk_in) begin
	acos_min <= acos_vals[acos_in[31:24]];
	acos_max <= acos_vals[acos_in[31:24]+1];
end

//linear interpolate a better value for acos
//takes acos_in[23:0] and 0xFFF-acos_in[23:0] to scale
//then add it up

logic [23:0] min_scale;
logic [23:0] max_scale;

assign min_scale = ~acos_in[23:0];
assign max_scale = acos_in[23:0];

Multiply_re #(
	.WIDTH(24)
) mult_min (
	.a_re(),
	.b_re(),
	.m_re()
);



endmodule