module windowed_fft #(
    parameter   FFT_POINTS = 512,
	parameter   WINDOW_POINTS = 400,
	parameter   BIT_WIDTH = 32
)(
    input               clk_in, //Master Clock
    input               rst_in, //Active High Asynchronous Reset
    input               start, //Flare to start process
	input [BIT_WIDTH-1:0] input_sample, //Sample to process on, receive one/cycle when start.
	output logic  				output_valid, //Flare when output is available.
	//output logic [BIT_WIDTH-1:0] wfft_result_re,// Outputs FFT_POINTS/2 magnitudes
	//output logic [BIT_WIDTH-1:0] wfft_result_im
	output logic [BIT_WIDTH-1:0] wfft_result
);

logic fft_inputing;
logic [BIT_WIDTH-1:0] fft_input;
logic [8:0] fft_counter = 0;
logic [BIT_WIDTH-1:0] hamming_factor;

//Do windowing too...
Hamming making_windows 
(
	.clock(clk_in),
	.addr(fft_counter),
	.hamming_factor(hamming_factor)
);


always_ff @(posedge clk_in) begin

	if (fft_counter > 0 && fft_counter < WINDOW_POINTS) begin
		fft_inputing <= 1;
		fft_counter <= fft_counter + 1;
		fft_input <= input_sample;
	end else if (fft_counter >= WINDOW_POINTS) begin //zero pad.
		fft_inputing <= 1;
		fft_counter <= fft_counter + 1;
		fft_input <= 32'h0000;
	end else if (start==1) begin //flare means next input is good
		fft_inputing <= 1;
		fft_counter <= 9'h001; //commence count
		fft_input <= input_sample;
	end else //when it overflows we have entered 512 points
		fft_inputing <= 0;
end

logic fft_inputing_window;
logic [BIT_WIDTH-1:0] fft_input_window;
logic [BIT_WIDTH-1:0] windowed_input;

//Combinatorial
Multiply_re #(.WIDTH(BIT_WIDTH)) 
window_multiply
(
	.a_re(fft_input),
	.b_re(hamming_factor),
	.m_re(windowed_input)
);

// one cycle to do windowing
always_ff @(posedge clk_in) begin
	fft_inputing_window <= fft_inputing;
	fft_input_window <= (fft_input == 32'h0000_0000) ? fft_input : windowed_input;
end

logic fft_output_valid;
logic signed [BIT_WIDTH-1:0] fft_output_re;
logic signed [BIT_WIDTH-1:0] fft_output_im;

FFT FFT_512
(
	.clock(clk_in),
	.reset(rst_in),
	.di_en(fft_inputing_window),
	.di_re(fft_input_window),
	.di_im(0), //???
	.do_en(fft_output_valid),
	.do_re(fft_output_re),
	.do_im(fft_output_im)
);
// Multiplications are currently 24 bit, losing precision.
// But accuracy looks kinda fine still.

//i also want to do magnitude calculation here...
//making the output read so verilog doesnt just remove everything
//only output 256 first values.
//these are sandwiched in even places, and 1-indexed.
//logic [7:0] fft_output_counter=0;
//logic fft_lower_flipper = 0;

//although the order of the ouputs are wrong
//here i elect to just use the reversed-bit order.
//it's kind of a pain
/*
always_ff @(posedge clk_in) begin
	if (fft_output_valid == 1) begin
		output_valid <= 1;
		wfft_result_re <= fft_output_re;
		wfft_result_im <= fft_output_im;
		fft_output_counter <= 8'h01;
	end else if (fft_output_counter != 0) begin
		output_valid <= 1;
		wfft_result_re <= fft_output_re;
		wfft_result_im <= fft_output_im; 
		fft_output_counter <= fft_output_counter + 1;
	end else
		output_valid <= 0;
end
*/

// Magnitude calculation
// Sum of squares.
logic fft_output_valid_buffer;
logic [BIT_WIDTH-9:0] fft_re_sq;
logic [BIT_WIDTH-9:0] fft_im_sq;

logic [BIT_WIDTH-1:0] fft_mag_squared;

//Again 32 bit is causing issue
Multiply_re #(.WIDTH(BIT_WIDTH-8)) 
re_square
(
	.a_re(fft_output_re[BIT_WIDTH-5:BIT_WIDTH-28]),
	.b_re(fft_output_re[BIT_WIDTH-5:BIT_WIDTH-28]),
	.m_re(fft_re_sq)
);

Multiply_re #(.WIDTH(BIT_WIDTH-8)) 
im_square
(
	.a_re(fft_output_im[BIT_WIDTH-5:BIT_WIDTH-28]),
	.b_re(fft_output_im[BIT_WIDTH-5:BIT_WIDTH-28]),
	.m_re(fft_im_sq)
);
always_ff @(posedge clk_in) begin
	fft_mag_squared <= {(fft_re_sq + fft_im_sq),8'h00}; //i expect this cannot overflow
	fft_output_valid_buffer <= fft_output_valid; //one cycle buffer
end

//now take square roots
/*sqrt #(.BIT_WIDTH(BIT_WIDTH)) magnitude_sqrt
(
	.clk_in(clk_in),
	.valid_in(fft_output_valid_buffer),
	.sqrt_in(fft_mag_squared),
	.sqrt_out(wfft_result),
	.valid_out(output_valid)
);*/

//we apparently dont need shifts anymore.
assign output_valid = fft_output_valid_buffer;
assign wfft_result = fft_mag_squared<<4;

endmodule