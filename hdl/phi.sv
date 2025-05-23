// max 700 cycles
// flares once on output_valid

module phi #(
    parameter BIT_WIDTH = 32, 
    parameter I = 160, 
    parameter FORMANTS = 5, 
    parameter NU_VALUES = 3,
	parameter MAX_FREQ = 5000
) ( input wire clk_in,
	input wire rst_in,
    input wire [BIT_WIDTH-1:0] T_vals_0,
	input wire [BIT_WIDTH-1:0] T_vals_1,
	input wire [BIT_WIDTH-1:0] T_vals_2,
    input wire input_start,
    input wire input_valid,
	output logic input_completed,
	output logic [BIT_WIDTH-1:0] debug_to_acos,
    output logic [BIT_WIDTH-1:0] output_data_1,
    output logic [BIT_WIDTH-1:0] output_data_2,
    output logic [BIT_WIDTH-1:0] output_data_3,
    output logic [BIT_WIDTH-1:0] output_data_4,
    //output logic [BIT_WIDTH-1:0] output_data_5,
    output logic output_valid
);
    // assumes that segments have been calculated already
    // when input_start is pulsed
    // on the kth time we see input_valid, we read in T_vals
    //  we interpret this as T_vals at the right end of the kth interval
    // we save these T_vals locally
    // then do math with local values and output all phi values at once
	// ok gottit thanks jonathan

	typedef enum {WAIT, INPUTTING, ARITHMETIC} poss_state;
	poss_state state;
	
	logic [BIT_WIDTH-1:0] T_vals_storage [0:NU_VALUES-1] [0:FORMANTS-1];
	logic flare_seen;
	logic [$clog2(FORMANTS+1)-1:0] T_vals_seen = 0;
	logic all_seen = 0;
	
	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			flare_seen <= 1'b0;
			state <= WAIT;
		end else begin
			case (state)
				WAIT: begin
					input_completed <= 1'b0;
					if (input_start) begin
						state <= INPUTTING;
						T_vals_seen <= 0;	
					end 
				end
				INPUTTING: begin
					if (T_vals_seen == FORMANTS) begin //overflowing
						state <= ARITHMETIC;
						formant_index <= 0;
						cycle_count <= CYCLES_PER_PHI-2;
					end else if (input_valid) begin
						T_vals_seen <= T_vals_seen + 1;
						T_vals_storage[0] [T_vals_seen] <= T_vals_0;
						T_vals_storage[1] [T_vals_seen] <= T_vals_1;
						T_vals_storage[2] [T_vals_seen] <= T_vals_2;
					end
				end
				ARITHMETIC: begin
					if (cycle_count == CYCLES_PER_PHI-1)
						cycle_count <= 0;
					else
						cycle_count <= cycle_count+1;

					input_completed <= 1'b1;
					case (cycle_count)
						0: begin
							if (formant_index == FORMANTS) begin
								formant_index <= 0;
								state <= WAIT;
							end else begin
								if (formant_index == 0) begin
									formant_index <= formant_index + 1;
									r_small[0] <= T_vals_storage[0][0];
									r_small[1] <= T_vals_storage[1][0];
									r_small[2] <= T_vals_storage[2][0];				
								end else begin
									formant_index <= formant_index + 1;
									r_small[0] <= $signed(T_vals_storage[0][formant_index])-$signed(T_vals_storage[0][formant_index-1]);
									r_small[1] <= $signed(T_vals_storage[1][formant_index])-$signed(T_vals_storage[1][formant_index-1]);
									r_small[2] <= $signed(T_vals_storage[2][formant_index])-$signed(T_vals_storage[2][formant_index-1]);
								end
							end
						end
						1 : for (int i=0; i<3; i++)
								r_shift1[i] <= (can_shift[0]) ? r_small[i]<<16 : r_small[i];
						2 : for (int i=0; i<3; i++)
								r_shift2[i] <= (can_shift[1]) ? r_shift1[i]<<8 : r_shift1[i];
						3 : for (int i=0; i<3; i++)
								r_shift3[i] <= (can_shift[2]) ? r_shift2[i]<<4 : r_shift2[i];
						4 : for (int i=0; i<3; i++)
								r_shift4[i] <= (can_shift[3]) ? r_shift3[i]<<2 : r_shift3[i];
						5 : for (int i=0; i<3; i++)
								r[i] <= (can_shift[4]) ? r_shift4[i]<<1 : r_shift4[i];
						6: begin
							a_in <= r[0];
							b_in <= r[0];
						end
						7: begin
							m00  <= $signed(m_out);
							a_in <= r[1];
							b_in <= r[1];
						end
						8: begin
							m11  <= $signed(m_out);
							a_in <= r[0];
							b_in <= r[1];
						end
						9: begin
							abdenom <= $signed(m00)-$signed(m11);
							m01  <= $signed(m_out);
							a_in <= r[1];
							b_in <= r[2];
						end
						10: begin
							m12  <= $signed(m_out);
							a_in <= r[0];
							b_in <= r[2];
						end
						11: begin
							anum <= $signed(m01) - $signed(m12);
							m02  <= m_out;
						end
						12: begin
							bnum <= $signed(m11) - $signed(m02);
							oneminusb <= $signed(m00) - $signed(m02);
						end
						13: begin
							a_in <= $signed(anum);
							b_in <= $signed(oneminusb);
						end
						14: begin
							a_in <= $signed(bnum);
							b_in <= $signed(abdenom);
							full_num <= $signed(m_out >>> 2); //the worry is accuracy is... doomed...
						end
						15: begin
							full_denom <= $signed(m_out); //same here.
						end
						16: begin
							division_sign <= full_num[2*BIT_WIDTH-1] ^ full_denom[2*BIT_WIDTH-1];
							div_data_valid <= 1;
							div_denom <= (full_denom[BIT_WIDTH-1]) ? 
								$signed((-full_denom)) : $signed(full_denom); //not guaranteed positive.
							div_num <= (full_num[BIT_WIDTH-1]) ? 
								$signed((-full_num) << BIT_WIDTH) : $signed(full_num << BIT_WIDTH); //not guaranteed positive.
						end
						17: begin
							div_data_valid <= 0;
						end
						82: begin
							to_acos <= (division_sign == 1'b1) ? 
								-$signed({1'b0,quotient[BIT_WIDTH-1:1]}) : 
								{1'b0,quotient[BIT_WIDTH-1:1]};
							//this takes the sign (if it exceeds one whatever is good)
							//and 31 MSB of the output.
						end
						85: begin
							debug_to_acos <= to_acos;
							output_data_1 <= (formant_index == 1) ? {acos_data, 8'b0} : output_data_1;
							output_data_2 <= (formant_index == 2) ? {acos_data, 8'b0} : output_data_2;
							output_data_3 <= (formant_index == 3) ? {acos_data, 8'b0} : output_data_3;
							output_data_4 <= (formant_index == 4) ? {acos_data, 8'b0} : output_data_4;
							//output_data_5 <= (formant_index == 5) ? {acos_data, 8'b0} : output_data_5;
							// output_data[formant_index-1] <= {acos_data,8'b0};
						end
						86: begin
							output_valid <= (formant_index == FORMANTS) ? 1 : 0;
						end
						87: begin
							output_valid <= 0;
						end
					endcase
				end
			endcase
		end
	end
	
	// go on heightened alert and await T_vals.
	
	// on all_seen, analyze the given T_vals in storage
	// we have T(0), T(1), T(2)
	
	// now we want a flaring gun with some limit on the
	// number of cycles between each phi is calculated
	// this is to be space efficient.
	// because it is a small time constant.
	
	parameter CYCLES_PER_PHI = 100;
	logic [$clog2(CYCLES_PER_PHI)-1:0] cycle_count;
	logic [$clog2(FORMANTS+1)-1:0] formant_index;
	

	//this essentially acts like a 1MHz clock.
	//we synchronize stuff to this clock.
	logic [BIT_WIDTH-1:0] r_small [0:NU_VALUES-1];


	//Cycle 0: formant_index increments to [1,...,FORMANTS]
	//Cycle 0: r0,1,2 are updated as the difference.
	
	//Up-shift for precision
	//Given we are width 32, try to shift up 5 times 
	//Ensure sign does not flip between
	//r[0] has largest magnitude so it suffice to check that
	logic [BIT_WIDTH-1:0] r_shift1 [0:NU_VALUES-1];
	logic [BIT_WIDTH-1:0] r_shift2 [0:NU_VALUES-1];
	logic [BIT_WIDTH-1:0] r_shift3 [0:NU_VALUES-1];
	logic [BIT_WIDTH-1:0] r_shift4 [0:NU_VALUES-1];
	logic [BIT_WIDTH-1:0] r [0:NU_VALUES-1];
	//we can shift everything up to protect precision...
	
	logic can_shift [0:4];
	assign can_shift[0] = ((r_small[0][31:31-16] == 16'b0) || (r_small[0][31:31-16] == ~16'b0));
	assign can_shift[1] = ((r_shift1[0][31:31-8] == 16'b0) || (r_shift1[0][31:31-16] == ~16'b0));	
	assign can_shift[2] = ((r_shift2[0][31:31-4] == 16'b0) || (r_shift2[0][31:31-16] == ~16'b0));	
	assign can_shift[3] = ((r_shift3[0][31:31-2] == 16'b0) || (r_shift3[0][31:31-16] == ~16'b0));	
	assign can_shift[4] = ((r_shift4[0][31:31-1] == 16'b0) || (r_shift4[0][31:31-16] == ~16'b0));	


	// always_ff @(posedge clk_in) begin
		
	// end
	
	logic signed [BIT_WIDTH-1:0] a_in, b_in, m_out;
	
	//
	//
	// MULTIPLICATION AND ARITHMETIC
	//
	//
	
	
	//We only use one, and time the usage base on the number of the clock.
	Multiply_re #(
		.WIDTH(BIT_WIDTH)
	)phi_multiplier(
		.a_re(a_in),
		.b_re(b_in),
		.m_re(m_out)
	);
	
	logic signed [BIT_WIDTH-1:0] m00,m11,m01,m12,m02,oneminusb;
	logic signed [BIT_WIDTH-1:0] anum, bnum, abdenom;
	logic signed [2*BIT_WIDTH-1:0] full_num, full_denom;
	//Multiply_re usage
	
	//
	//
	// DIVISION
	//
	//
	
	//We also want some signed division thingy
	//But blocking is fine.
	//16 cycle delay
	logic [2*BIT_WIDTH-1:0] div_num, div_denom_nonzero, div_denom;
	logic asign, bsign;
	logic signed [BIT_WIDTH-1:0] ak,bk;
	logic div_data_valid;
	logic signed [2*BIT_WIDTH-1:0] quotient,remainder;
	
	//Using a more efficient but blocking divider module.
	divider2 #(
		.WIDTH(2*BIT_WIDTH)
	)thanks_joe(
		.clk_in(clk_in),
		.rst_in(1'b0),
		.dividend_in(div_num),
		.divisor_in(div_denom_nonzero),
		.data_valid_in(div_data_valid),
		.quotient_out(quotient),
		.remainder_out(remainder)
	);
	
	//to curb divide by 0.
	assign div_denom_nonzero = {div_denom[2*BIT_WIDTH-1:1],1'b1};
	parameter LEFT_SHIFT = 8;
	logic division_sign;
	
	//do more multiplications and just divide once...
	
	//
	//
	//ACOS
	//
	//
	
	logic signed [BIT_WIDTH-1:0] to_acos;
	logic [23:0] acos_data;
	
	//might be done by bimary search
	//256 values
	//followed by linear interpolation (done by binary search)
	acos acos_calc(
		.clk_in(clk_in),
		.acos_in(to_acos),
		.acos_out(acos_data)
	);
	
	/*
		case(cycle_count)
			7: begin
				asign <= anum[BIT_WIDTH-1]^abdenom[BIT_WIDTH-1];
				div_num <= (anum[BITWIDTH-1]==1'b1)? (~anum)+1 : anum;
				div_denom <= (abdenom[BITWIDTH-1]==1'b1)? 
					((~abdenom)+1)>>LEFT_SHIFT : (abdenom)>>LEFT_SHIFT;
			end
			8: begin
				bsign <= bnum[BIT_WIDTH-1]^abdenom[BIT_WIDTH-1];
				div_num <= (bnum[BITWIDTH-1]==1'b1)? (~bnum)+1 : bnum;
				div_denom <= (abdenom[BITWIDTH-1]==1'b1)? 
					((~abdenom)+1)>>LEFT_SHIFT : (abdenom)>>LEFT_SHIFT;
			end
			23: begin //16 cycles after
				ak <= quotient
	
		endcase
	*/
	
endmodule 