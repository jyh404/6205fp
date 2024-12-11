module formant #(
	parameter BIT_WIDTH = 32, 
	parameter I = 160, 
	parameter FORMANTS = 5
) (
	input wire clk_in,
	input wire rst_in,
	input wire fft_valid, //valid for the 160 valid data
	input wire [BIT_WIDTH-1:0] fft_data, //is in for 160 cycles
	output logic [BIT_WIDTH-1:0] debug_formant_T,
	output logic [BIT_WIDTH-1:0] debug_formant_E,
	output logic [BIT_WIDTH-1:0] debug_formant_F,
	output logic [BIT_WIDTH-1:0] debug_formant_B,
	output logic formant_valid,
	output logic [BIT_WIDTH-1:0] formant_freq [0:FORMANTS-1]
); //this has 1million cycles to finish, sure hope it does.
	localparam I_WIDTH = $clog2(I);

	// T BRAM Used for computation of Emin
	// read_address is compiled as we only ever take all 3 values at once.
	// Helps to spread out wires to split up the storage... maybe?
	localparam NU_VALUES = 3;
	logic [I_WIDTH-1:0] T_write_address;
	logic [BIT_WIDTH-1:0] T_input_data [0:NU_VALUES-1];
	logic T_input_data_valid;
	logic [I_WIDTH-1:0] T_read_address;
	logic [BIT_WIDTH-1:0] T_output_data [0:NU_VALUES-1]; //Testing the read values here... to be non-zero.

	// Emin BRAM is the loss of having a segment (addr,f) for each f
	// We could use a rolling buffer, but currently we are calculating all of Emin(x, i), then calculate all of F(k, i)
	// without any simultaneous calculation of Emin during F, so one BRAM suffices
	logic [I_WIDTH-1:0] E_write_address;
	logic [BIT_WIDTH-1:0] E_input_data;
	logic E_input_data_valid;
	logic [I_WIDTH-1:0] E_read_address;
	logic [BIT_WIDTH-1:0] E_output_data;

	// F BRAM Is the loss of having k segments up to addr
	// There is one BRAM for each possible number of formants.
	logic [I_WIDTH-1:0] F_write_address;
	logic [BIT_WIDTH-1:0] F_input_data;
	logic F_input_data_valid [0:FORMANTS-1];
	logic [I_WIDTH-1:0] F_read_address;
	logic [BIT_WIDTH-1:0] F_output_data [0:FORMANTS-1];

	// B BRAM Used to store the optimal place for the next segment boundary.
	// Traceback to get the optimal segment placement.
	logic [I_WIDTH-1:0] B_write_address;
	logic [BIT_WIDTH-1:0] B_input_data;
	logic B_input_data_valid [0:FORMANTS-1];
	logic [I_WIDTH-1:0] B_read_address;
	logic [BIT_WIDTH-1:0] B_output_data [0:FORMANTS-1];
	
	always_ff @(posedge clk_in) begin
		debug_formant_T <= (T_output_data[0] != 0) ? T_output_data[0] : debug_formant_T;
		debug_formant_E <= (E_output_data[0] != 0) ? E_output_data : debug_formant_E;
		debug_formant_F <= (F_output_data[0] != 0) ? F_output_data[0] : debug_formant_F;
		debug_formant_B <= (B_output_data[0] != 0) ? B_output_data[0] : debug_formant_B;
	end

	generate
		genvar i;
		
		//T[nu] is the sum multiplied some cosine weightage.
		for (i = 0; i < NU_VALUES; ++i) begin
			xilinx_true_dual_port_read_first_1_clock_ram #(
				.RAM_WIDTH(BIT_WIDTH),
				.RAM_DEPTH(I),
				.RAM_PERFORMANCE("HIGH_PERFORMANCE")
			) 
			T_bram
			(
				.clka(clk_in),     // Clock
				//writing port:
				.addra(T_write_address),   // Port A address bus,
				.dina(T_input_data[i]),     // Port A RAM input data
				.wea(T_input_data_valid),       // Port A write enable
				//reading port:
				.addrb(T_read_address),   // Port B address bus,
				.doutb(T_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);
		end
		
		//Emin calculation of the next frequency sample.
		xilinx_true_dual_port_read_first_1_clock_ram #(
			.RAM_WIDTH(BIT_WIDTH),
			.RAM_DEPTH(I),
			.RAM_PERFORMANCE("HIGH_PERFORMANCE")
		) 
		Emin_bram
		(
			.clka(clk_in),     // Clock
			//writing port:
			.addra(E_write_address),   // Port A address bus,
			.dina(E_input_data),     // Port A RAM input data
			.wea(E_input_data_valid),       // Port A write enable
			//reading port:
			.addrb(E_read_address),   // Port B address bus,
			.doutb(E_output_data),    // Port B RAM output data,
			.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
			.dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
			.web(1'b0),       // Port B write enable
			.ena(1'b1),       // Port A RAM Enable
			.enb(1'b1),       // Port B RAM Enable,
			.rsta(1'b0),     // Port A output reset
			.rstb(1'b0),     // Port B output reset
			.regcea(1'b1), // Port A output register enable
			.regceb(1'b1) // Port B output register enable
		);
		
		//F[p] is the loss of (0,addr) if p formants were used.
		for (i = 0; i < FORMANTS; ++i) begin
			xilinx_true_dual_port_read_first_1_clock_ram #(
				.RAM_WIDTH(BIT_WIDTH),
				.RAM_DEPTH(I),
				.RAM_PERFORMANCE("HIGH_PERFORMANCE")
			) 
			F_bram
			(
				.clka(clk_in),     // Clock
				//writing port:
				.addra(F_write_address),   // Port A address bus,
				.dina(F_input_data),     // Port A RAM input data
				.wea(F_input_data_valid[i]),       // Port A write enable
				//reading port:
				.addrb(F_read_address),   // Port B address bus,
				.doutb(F_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);

			//B[p] is the location of the next segment boundary if p segments are used.
			xilinx_true_dual_port_read_first_1_clock_ram #(
				.RAM_WIDTH(BIT_WIDTH),
				.RAM_DEPTH(I),
				.RAM_PERFORMANCE("HIGH_PERFORMANCE")
			) 
			B_bram
			(
				.clka(clk_in),     // Clock
				//writing port:
				.addra(B_write_address),   // Port A address bus,
				.dina(B_input_data),     // Port A RAM input data
				.wea(B_input_data_valid[i]),       // Port A write enable
				//reading port:
				.addrb(B_read_address),   // Port B address bus,
				.doutb(B_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);
		end
  	endgenerate

	typedef enum {START, T_CALC, EMIN_CALC, F_CALC, SEGMENT_CALC, PHI_CALC, FINAL} poss_state;
	poss_state state;

	logic [I_WIDTH-1:0] current_i;
	
	// for traceback
	logic [I_WIDTH-1:0] segment_values [0:FORMANTS];
	logic [$clog2(FORMANTS)-1:0] segment;
	logic delay;

	// phi functions
	logic phi_input_valid;
	logic phi_input_start;
	logic [BIT_WIDTH-1:0] phi_output [0:FORMANTS-1];
	logic phi_output_valid;
	
	// buffer time
	logic [2:0] state_tracker;
	
	
	//fixing timing for T_read_address
	logic [I_WIDTH-1:0] emin_T_read_address, segment_T_read_address, phi_T_read_address;	

	always_comb begin
		case(state)
			default: T_read_address = emin_T_read_address;
			SEGMENT_CALC: T_read_address = segment_T_read_address;
			PHI_CALC: T_read_address = phi_T_read_address;
		endcase
	end

	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			state <= START;
			current_i <= 0;
			emin_input_valid <= 0;
			f_begin_iter <= 0;
			for (integer b = 0; b <= FORMANTS; ++b) begin
				segment_values[b] <= 0;
			end
		end else begin
			case (state)
				START: begin
					current_i <= 0;
					formant_valid <= 0;
					state_tracker <= 3'b000;
					if (fft_valid) begin
						// FFT data is starting to arrive
						state <= T_CALC;
					end
				end
				T_CALC: begin
					state_tracker <= 3'b001;
					if (T_write_address == I - 1) begin
						// we have written the last T value
						state <= EMIN_CALC;
						emin_input_valid <= 1'b1;
					end
				end
				EMIN_CALC: begin
					emin_input_valid <= 1'b0;
					state_tracker <= 3'b010;
					//T_read_address <= emin_T_read_address;
					if ((E_write_address == 0) && E_input_data_valid) begin
						// we have written the last Emin value
						state <= F_CALC;
						f_begin_iter <= 1'b1;
					end
				end
				F_CALC: begin
					state_tracker <= 3'b011;
					f_begin_iter <= 1'b0;
					if (f_iter_done) begin
						if (current_i < I - 1) begin
							state <= EMIN_CALC;
							current_i <= current_i + 1;
							emin_input_valid <= 1'b1;
						end else begin
							state <= SEGMENT_CALC;
							segment <= FORMANTS;
							segment_values[FORMANTS] <= I - 1;
							delay <= 1'b1;
							B_read_address <= segment_values[FORMANTS];
						end
					end
				end
				SEGMENT_CALC: begin
					if (segment) begin
						if (delay) begin
							delay <= delay - 1;
						end else begin
							delay <= 1'b1;
							segment_values[segment-1] <= B_output_data[segment-1];
							if (segment > 1) begin
								B_read_address <= B_output_data[segment-1];
							end
							segment <= segment - 1;
						end
					end else begin
						state <= PHI_CALC;
						delay <= 1'b1;
						segment_T_read_address <= segment_values[1];
						segment <= 1;
						phi_input_start <= 1'b1;
					end
				end
				PHI_CALC: begin
					// send the T_vals sequentially
					// don't do any fancy stuff
					phi_input_start <= 1'b0;
					if (segment < FORMANTS) begin
						if (delay) begin
							delay <= delay - 1;
							phi_input_valid <= 1'b0;
						end else begin
							delay <= 1'b1;
							phi_input_valid <= 1'b1;
							phi_T_read_address <= segment_values[segment+1];
							segment <= segment + 1;
						end
					end else if (phi_output_valid) begin
						state <= START;
						formant_valid <= 1'b1;
						// formant_freq <= phi_output; // cocotb does not support this
						for (integer b = 0; b < FORMANTS; ++b) begin
							formant_freq[b] <= phi_output[b];
						end
					end
				end
			endcase
		end
	end

	T #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I),
		.NU_VALUES(NU_VALUES)
	) 
	t_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.fft_valid(fft_valid),
		.fft_data(fft_data),
		.output_written_0(T_input_data[0]),
		.output_written_1(T_input_data[1]),
		.output_written_2(T_input_data[2]),
		.output_valid(T_input_data_valid),
		.output_address(T_write_address)
	);

	logic emin_input_valid;

	emin #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I)
	) 
	emin_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.i(current_i),
		.input_valid(emin_input_valid),
		.T_resp0(T_output_data[0]),
		.T_resp1(T_output_data[1]),
		.T_resp2(T_output_data[2]),
		.T_req(emin_T_read_address),
		.j_out(E_write_address),
		.data_out(E_input_data),
		.output_valid(E_input_data_valid)
	);

	// need to pipeline k_req to make sure we pass the correct
	// F(k-1,j) that was requested two cycles ago
	logic [$clog2(FORMANTS)-1:0] k_req [0:1];
	logic [$clog2(FORMANTS)-1:0] k_req_begin;
	logic [I_WIDTH-1:0] j_req;
	logic [$clog2(FORMANTS)-1:0] k_write;
	logic f_output_valid;
	logic f_begin_iter;
	logic f_iter_done;
	
	always_comb begin
		for (int i=0; i<FORMANTS; i++) begin
			F_input_data_valid[i] = (i == k_write) ? f_output_valid : 1'b0; 	
			B_input_data_valid[i] = (i == k_write) ? f_output_valid : 1'b0; 	
		end
	end

	f #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I),
		.FORMANTS(FORMANTS)
	)
	f_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.begin_iter(f_begin_iter),
		.i(current_i),
		.e_prev(E_output_data),
		.f_prev(F_output_data[k_req[1]-1]),
		.k_req(k_req_begin),
		.j_req(j_req),
		.k_write(k_write),
		.f_data(F_input_data),
		.b_data(B_input_data),
		.output_valid(f_output_valid),
		.iter_done(f_iter_done)
	);

	always_ff @(posedge clk_in) begin
		k_req[0] <= k_req_begin;
		k_req[1] <= k_req[0];
	end

	assign F_read_address = j_req; // can request from all F BRAMs at once
	assign E_read_address = j_req + 1;
	assign F_write_address = current_i;
	assign B_write_address = current_i;

	phi #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I),
		.FORMANTS(FORMANTS),
		.NU_VALUES(NU_VALUES)
	)
	phi_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.T_vals(T_output_data),
		.input_start(phi_input_start),
		.input_valid(phi_input_valid),
		.output_data(phi_output),
		.output_valid(phi_output_valid)
	);

endmodule 