`timescale 1ns / 1ps
`default_nettype none

module divider4 #(parameter WIDTH = 32) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);

  logic [31:0] p[31:0]; //32 stages
  logic [31:0] dividend [31:0];
  logic [31:0] divisor [31:0];
  logic data_valid [31:0];

  assign data_valid_out = data_valid[31];
  assign quotient_out = dividend[31];
  assign remainder_out = p[31];

  always @(*) begin
    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in;
    if (data_valid_in)begin
      if ({31'b0,dividend_in[31]}>=divisor_in[31:0])begin
        p[0] = {31'b0,dividend_in[31]} - divisor_in[31:0];
        dividend[0] = {dividend_in[30:0],1'b1};
      end else begin
        p[0] = {31'b0,dividend_in[31]};
        dividend[0] = {dividend_in[30:0],1'b0};
      end
    end
    for (int i=2; i<32; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      if ({p[i-1][30:0],dividend[i-1][31]}>=divisor[i-1][31:0])begin
        p[i] = {p[i-1][30:0],dividend[i-1][31]} - divisor[i-1][31:0];
        dividend[i] = {dividend[i-1][30:0],1'b1};
      end else begin
        p[i] = {p[i-1][30:0],dividend[i-1][31]};
        dividend[i] = {dividend[i-1][30:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
    for (int i=1; i<32; i=i+2)begin
      data_valid[i] <= data_valid[i-1];
      if ({p[i-1][30:0],dividend[i-1][31]}>=divisor[i-1][31:0])begin
        p[i] <= {p[i-1][30:0],dividend[i-1][31]} - divisor[i-1][31:0];
        dividend[i] <= {dividend[i-1][30:0],1'b1};
      end else begin
        p[i] <= {p[i-1][30:0],dividend[i-1][31]};
        dividend[i] <= {dividend[i-1][30:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
