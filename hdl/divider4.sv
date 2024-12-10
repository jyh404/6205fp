`timescale 1ns / 1ps
`default_nettype none

module divider4 #(parameter WIDTH = 64) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);

  logic [WIDTH-1:0] p[WIDTH-1:0]; // WIDTH stages
  logic [WIDTH-1:0] dividend [WIDTH-1:0];
  logic [WIDTH-1:0] divisor [WIDTH-1:0];
  logic data_valid [WIDTH-1:0];
  logic [WIDTH-2:0] bigzero;

  assign data_valid_out = data_valid[WIDTH-1];
  assign quotient_out = dividend[WIDTH-1];
  assign remainder_out = p[WIDTH-1];
  assign bigzero = 64'b0;

  always @(*) begin
    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in;
    if (data_valid_in)begin
      if ({WIDTH-1'b0,dividend_in[WIDTH-1]}>=divisor_in[WIDTH-1:0])begin
        p[0] = {WIDTH-1'b0,dividend_in[WIDTH-1]} - divisor_in[WIDTH-1:0];
        dividend[0] = {dividend_in[WIDTH-2:0],1'b1};
      end else begin
        p[0] = {WIDTH-1'b0,dividend_in[WIDTH-1]};
        dividend[0] = {dividend_in[WIDTH-2:0],1'b0};
      end
    end
    for (int i=2; i<BIT_WIDTH; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      if ({p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]}>=divisor[i-1][WIDTH-1:0])begin
        p[i] = {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]} - divisor[i-1][WIDTH-1:0];
        dividend[i] = {dividend[i-1][WIDTH-2:0],1'b1};
      end else begin
        p[i] = {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]};
        dividend[i] = {dividend[i-1][WIDTH-2:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
    for (int i=1; i<BIT_WIDTH; i=i+2)begin
      data_valid[i] <= data_valid[i-1];
      if ({p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]}>=divisor[i-1][WIDTH-1:0])begin
        p[i] <= {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]} - divisor[i-1][WIDTH-1:0];
        dividend[i] <= {dividend[i-1][WIDTH-2:0],1'b1};
      end else begin
        p[i] <= {p[i-1][WIDTH-2:0],dividend[i-1][WIDTH-1]};
        dividend[i] <= {dividend[i-1][WIDTH-2:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
