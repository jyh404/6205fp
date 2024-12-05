`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

//STOLEN FROM LAB3

module top_level
  (
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic [15:0] led, //16 green output LEDs (located right above switches)
   output logic [2:0]  rgb0, //RGB channels of RGB LED0
   output logic [2:0]  rgb1, //RGB channels of RGB LED1
   output logic        spkl, spkr, // left and right channels of line out port
   input wire          cipo, // SPI controller-in peripheral-out
   output logic        copi, dclk, cs, // SPI controller output signals
	 input wire 				 uart_rxd, // UART computer-FPGA
	 output logic 			 uart_txd // UART FPGA-computer
   );

   //shut up those rgb LEDs for now (active high):
   assign rgb1 = 0; //set to 0.
   assign rgb0 = 0; //set to 0.

   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];

   // 16kHz trigger using a week 1 counter!
   // In effect most of our computations finish within one trigger
   // This gives a ordering for when things happen.
   localparam CYCLES_PER_TRIGGER = 6250; // MUST CHANGE

   logic [31:0]        trigger_count;
   logic               spi_trigger;

   counter counter_16khz_trigger
     (.clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .period_in(CYCLES_PER_TRIGGER),
      .count_out(trigger_count));

   // Signals 1 every time a data is sampled.
   assign spi_trigger = (trigger_count == CYCLES_PER_TRIGGER-1);

   // SPI Controller on our ADC

   // TODO: bring in the instantiation of your SPI controller from the end of last week's lab!
   // you updated some parameter values based on the MCP3008's specification, bring those updates here.
   // see: "The Whole Thing", last checkoff from Week 02
   parameter ADC_DATA_WIDTH = 17; //MUST CHANGE
   parameter ADC_DATA_CLK_PERIOD = 50; //MUST CHANGE

   // SPI interface controls
   logic [ADC_DATA_WIDTH-1:0] spi_write_data;
   logic [ADC_DATA_WIDTH-1:0] spi_read_data; //The data!
   logic                      spi_read_data_valid;

   // Since now we're only ever reading from one channel, spi_write_data can stay constant.
   // TODO: Assign it a proper value for accessing CH7!
   assign spi_write_data = 17'b11111_0000_0000_0000; // MUST CHANGE

   spi_con
  #(   .DATA_WIDTH(ADC_DATA_WIDTH),
       .DATA_CLK_PERIOD(ADC_DATA_CLK_PERIOD)
   )my_spi_con
   ( .clk_in(clk_100mhz),
     .rst_in(sys_rst),
     .data_in(spi_write_data),
     .trigger_in(spi_trigger),
     .data_out(spi_read_data),
     .data_valid_out(spi_read_data_valid), //high when output data is present.
     .chip_data_out(copi), //(serial dout preferably)
     .chip_data_in(cipo), //(serial din preferably)
     .chip_clk_out(dclk),
     .chip_sel_out(cs)
    );

	parameter SAMPLE_BITS = 32; //Make everything 32 bits...?
	// Down-scaling to 24 because bad things are happening.
	
   logic signed [SAMPLE_BITS-1:0]                audio_sample;
   
   // TODO: store your audio sample from the SPI controller, only when the data is valid!
   // See below
 
   
   //Offcom, pre-emph
   logic signed [SAMPLE_BITS-1:0] prev_audio_sample; //s in(n-1)
   logic signed [SAMPLE_BITS-1:0] audio_of; //s out(n)
   logic signed [SAMPLE_BITS-1:0] audio_of_buffer;
   logic signed [SAMPLE_BITS-1:0] correction;
   logic signed [SAMPLE_BITS-1:0] audio_pc;
   logic signed [SAMPLE_BITS+1:0] audio_of_partial;
   //logic signed [15:0] random_bits; //what's more random than atmospheric noise??
   
   //assign correction = (random_bits[15:12] == 4'b0000) ? (audio_of>>6) : 0; //s out(n-1)*0.001
   assign correction = audio_of>>>10;
   //attaining 1/1000 by assuming audio_sample last 3 bits is lowkey random
   //assign audio_of_partial = {2'b00,audio_sample} - {2'b00,prev_audio_sample} 
	    //+ {2'b00,prev_audio_of} - {2'b00,correction};
    assign audio_of_partial = $signed(audio_sample) + $signed(audio_of) 
		- $signed(prev_audio_sample) - $signed(correction);


    // for fft
	// sampling at 16kHz so it takes 6250 clock cycles to send each one
	// 25ms is 400 samples, the overlap is 10ms which is 160 samples
	parameter WINDOW_SIZE = 400;
	parameter WINDOW_OVERLAP = 160;
	
	logic signed [SAMPLE_BITS-1:0] audio_pc_buffer [0:WINDOW_SIZE];
	logic [8:0] fft_packet_counter = 0; //this tells us when to send a packet
	logic [8:0] fft_start = 0;
	logic wfft_input_valid;
	logic start_reinsertion = 0;


   always_ff @(posedge clk_100mhz) begin
	 if(spi_read_data_valid) begin //every sample.
		//CHANGE WHEN BIT LENGTH CHANGES
	   audio_sample <= {spi_read_data[9:0],22'b0}; //9:0 is needed to take the data parts of spi_read_data
	   // pad to 32 bits.
	   //random_bits <= (random_bits << 2) || {14'b0,spi_read_data[1:0]}; //collects random bits.
	   prev_audio_sample <= audio_sample;
	   
		//Offset compensation (signed)
		audio_of <= $signed(audio_of_partial[SAMPLE_BITS-1:0]);
		audio_of_buffer <= audio_of;
		
		//Preemphasis (overflow unlikely.)
	    audio_pc_buffer[0] <= $signed(audio_of_buffer - audio_of + $signed(audio_of[SAMPLE_BITS-1:5])); //Preemphasis (that does 1-1/32 instead of 0.97)

		//Setting up fft
		for (int i=1; i<WINDOW_SIZE; i=i+1) begin
			audio_pc_buffer[i] <= audio_pc_buffer[i-1];
		end
		
		if (fft_packet_counter == WINDOW_OVERLAP - 1) begin
			fft_packet_counter <= 0;
			fft_start <= WINDOW_SIZE; //flare that fft_start for 1 cycle.
		end else
			fft_packet_counter <= fft_packet_counter+1;
	end
	
	
	else if (fft_start!=0) begin//in situations we need to start wfft, use this
		// at this instant
		// audio_pc_buffer[0:399] store stuff with 0 most recent
		// audio_pc_buffer[0:240] must be reused
		// audio_pc_buffer[240:399] disappears forever.
		wfft_input_valid <= 1;
		fft_start <= fft_start - 1;
		for (int i=1; i<WINDOW_SIZE; i=i+1) begin
			audio_pc_buffer[i] <= audio_pc_buffer[i-1];
		end

		if (start_reinsertion == 1) begin
			audio_pc_buffer[0] <= audio_pc_buffer[WINDOW_SIZE-1];
		end else if (fft_start == WINDOW_SIZE - WINDOW_OVERLAP) begin
			start_reinsertion <= 1;
			audio_pc_buffer[0] <= audio_pc_buffer[WINDOW_SIZE-1];
		end
		
	end
	
	else begin
		wfft_input_valid <= 0;
		start_reinsertion <= 0;
	end
   end

	logic [SAMPLE_BITS-1:0] wfft_input, wfft_result;
	logic wfft_valid;

	// HERE WE GO
    windowed_fft #(.BIT_WIDTH(SAMPLE_BITS))
	my_windowed_fft
	(.clk_in(clk_100mhz),
	.rst_in(sys_rst),
	.start(wfft_input_valid),
	.input_sample(audio_pc_buffer[WINDOW_SIZE-1]),
	.output_valid(wfft_valid),
	.wfft_result(wfft_result)
	);
	
	// Rearrangement into 0-159 to get the order of frequencies we want
	logic [SAMPLE_BITS-1:0] reordered_coeff [0:160];
	logic [8:0] counter_coeff;
	logic [8:0] reversed_counter_coeff;
	assign reversed_counter_coeff = 
		{counter_coeff[0],counter_coeff[1],counter_coeff[2],
		counter_coeff[3],counter_coeff[4],counter_coeff[5],
		counter_coeff[6],counter_coeff[7],counter_coeff[8]};
	logic all_coeff_ordered = 0;
	
	always_ff @(posedge clk_100mhz) begin
		if (wfft_valid) begin
			counter_coeff <= 1;
			reordered_coeff[0] <= wfft_result;
		end else if (counter_coeff != 0) begin
			counter_coeff <= counter_coeff + 1;
			if (reversed_counter_coeff < 160) begin
				reordered_coeff[reversed_counter_coeff] <= wfft_result;
			end
			if (counter_coeff == 9'h1ff) begin
				all_coeff_ordered <= 1;
			end
		end else
			all_coeff_ordered <= 0;
	end
	
	// Formant analysis using wfft_result and wfft_valid
	// Note that these are still fairly sus... reversed_bit or what
	// but it's time for another file!
	parameter FORMANTS = 1;
	
	logic formant_valid;
	logic [SAMPLE_BITS-1:0] freq_buffer [0:FORMANTS];
	
	/*formant #(.FORMANTS(FORMANTS)) my_dp_formant
	(.clk_in(clk_100mhz),
	.rst_in(sys_rst),
	.fft_valid(wfft_valid),
	.fft_data(wfft_result),
	.formant_valid(),
	.formant_freq(freq_buffer)
	); //Probably fine to just send all frequencies to module...*/
	
	//Outputing to check
	//This is failing and I'm kinda ambivalent to that...
	/* Currently only taking 160 fourier coeffients and ordered above.
	logic [7:0] wfft_data;
	logic [7:0] wfft_result_buffer [0:512]; //this stores the fourier coeffs
	logic [9:0] wfft_data_counter;
	always_ff @(posedge clk_100mhz) begin
		if (wfft_valid) begin
			//changing which bits of the fourier coeff we extract...
			wfft_result_buffer[0] <= wfft_result[SAMPLE_BITS-1:SAMPLE_BITS-8];
			for (int i=1; i<512; i=i+1) begin
				wfft_result_buffer[i] <= wfft_result_buffer[i-1];
			end
		end
	end */
	
	parameter UART_SAMPLES = 420;
	parameter CYCLES_PER_SAMPLE = 2200;
	logic [7:0] uart_420_packets [0:UART_SAMPLES];
	logic [9:0] uart_counter = 420;
	logic [12:0] clock_cycles_per_sample = 0;
	logic new_uart_data_available = 0;
	logic [7:0] new_uart_data;
	// we use fft_start as a flare every 10ms to denote extraction.
	always_ff @(posedge clk_100mhz) begin
		if (uart_counter<UART_SAMPLES) begin
			//output stream has been setup
			//uart 8bits every CYCLES_PER_SAMPLE cycles.
			if (clock_cycles_per_sample < CYCLES_PER_SAMPLE) begin
				clock_cycles_per_sample <= clock_cycles_per_sample + 1;
				new_uart_data_available <= 0; //!!! the thing accumaltes already!
			end
			if (clock_cycles_per_sample == CYCLES_PER_SAMPLE) begin
				clock_cycles_per_sample <= 0;
				uart_counter <= uart_counter + 1;
				new_uart_data_available <= 1;
				new_uart_data <= uart_420_packets[UART_SAMPLES-1];
				for (int i=1; i<UART_SAMPLES; i=i+1) begin
					uart_420_packets[i] <= uart_420_packets[i-1];
				end
			end
				
		end else if (fft_start > 0) begin
			//10ms flare is given, initialize the output stream
			//[0:160] steals the audio output
			//[160:416] steals the fourier output (only half)
			//[416:420] is constant 128 for figuring this out later.
			for (int i=0; i<160; i=i+1) begin
				uart_420_packets[i] <= 
					8'h80 ^ audio_pc_buffer[i + WINDOW_SIZE - WINDOW_OVERLAP][SAMPLE_BITS-1 : SAMPLE_BITS-8];
			end
			for (int i=0; i<160; i=i+1) begin //Now loading the 
				uart_420_packets[i+160] <= reordered_coeff[i];
			end
			for (int i=320; i<416; i=i+1) begin
				uart_420_packets[i] <= 8'h00;
			end
			uart_420_packets[416] <= 8'hff;
			uart_420_packets[417] <= 8'hff;
			uart_420_packets[418] <= 8'hff;
			uart_420_packets[419] <= 8'hff;
			uart_counter <= 0; //starts the output stream
		end else
			new_uart_data_available <= 0; //stops from outputing after 420.
	end

   // Data Buffer SPI-UART
   logic                      audio_sample_waiting;
   
   always_ff @(posedge clk_100mhz) begin
	 if (sys_rst) audio_sample_waiting <= 0;
     //else if (spi_read_data_valid) audio_sample_waiting <= 1; //How we get data in rn
	 else if (new_uart_data_available) audio_sample_waiting <= 1; //use logic to get each sample
	 else if (uart_data_valid == 0) audio_sample_waiting <= 0;
   end

   logic [7:0]                uart_data_in; 
   logic                      uart_data_valid;
   logic                      uart_busy;
   
   always_ff @(posedge clk_100mhz) begin
     if (sys_rst) begin 
	   uart_data_in <= 0;
      end else if (sw[0]==0) begin 
	   uart_data_valid <= 0;
	 end else if (audio_sample_waiting == 1 && uart_data_valid == 0) begin
	   uart_data_in <= new_uart_data;
	   uart_data_valid <= 1;
	 end else if (uart_busy == 0) begin 
	   uart_data_valid <= 0; //transmission started, dont keep sending it.
	   end
   end
   
   // UART Transmitter to FTDI2232
   // TODO: instantiate the UART transmitter you just wrote, using the input signals from above.
   
   uart_transmit #(.BAUD_RATE(460800)) my_uart_transmitter
   (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .data_byte_in(uart_data_in),
    .trigger_in(uart_data_valid),
    .busy_out(uart_busy),
    .tx_wire_out(uart_txd)
    );

endmodule // top_level

`default_nettype wire