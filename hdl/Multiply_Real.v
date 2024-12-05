//----------------------------------------------------------------------
//  Multiply: Complex Multiplier
//  Modified to only take real inputs and give real outputs.
//----------------------------------------------------------------------
module Multiply_re #(
    parameter   WIDTH = 16
)(
    input   signed  [WIDTH-1:0] a_re,
    input   signed  [WIDTH-1:0] b_re,
    output  signed  [WIDTH-1:0] m_re
);

wire signed [WIDTH*2-1:0]   arbr, aibr;
wire signed [WIDTH-1:0]     sc_arbr, sc_aibr;

//  Signed Multiplication
assign  arbr = a_re * b_re;

//  Scaling
assign  sc_arbr = arbr >>> (WIDTH-1);

//  Sub/Add
//  These sub/add may overflow if unnormalized data is input.
assign  m_re = sc_arbr;

endmodule
