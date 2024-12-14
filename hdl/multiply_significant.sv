// Multiply
// takes 32 bit and returns 32
// but it takes some liberties to return a more precise.

module Multiply32_comp (
	input wire [31:0] a_in,
	input wire [31:0] b_in,
	output logic [31:0] m_out
);

logic signed [23:0] a_comp, b_comp;
logic [1:0] shift;
logic signed [47:0] prod;

always_comb begin
	if ((a_in[31:23] == 9'b0) || (a_in[31:23] == ~9'b0)) begin 
		a_comp =  a_in[23:0];
		shift[0] = 1;
	end else begin
		a_comp = a_in[31:8];
		shift[0] = 0;
	end
	if ((b_in[31:23] == 9'b0) || (b_in[31:23] == ~9'b0)) begin 
		b_comp =  b_in[23:0];
		shift[1] = 1;
	end else begin
		b_comp = b_in[31:8];
		shift[1] = 0;
	end
	prod = $signed(a_comp)*$signed(b_comp);
	case(shift)
		2'b00 : m_out = $signed(prod[47:16]);
		2'b01 : m_out = $signed(prod[47:16]) >>> 8;
		2'b10 : m_out = $signed(prod[47:16]) >>> 8;
		2'b11 : m_out = $signed(prod[47:16]) >>> 16;
	endcase
end

endmodule