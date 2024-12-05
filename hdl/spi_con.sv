module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 100
      )
      (input wire   clk_in, //system clock (100 MHz)
       input wire   rst_in, //reset in signal
       input wire   [DATA_WIDTH-1:0] data_in, //data to send
       input wire   trigger_in, //start a transaction
       output logic [DATA_WIDTH-1:0] data_out, //data received!
       output logic data_valid_out, //high when output data is present.
 
       output logic chip_data_out, //(COPI)
       input wire   chip_data_in, //(CIPO)
       output logic chip_clk_out, //(DCLK)
       output logic chip_sel_out // (CS)
      );
  //your code here
  parameter HALF_COUNTER = int'(DATA_CLK_PERIOD/2);
  parameter NEW_TOTAL_COUNTER = HALF_COUNTER*2;
  parameter COUNTER_SIZE = $clog2(NEW_TOTAL_COUNTER);
  parameter INDEX_COUNTER_SIZE = $clog2(DATA_WIDTH);
  //counter resets every period, is 1 when above half counter.
  
  logic [DATA_WIDTH-1:0] data_to_go = 0;
  logic [COUNTER_SIZE-1:0] time_counter = 0;
  logic [INDEX_COUNTER_SIZE-1:0] index_counter = DATA_WIDTH-1;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
	  //resetting everything
	  
	  data_out <= 0;
	  data_valid_out <= 0;
	  chip_data_out <= 0;
	  chip_clk_out <= 0;
	  chip_sel_out <= 1;
	  data_to_go <= 0;
	  time_counter <= 0;
	  index_counter <= DATA_WIDTH-1;	  end 
	
	else if (trigger_in && chip_sel_out) begin 
	  //only accept input if not transmitting 
	  //presets for accepting input
	  
	  chip_sel_out <= 0; // inform start of transmission
	  chip_data_out <= data_in[DATA_WIDTH-1]; //output MSB
	  chip_clk_out <= 0;
	  data_to_go <= (data_in<<1); //first MSB is gone
	  time_counter <= 0;
	  index_counter <= DATA_WIDTH-1;
	  end 
	
	else if (~ chip_sel_out)
	  // begin transmission
	
	  if (time_counter < HALF_COUNTER) begin //clock low
		if (time_counter == HALF_COUNTER-1) begin //rising edge
		  data_out <= (data_out<<1) | chip_data_in; //read
		  chip_clk_out <= 1;
		  time_counter <= time_counter + 1;
		end else begin 
		  chip_clk_out <= 0;
		  time_counter <= time_counter + 1;
		end
		
	  
	  end else begin // clock high
	    if (time_counter == NEW_TOTAL_COUNTER-1) begin //falling edge
	      if (index_counter == 0) begin
			chip_sel_out <= 1; // inform end of transmission
			data_valid_out <= 1; // flare that data is valid
			time_counter <= 0; // reset timer
			chip_clk_out <= 0;
			end
			
	      else begin // continue to next index
			chip_data_out <= data_to_go[DATA_WIDTH-1]; // output (old) MSB
			data_to_go <= (data_to_go << 1); // shift MSB down
		    time_counter <= 0;
			chip_clk_out <= 0;
			index_counter <= index_counter - 1;
            end
		  
	    end else begin
	      time_counter <= time_counter + 1;
		  chip_clk_out <= 1;
		end
	  end
	  
	else if (data_valid_out) begin
	    data_valid_out <= 0; // stop flare
		chip_clk_out <= 0;
		end
	end
  
endmodule