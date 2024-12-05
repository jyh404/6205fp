`default_nettype none
module evt_counter #(MAXIMUM_COUNT = 16'hffff)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          evt_in,
    output logic[15:0]  count_out
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      count_out <= 16'b0;
    end else begin
      /* your code here */
      count_out <= (count_out + evt_in == MAXIMUM_COUNT)?0:count_out + evt_in;
    end
  end
endmodule
`default_nettype wire