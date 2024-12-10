module phi #(
    parameter BIT_WIDTH = 32, 
    parameter I = 160, 
    parameter FORMANTS = 5, 
    parameter NU_VALUES = 3,
	parameter MAX_FREQ = 5000
) ( input wire clk_in,
	input wire rst_in,
    input wire [BIT_WIDTH-1:0] T_vals [0:NU_VALUES-1],
    input wire input_start,
    input wire input_valid,
    output logic [BIT_WIDTH-1:0] output_data [0:FORMANTS-1],
    output logic output_valid
);
    // assumes that segments have been calculated already
    // when input_start is pulsed
    // on the kth time we see input_valid, we read in T_vals
    //  we interpret this as T_vals at the right end of the kth interval
    // we save these T_vals locally
    // then do math with local values and output all phi values at once
	// ok gottit thanks jonathan
	logic [BIT_WIDTH-1:0] T_vals_storage [0:NU_VALUES-1] [0:FORMANTS-1];
	logic flare_seen;
	logic [$clog2(FORMANTS)-1:0] T_vals_seen = 0;
	logic all_seen = 0;
	
	// records flare seen, goes into heightened alert.
	always_ff @(posedge clk_in) begin
		if (input_start) begin
			flare_seen <= 1;
		end else if (T_vals_seen == FORMANTS) begin //overflowing
			flare_seen <= 0;
			all_seen <= 1;
		end
	end
	
	// go on heightened alert and await T_vals.
	always_ff @(posedge clk_in) begin
		if (flare_seen) begin
			if (input_valid) begin
				T_vals_seen <= T_vals_seen + 1;
				T_vals_storage[0] [T_vals_seen] <= T_vals[0];
				T_vals_storage[1] [T_vals_seen] <= T_vals[1];
				T_vals_storage[2] [T_vals_seen] <= T_vals[2];
			end else if (T_vals_seen == FORMANTS) begin
				T_vals_seen <= 0;
			end
		end
	end
	
	// on all_seen, analyze the given T_vals in storage
	// we have T(0), T(1), T(2)
	
	// now we want a flaring gun with some limit on the
	// number of cycles between each phi is calculated
	// this is to be space efficient.
	// because it is a small time constant.
	
	parameter CYCLES_PER_PHI = 100;
	logic [$clog2(CYCLES_PER_PHI)-1:0] cycle_count = 0;
	logic [$clog2(FORMANTS+1)-1:0] formant_index = 0;
	
	always_ff @(posedge clk_in) begin
		if (cycle_count == CYCLES_PER_PHI-1)
			cycle_count <= 0;
		else
			cycle_count <= cycle_count+1;
	end
	//this essentially acts like a 1MHz clock.
	//we synchronize stuff to this clock.
	logic [BIT_WIDTH-1:0] r_small [0:NU_VALUES-1];


	//Cycle 0: formant_index increments to [1,...,FORMANTS]
	//Cycle 0: r0,1,2 are updated as the difference.
	always_ff @(posedge clk_in) begin
		if (all_seen && (cycle_count == 0)) begin
			if (formant_index == FORMANTS) begin
				formant_index <= 0;
				all_seen <= 0; //end loop of formant_index
			end else begin
				if (formant_index == 0) begin
					formant_index <= formant_index + 1;
					r_small[0] <= T_vals_storage[0][0];
					r_small[1] <= T_vals_storage[1][0];
					r_small[2] <= T_vals_storage[2][0];				
				end else begin
					formant_index <= formant_index + 1;
					r_small[0] <= T_vals_storage[0][formant_index]-T_vals_storage[0][formant_index-1];
					r_small[1] <= T_vals_storage[1][formant_index]-T_vals_storage[1][formant_index-1];
					r_small[2] <= T_vals_storage[2][formant_index]-T_vals_storage[2][formant_index-1];
				end
			end
		end 		
	end
	
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


	always_ff @(posedge clk_in) begin
		case(cycle_count)
			//Shift by 16/15 (both work)
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
		endcase
	end
	
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
	always_ff @(posedge clk_in) begin
		case(cycle_count)
			//initial steps
			6: begin
				a_in <= r[0];
				b_in <= r[0];
			end
			7: begin
				m00  <= m_out;
				a_in <= r[1];
				b_in <= r[1];
			end
			8: begin
				m11  <= m_out;
				a_in <= r[0];
				b_in <= r[1];
			end
			9: begin
				abdenom <= $signed(m00)-$signed(m11);
				m01  <= m_out;
				a_in <= r[1];
				b_in <= r[2];
			end
			10: begin
				m12  <= m_out;
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
				a_in <= anum;
				b_in <= oneminusb;
			end
			14: begin
				a_in <= (bnum <<< 2);
				b_in <= abdenom;
				full_num <= m_out; //the worry is accuracy is... doomed...
			end
			15: begin
				full_denom <= m_out; //same here.
			end
			
			//Multiply here again.
	
		endcase
	end
	
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
	divider2b #(
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
	always_ff @(posedge clk_in) begin
		case(cycle_count)
			16: begin
				division_sign <= div_num[BIT_WIDTH-1];
				div_data_valid <= 1;
				div_denom <= full_denom; //guaranteed positive.
				div_num <= (div_num[BIT_WIDTH-1]) ? 
					$signed((-full_num) << BIT_WIDTH) : $signed(full_num << BIT_WIDTH); //not guaranteed positive.
			end
			17: begin
				div_data_valid <= 0;
			end
		endcase
		
	end
	
	//
	//
	//ACOS
	//
	//
	
	logic signed [BIT_WIDTH-1:0] to_acos;
	logic acos_data_valid;
	
	//might be done by bimary search
	//256 values
	//followed by linear interpolation (done by binary search)
	acos#(.BIT_WIDTH(BITWIDTH))
	acos_calc(
		.clk_in(clk_in),
		.acos_in(to_acos),
		.acos_in_valid(acos_data_valid),
		.acos_out(acos_data)
	);
	
	always_ff @(posedge clk_in) begin
		case
			50: begin
				to_acos <= $signed({quotient[BIT_WIDTH:1]});
				//this takes the sign (if it exceeds one whatever is good)
				//and 31 MSB of the output.
				acos_data_valid <= 1'b1;
			end
			51: begin
				acos_data_valid <= 1'b0;
			end
		endcase
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
	end
	
endmodule 