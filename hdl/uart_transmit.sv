`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );
				  
	parameter PERIOD = int'(INPUT_CLOCK_FREQ/BAUD_RATE);
	parameter COUNTER_WIDTH = $clog2(PERIOD);
	
	logic [COUNTER_WIDTH:0] counter = 0; 
	logic [3:0] bytes_left = 9;
	logic [8:0] data_out;

	always_ff @(posedge clk_in) begin
		if (rst_in) begin //reset values
			busy_out <= 0;
			tx_wire_out <= 1;
			counter <= 0;
			bytes_left <= 9;
		end else if (busy_out==0 && trigger_in) begin //start transmission
			busy_out <= 1;
			counter <= 0;
			tx_wire_out <= 0; //start bit
			data_out <= {1'b1, data_byte_in}; //end bit is last
			bytes_left <= 9;
		end else if ((busy_out==1) && (counter < PERIOD)) begin
			counter <= counter + 1;
		end else if ((busy_out==1) && (counter == PERIOD)) begin
			counter <= 0;	
			if (bytes_left==0) begin
				tx_wire_out <= 1;
				busy_out <= 0;
			end else begin
				bytes_left <= bytes_left-1;
				tx_wire_out <= data_out[0];
				data_out <= (data_out >> 1);
			end
		end else begin //no transmission just chillin'
			busy_out <= 0;
			tx_wire_out <= 1;
		end
	end
endmodule

`default_nettype wire