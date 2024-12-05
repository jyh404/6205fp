`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );

   // TODO: module to read UART rx wire
	parameter HALF_PERIOD = int'(INPUT_CLOCK_FREQ/BAUD_RATE/2);
	parameter PERIOD = 2*HALF_PERIOD;
	parameter COUNTER_WIDTH = $clog2(PERIOD);

	logic [COUNTER_WIDTH:0] counter = 0; 
	logic [3:0] bytes_left = 9;
	logic good_data = 1; //innocent until proven guilty
	logic receiving = 0;

	always_ff @(posedge clk_in) begin
		if ((rst_in == 1) || (good_data == 0) || (new_data_out == 1)) begin //idle or purge bad data
			bytes_left <= 9;
			new_data_out <= 0;
			data_byte_out <= 0;
			counter <= 0;
			good_data <= 1;
			receiving <= 0;
		end else if ((receiving == 0) && (rx_wire_in == 0)) begin //receive begins
			counter <= 0;
			receiving <= 1;
		end else if ((receiving == 1) && (counter == HALF_PERIOD)) begin //take a bit
			counter <= counter+1;
			if (bytes_left==9 && rx_wire_in==1) good_data <= 0;
			else if (bytes_left == 0 & rx_wire_in==0) good_data <= 0;
			else if (bytes_left == 0) begin 
				new_data_out <= 1; //flare once
			end else data_byte_out <= {rx_wire_in,data_byte_out[7:1]};
		end else if ((receiving == 1) && (counter == PERIOD)) begin
			counter <= 0;
			bytes_left <= bytes_left-1;
		end	else if (receiving == 1) counter <= counter+1;
	end
	
endmodule // uart_receive

`default_nettype wire
