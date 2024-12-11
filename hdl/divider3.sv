`timescale 1ns / 1ps
`default_nettype none

module divider3 #(parameter WIDTH = 64) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);

  logic [63:0] p[63:0]; // 64 stages
  logic [63:0] dividend [63:0];
  logic [63:0] divisor [63:0];
  logic data_valid [63:0];

  assign data_valid_out = data_valid[63];
  assign quotient_out = dividend[63];
  assign remainder_out = p[63];

  always_ff @(posedge clk_in)begin
    data_valid[0] <= data_valid_in;
    if (data_valid_in)begin
      divisor[0] <= divisor_in;
      if ({63'b0,dividend_in[63]}>=divisor_in[63:0])begin
        p[0] <= {63'b0,dividend_in[63]} - divisor_in[63:0];
        dividend[0] <= {dividend_in[62:0],1'b1};
      end else begin
        p[0] <= {63'b0,dividend_in[63]};
        dividend[0] <= {dividend_in[62:0],1'b0};
      end
    end
    for (int i=1; i<64; i=i+1)begin
      data_valid[i] <= data_valid[i-1];
      if ({p[i-1][62:0],dividend[i-1][63]}>=divisor[i-1][63:0])begin
        p[i] <= {p[i-1][62:0],dividend[i-1][63]} - divisor[i-1][63:0];
        dividend[i] <= {dividend[i-1][62:0],1'b1};
      end else begin
        p[i] <= {p[i-1][62:0],dividend[i-1][63]};
        dividend[i] <= {dividend[i-1][62:0],1'b0};
      end
      divisor[i] <= divisor[i-1];
    end
  end
endmodule

`default_nettype wire
