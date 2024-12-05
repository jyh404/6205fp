module #(BIT_WIDTH = 32, I = 160, FORMANTS = 5) formant(
	input wire clk_in,
	input wire rst_in,
	input wire fft_valid,
	input wire [BIT_WIDTH-1:0] fft_data,
	output wire formant_valid,
	output wire [BIT_WIDTH-1:0] formant_freq [0:FORMANTS]
);
	localparam I_WIDTH = $clog2(I);

	// T BRAM
	localparam NU_VALUES = 3;
	logic [I_WIDTH-1:0] T_write_address;
	logic [BIT_WIDTH-1:0] T_input_data [0:NU_VALUES-1];
	logic T_input_data_valid;
	logic [I_WIDTH-1:0] T_read_address;
	logic [BIT_WIDTH-1:0] T_output_data [0:NU_VALUES-1];

	// Emin BRAM
	localparam E_BUFFERS = 2;
	logic [I_WIDTH-1:0] E_write_address;
	logic [BIT_WIDTH-1:0] E_input_data;
	logic E_input_data_valid [0:E_BUFFERS-1];
	logic [I_WIDTH-1:0] E_read [0:E_BUFFERS-1];
	logic [BIT_WIDTH-1:0] E_output_data [0:E_BUFFERS-1];

	// F BRAM
	logic [I_WIDTH-1:0] F_write_address;
	logic [BIT_WIDTH-1:0] F_input_data;
	logic F_input_data_valid [0:FORMANTS-1];
	logic [I_WIDTH-1:0] F_read_address [0:FORMANTS-1];
	logic [BIT_WIDTH-1:0] F_output_data [0:FORMANTS-1];

	// B BRAM
	logic [I_WIDTH-1:0] B_write_address;
	logic [BIT_WIDTH-1:0] B_input_data;
	logic B_input_data_valid [0:FORMANTS-1];
	logic [I_WIDTH-1:0] B_read_address [0:FORMANTS-1];
	logic [BIT_WIDTH-1:0] B_output_data [0:FORMANTS-1];

	generate
		genvar i;
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
				.dinb(16'b0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);
		end
		for (i = 0; i < E_BUFFERS; ++i) begin
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
				.wea(E_input_data_valid[i]),       // Port A write enable
				//reading port:
				.addrb(E_read[i]),   // Port B address bus,
				.doutb(E_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(16'b0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);
		end
		for (i = 0; i < FORMANT; ++i) begin
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
				.addrb(F_read_address[i]),   // Port B address bus,
				.doutb(F_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(16'b0),     // Port B RAM input data, width determined from RAM_WIDTH
				.web(1'b0),       // Port B write enable
				.ena(1'b1),       // Port A RAM Enable
				.enb(1'b1),       // Port B RAM Enable,
				.rsta(1'b0),     // Port A output reset
				.rstb(1'b0),     // Port B output reset
				.regcea(1'b1), // Port A output register enable
				.regceb(1'b1) // Port B output register enable
			);

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
				.addrb(B_read_address[i]),   // Port B address bus,
				.doutb(B_output_data[i]),    // Port B RAM output data,
				.douta(),   // Port A RAM output data, width determined from RAM_WIDTH
				.dinb(16'b0),     // Port B RAM input data, width determined from RAM_WIDTH
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

	typedef enum {START, T_CALC, EMIN_CALC, F_CALC, SEGMENT_CALC, PHI_CALC, FINAL} state;

	logic [I_WIDTH-1:0] current_i;
	logic [I_WIDTH-1:0] segment_values [0:FORMANTS];
	logic [$clog2(FORMANTS)-1:0] segment;
	logic [1:0] delay;

	// phi functions
	logic phi_input_valid;
	logic [BIT_WIDTH-1:0] phi_output [0:FORMANTS-1];
	logic phi_output_valid;

	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			state <= START;
			current_i <= 0;
		end else begin
			case (state):
				START: begin
					if (fft_valid) begin
						state <= T_CALC;
					end
				end
				T_CALC: begin
					if (T_write_address == I - 1) begin
						state <= EMIN_CALC;
						current_i <= 0;
					end
				end
				EMIN_CALC: begin
					if (E_write_address == I - 1) begin
						state <= F_CALC;
						f_begin_iter <= 1'b1;
					end
				end
				F_CALC: begin
					f_begin_iter <= 1'b0;
					if (f_iter_done) begin
						if (current_i < I - 1) begin
							state <= EMIN_CALC;
							current_i <= current_i + 1;
						end else begin
							state <= SEGMENT_CALC;
							segment <= FORMANTS;
							segment_values[FORMANTS] <= I-1;
							delay <= 2'b10;
							B_read_address[FORMANTS-1] <= segment_values[FORMANTS];
						end
					end
				end
				SEGMENT_CALC: begin
					if (segment > 0) begin
						if (delay == 2'b00) begin
							delay <= 2'b10;
							segment_values[segment-1] <= B_output_data[segment-1];
							if (segment > 1) begin
								B_read_address[segment-2] <= B_output_data[segment-1];
							end
							segment <= segment - 1;
						end else begin
							delay <= delay - 1;
						end
					end else begin
						state <= PHI_CALC;
						delay <= 2'b10;
						T_read_address <= segment_values[1];
						segment <= 1;
						phi_input_start <= 1'b1;
					end
				end
				PHI_CALC: begin
					// send the T_vals sequentially
					// don't do any fancy stuff
					phi_input_start <= 1'b0;
					if (segment < FORMANTS) begin
						if (delay == 2'b00) begin
							delay <= 2'b10;
							phi_input_valid <= 1'b1;
							T_read_address <= segment_values[segment+1];
							segment <= segment + 1;
						end else begin
							delay <= delay - 1;
							phi_input_valid <= 1'b0;
						end
					end else if (phi_output_valid)
						state <= FINAL;
					end
				end
				FINAL: begin
					// multiply phi_output by 5000/pi
					formant_valid <= 1'b1;
				end
			endcase
		end
	end

	t #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I),
		.NU_VALUES(NU_VALUES)
	) 
	t_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.fft_valid(fft_valid),
		.fft_data(fft_data),
		.output_written(T_input_data),
		.output_valid(T_input_data_valid),
		.output_address(T_write_address)
	);

	logic emin_input_valid;
	logic emin_write_buffer = current_i[0]; // buffer depends on i
	logic emin_output_valid;

	emin #(
		.BIT_WIDTH(BIT_WIDTH),
		.I(I),
	) 
	emin_func (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.i(current_i),
		.input_valid(emin_input_valid),
		.T_resp(T_output_data),
		.T_req(T_read_address),
		.j(E_write_address),
		.data(E_input_data),
		.output_valid(emin_output_valid)
	);

	// direct which buffer we are writing to
	E_input_data_valid[emin_write_buffer] = emin_output_valid;
	E_input_data_valid[!emin_write_buffer] = 1'b0;

	// need to pipeline k_req to make sure we pass the correct
	// F(k-1,j) and F(k,i) that was requested two cycles ago
	logic [I_WIDTH-1:0] k_req [0:2];
	logic [I_WIDTH-1:0] j_req;
	logic [$clog(FORMANTS)-1:0] k_write;
	logic f_output_valid;
	logic f_begin_iter;
	logic f_iter_done;

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
		.e_prev(E_output_data[!emin_write_buffer]),
		.f_prev(F_output_data[k_req[2]-1]),
		.f_old(F_output_data[k_req[2]]),
		.k_req(k_req[0]),
		.j_req(j_req),
		.k_write(k_write),
		.f_data(F_input_data),
		.b_data(B_input_data),
		.output_valid(f_output_valid),
		.iter_done(f_iter_done)
	);

	always_comb @(posedge clk_in) begin
		k_req[1] <= k_req[0];
		k_req[2] <= k_req[1];
	end

	assign F_read_address[k_req[0]-1] = j_req;
	assign F_read_address[k_req[0]] = current_i;
	integer k;
	for (k = 0; k < FORMANTS; ++k) begin
		assign F_input_valid[k] = (k == k_write) & f_output_valid;
		assign B_input_valid[k] = F_input_valid[k];
	end
	assign F_write_address = current_i; // this is true!
	assign B_write_address = current_i; // this is also true!

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
		.output(phi_output),
		.output_valid(phi_output_valid)
	);

endmodule 