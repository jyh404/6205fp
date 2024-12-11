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
	
	logic [7:0] f_write_address; 
	logic [SAMPLE_BITS-1:0] f_input_data;
	logic f_input_data_valid;
	logic [7:0] f_read_address;
	logic [SAMPLE_BITS-1:0] f_output_data;
	
	xilinx_true_dual_port_read_first_1_clock_ram #(
		.RAM_WIDTH(SAMPLE_BITS),
		.RAM_DEPTH(256),
		.RAM_PERFORMANCE("HIGH_PERFORMANCE")
	) 
	fft_bram
	(
		.clka(clk_100mhz),     // Clock
		//writing port:
		.addra(f_write_address),   // Port A address bus,
		.dina(f_input_data),     // Port A RAM input data
		.wea(f_input_data_valid),       // Port A write enable
		//reading port:
		.addrb(f_read_address),   // Port B address bus,
		.doutb(f_output_data),    // Port B RAM output data,
		.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
		.dinb(32'b0),     // Port B RAM input data, width determined from RAM_WIDTH
		.web(1'b0),       // Port B write enable
		.ena(1'b1),       // Port A RAM Enable
		.enb(1'b1),       // Port B RAM Enable,
		.rsta(1'b0),     // Port A output reset
		.rstb(1'b0),     // Port B output reset
		.regcea(1'b1), // Port A output register enable
		.regceb(1'b1) // Port B output register enable
	);
	
	logic wfft_valid_prev;
	logic [8:0] wfft_counter;
	logic fft_bram_all_ready [0:2]; //Only read when this flares.
	always_ff @(posedge clk_100mhz) begin
		wfft_valid_prev <= wfft_valid;
		if (wfft_valid && !wfft_valid_prev) begin
			wfft_counter <= 1;
		end else if (wfft_counter != 0) begin
			wfft_counter <= wfft_counter + 1;
		end
		fft_bram_all_ready[2] <= (!wfft_valid && wfft_valid_prev);
		fft_bram_all_ready[1] <= fft_bram_all_ready[2];
		fft_bram_all_ready[0] <= fft_bram_all_ready[1];
	end
	
	//writing module
	always_ff @(posedge clk_100mhz) begin
		f_input_data_valid <= (wfft_valid && wfft_counter[0] == 1'b0);
		f_input_data <= wfft_result;
		f_write_address <= {wfft_counter[1],wfft_counter[2],wfft_counter[3],
							wfft_counter[4],wfft_counter[5],wfft_counter[6],
							wfft_counter[7],wfft_counter[8]}; //ideally this is reversed later
	end
	
	//reading module, testing here.
	logic [7:0] reordering_counter;
	assign f_read_address = reordering_counter;
	always_ff @(posedge clk_100mhz) begin
		if (fft_bram_all_ready[0] == 1'b1) begin //this is a flare signal
			reordering_counter <= 8'h01;
		end else if (reordering_counter != 8'h00) begin
			reordering_counter <= reordering_counter + 1;
		end
	end

	
	//This is used to output things in the log 'cause thats fun and all
	//1 cycle delay
	logic [7:0] f_output_data_log;
	log2bad my_bad_log2 (
		.clk_in(clk_100mhz),
		.log_in(f_output_data),
		.log_out(f_output_data_log)
	);
	
	logic reordering_valid_buffer [0:1];
	logic [7:0] reordering_counter_buffer [0:2]; //2 for BRAM, 1 for log2bad
	logic [7:0] reordered_counter;
	logic [7:0] reordered_flipflops [0:256];
	always_ff @(posedge clk_100mhz) begin
		reordering_valid_buffer[1] <= fft_bram_all_ready[0];
		reordering_valid_buffer[0] <= reordering_valid_buffer[1];
		reordering_counter_buffer[2] <= reordering_counter;
		reordering_counter_buffer[1] <= reordering_counter_buffer[2];
		reordering_counter_buffer[0] <= reordering_counter_buffer[1];
		//This gives a choice of output
		//Top: log/8, Bottom: Top 8 bits.
		reordered_flipflops[reordering_counter_buffer[0]] <= f_output_data_log;
		// reordered_flipflops[reordering_counter_buffer[1]] <= f_output_data[31:24];
		// i am sneaking the uart packet here... oops
	end

	
	// Rearrangement into 0-159 to get the order of frequencies we want\
	// Rearrangement is failing, I am also testing the ip setup
	/*logic [SAMPLE_BITS-1:0] reordered_coeff [0:160];
	logic [8:0] counter_coeff;
	logic [8:0] reversed_counter_coeff;
	assign reversed_counter_coeff = 
		{counter_coeff[0],counter_coeff[1],counter_coeff[2],
		counter_coeff[3],counter_coeff[4],counter_coeff[5],
		counter_coeff[6],counter_coeff[7],counter_coeff[8]};
	logic all_coeff_ordered = 0;
	
	always_ff @(posedge clk_100mhz) begin
		if (wfft_valid) begin //I skill issued here, seek to fix this if i revert.
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
	end*/
	
	
	
	// Formant analysis using wfft_result and wfft_valid
	// Note that these are still fairly sus... reversed_bit or what
	// but it's time for another file!
	parameter FORMANTS = 5;
	parameter FREQ_INPUTS = 160;
	
	logic formant_in_valid; //Keeps on for 160 cycles hopefully
	logic [7:0] formant_valid_counter;
	logic [31:0] formant_in_data;
	logic formant_data_valid;

	
	//INPUTS TO FORMANTS
	//assign formant_in_data = f_output_data;
	always_ff @(posedge clk_100mhz) begin
		formant_in_data <= f_output_data;
		if (reordering_valid_buffer[0]) begin //2 cycle delay given here
			formant_valid_counter <= 1;
			formant_in_valid <= 1;
		end else if (formant_valid_counter == FREQ_INPUTS-1) begin
			formant_valid_counter <= 0;
			formant_in_valid <= 0;
		end else if (formant_valid_counter != 0) begin
			formant_valid_counter <= formant_valid_counter + 1;
		end
	end
	
	logic formant_out_valid;
	logic [SAMPLE_BITS-1:0] freq_buffer [0:FORMANTS-1];
	logic [SAMPLE_BITS-1:0] debug_formant_T;
	logic [SAMPLE_BITS-1:0] debug_formant_E;
	logic [SAMPLE_BITS-1:0] debug_formant_F;
	logic [SAMPLE_BITS-1:0] debug_formant_B;
	
	
	formant #(.FORMANTS(FORMANTS)) my_dp_formant
	(.clk_in(clk_100mhz),
	.rst_in(sys_rst),
	.fft_valid(formant_in_valid),
	.fft_data(formant_in_data),
	.debug_formant_T(debug_formant_T),
	.debug_formant_E(debug_formant_E),
	.debug_formant_F(debug_formant_F),
	.debug_formant_B(debug_formant_B),
	.formant_valid(formant_out_valid),
	.formant_freq(freq_buffer)
	); //Probably fine to just send all frequencies to module...
	
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
	logic [9:0] uart_counter = UART_SAMPLES;
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
				uart_420_packets[i+160] <= reordered_flipflops[i];
			end
			for (int i=320; i<390; i=i+1) begin
				uart_420_packets[i] <= 8'h00;
			end
			uart_420_packets[389] <= 8'hff;
			uart_420_packets[390] <= debug_formant_T[31:24];
			uart_420_packets[391] <= debug_formant_T[23:16];
			uart_420_packets[392] <= debug_formant_T[15:08];
			uart_420_packets[393] <= debug_formant_T[07:00];
			uart_420_packets[394] <= debug_formant_E[31:24];
			uart_420_packets[395] <= debug_formant_E[23:16];
			uart_420_packets[396] <= debug_formant_E[15:08];
			uart_420_packets[397] <= debug_formant_E[07:00];
			uart_420_packets[398] <= debug_formant_F[31:24];
			uart_420_packets[399] <= debug_formant_F[23:16];
			uart_420_packets[400] <= debug_formant_F[15:08];
			uart_420_packets[401] <= debug_formant_F[07:00];
			uart_420_packets[402] <= debug_formant_B[31:24];
			uart_420_packets[403] <= debug_formant_B[23:16];
			uart_420_packets[404] <= debug_formant_B[15:08];
			uart_420_packets[405] <= debug_formant_B[07:00];
			uart_420_packets[406] <= freq_buffer[0][31:24];
			uart_420_packets[407] <= freq_buffer[0][23:16];
			uart_420_packets[408] <= freq_buffer[1][31:24];
			uart_420_packets[409] <= freq_buffer[1][23:16];
			uart_420_packets[410] <= freq_buffer[2][31:24];
			uart_420_packets[411] <= freq_buffer[2][23:16];
			uart_420_packets[412] <= freq_buffer[3][31:24];
			uart_420_packets[413] <= freq_buffer[3][23:16];
			uart_420_packets[414] <= freq_buffer[4][31:24];
			uart_420_packets[415] <= freq_buffer[4][23:16];
			
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

	// IT IS TIME TO GRAPH OUR FORMANTS
	// FBRAM = frame bram

	localparam FRAME_WIDTH = 1280;
	localparam FRAME_HEIGHT = 720;
	localparam DATA_LEN = 8;
	localparam FBRAM_DEPTH = FRAME_WIDTH * FRAME_HEIGHT / DATA_LEN;

	logic [DATA_LEN-1:0] formant_graph [0:FRAME_HEIGHT-1];

	logic [$clog2(FBRAM_DEPTH)-1:0] fbram_write_address;
	logic [DATA_LEN-1:0] fbram_input_data;
	logic fbram_input_data_valid;

	logic [$clog2(FBRAM_DEPTH)-1:0] fbram_read_address;
	logic [DATA_LEN-1:0] fbram_output_data;

	xilinx_true_dual_port_read_first_1_clock_ram #(
		.RAM_WIDTH(DATA_LEN),
		.RAM_DEPTH(FBRAM_DEPTH),
		.RAM_PERFORMANCE("HIGH_PERFORMANCE")
	) 
	fbram
	(
		.clka(clk_100mhz),     // Clock
		//writing port:
		.addra(fbram_write_address),   // Port A address bus,
		.dina(fbram_input_data),     // Port A RAM input data
		.wea(fbram_input_data_valid),       // Port A write enable
		//reading port:
		.addrb(fbram_read_address),   // Port B address bus,
		.doutb(fbram_output_data),    // Port B RAM output data,
		.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
		.dinb(8'b0),     // Port B RAM input data, width determined from RAM_WIDTH
		.web(1'b0),       // Port B write enable
		.ena(1'b1),       // Port A RAM Enable
		.enb(1'b1),       // Port B RAM Enable,
		.rsta(1'b0),     // Port A output reset
		.rstb(1'b0),     // Port B output reset
		.regcea(1'b1), // Port A output register enable
		.regceb(1'b1) // Port B output register enable
	);
    
    logic clk_pixel, clk_5x; //clock lines
    logic locked; //locked signal (we'll leave unused but still hook it up)
    
    //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
    hdmi_clk_wiz_720p mhdmicw (
        .reset(0),
        .locked(locked),
        .clk_ref(clk_100mhz),
        .clk_pixel(clk_pixel),
        .clk_tmds(clk_5x)
	);
    
    logic [10:0] hcount; //hcount of system!
    logic [9:0] vcount; //vcount of system!
    logic hor_sync; //horizontal sync signal
    logic vert_sync; //vertical sync signal
    logic active_draw; //active draw! 1 when in drawing region, 0 in blanking/sync
    logic new_frame; //one cycle active indicator of new frame of info!
    logic [5:0] frame_count; // 0 to 59 then rollover frame counter
    
    //written by you previously! (make sure you include in your hdl)
    //default instantiation so making signals for 720p
    video_sig_gen mvg(
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .vs_out(vert_sync),
        .hs_out(hor_sync),
        .ad_out(active_draw),
        .nf_out(new_frame),
        .fc_out(frame_count)
	);
    
    logic [7:0] red, green, blue; //red green and blue pixel values for output
    logic [9:0] tmds_10b [2:0]; //output of each TMDS encoder!
    logic tmds_signal [2:0]; //output of each TMDS serializer!

	typedef enum {WAIT_DRAW, DRAW, HBLANK, VBLANK} frame_state;
	framestate state;

	logic [FRAME_WIDTH-1:0] row_data;
	logic [$clog2(FRAME_WIDTH)-1:0] row_offset;
	logic [$clog2(FRAME_WIDTH)-1:0] row_index;
	logic [$clog2(FRAME_HEIGHT)-1:0] col_index;
	logic [$clog2(FRAME_WIDTH)-1:0] row_index_pipeline [0:1];

	// for BRAM waiting
	always_ff @(posedge clk_in) begin
		row_index_pipeline[0] <= row_index;
		row_index_pipeline[1] <= row_index_pipeline[0];
	end

	// drawing row by row: just do white if on, black if off
	always_comb begin
		red = (row_data[hcount]) ? 8'hff : 8'h00;
		green = (row_data[hcount]) ? 8'hff : 8'h00;
		blue = (row_data[hcount]) ? 8'hff : 8'h00;
	end

	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			state <= DRAW;
			row_offset <= 0;
			fbram_read_address <= 0;
		end else begin
			case (state) 
				WAIT_DRAW: begin
					fbram_input_data_valid <= 1'b0;
					if (hcount == 0) begin
						state <= DRAW;
					end
				end
				DRAW: begin
					if (hcount == FRAME_WIDTH - 1) begin
						state <= HBLANK;
						row_index <= 0;
						fbram_read_address <= (FRAME_WIDTH / DATA_LEN) * (vcount) + row_offset;
					end
				end
				HBLANK: begin
					if (row_index <= FRAME_WIDTH - DATA_LEN) begin
						if (fbram_read_address == (FRAME_WIDTH / DATA_LEN) * (vcount + 1) - 1) begin
							fbram_read_address <= (FRAME_WIDTH / DATA_LEN) * (vcount);
						end else begin
							fbram_read_address <= fbram_read_address + 1;
						end
						row_index <= row_index + DATA_LEN;
					end
					if (row_index_pipeline[1] <= FRAME_WIDTH - DATA_LEN) begin
						row_data[row_index_pipeline[1]+DATA_LEN-1:row_index_pipeline[1]] <= fbram_output_data;
						if (row_index_pipeline[1] == FRAME_WIDTH - DATA_LEN) begin
							if (vcount < FRAME_HEIGHT - 1) begin
								state <= WAIT_DRAW;
							end else begin
								state <= VBLANK;
								col_index <= 0;
							end
						end
					end
				end
				VBLANK: begin
					// move formant_graphs data into bram
					// when done, go to WAIT_DRAW
					if (col_index < FRAME_HEIGHT) begin
						fbram_write_address <= (FRAME_HEIGHT / DATA_LEN) * col_index + row_offset;
						fbram_input_data <= formant_graph[col_index];
						fbram_input_data_valid <= 1'b1;
						col_index <= col_index + 1;
					end else begin
						state <= WAIT_DRAW;
						fbram_input_data_valid <= 1'b0;
						if (row_offset == (FRAME_HEIGHT / DATA_LEN) - 1) begin
							row_offset <= 0;
						end else begin
							row_offset <= row_offset + 1;
						end
					end
				end
			endcase
		end
	end
    
    //three tmds_encoders (blue, green, red)
    
    tmds_encoder tmds_red(
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(red),
        .control_in(2'b0),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[2]));

    tmds_encoder tmds_green(
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(green),
        .control_in(2'b0),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[1]));

    tmds_encoder tmds_blue(
        .clk_in(clk_pixel),
        .rst_in(sys_rst),
        .data_in(blue),
        .control_in({vert_sync, hor_sync}),
        .ve_in(active_draw),
        .tmds_out(tmds_10b[0]));
    
    //three tmds_serializers (blue, green, red):
    tmds_serializer red_ser(
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[2]),
        .tmds_out(tmds_signal[2]));

    tmds_serializer green_ser(
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[1]),
        .tmds_out(tmds_signal[1]));

    tmds_serializer blue_ser(
        .clk_pixel_in(clk_pixel),
        .clk_5x_in(clk_5x),
        .rst_in(sys_rst),
        .tmds_in(tmds_10b[0]),
        .tmds_out(tmds_signal[0]));
    
    //output buffers generating differential signals:
    //three for the r,g,b signals and one that is at the pixel clock rate
    //the HDMI receivers use recover logic coupled with the control signals asserted
    //during blanking and sync periods to synchronize their faster bit clocks off
    //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
    //the slower 74.25 MHz clock)
    OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

endmodule // top_level

`default_nettype wire