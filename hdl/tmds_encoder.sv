`timescale 1ns / 1ps
`default_nettype none
 
module tmds_encoder(
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] data_in,  // video data (red, green or blue)
    input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
    input wire ve_in,  // video data enable, to choose between control or video signal
    output logic [9:0] tmds_out
);
 
    logic [8:0] q_m;
    logic [4:0] tally;
    logic [4:0] cur_tally;
    
    tm_choice mtm(
        .data_in(data_in),
        .qm_out(q_m)
    );
    
    assign cur_tally = 2 * $countones(q_m[7:0]) - 8; // # 1's minus # 0's

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            tmds_out <= 10'b0;
            tally <= 5'b0;
        end else if (~ve_in) begin
            tally <= 5'b0;
            case (control_in) 
                2'b00: tmds_out <= 10'b1101010100;
                2'b01: tmds_out <= 10'b0010101011;
                2'b10: tmds_out <= 10'b0101010100;
                2'b11: tmds_out <= 10'b1010101011;
            endcase
        end else begin
            if (tally == 5'b0 || cur_tally == 5'b0) begin
                tmds_out <= {!q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0])};
                tally <= (q_m[8]) ? (tally + cur_tally) : (tally - cur_tally);
            end else begin
                if (tally[4] ^ cur_tally[4]) begin
                    // we want to flip
                    tmds_out <= {1'b0, q_m[8], q_m[7:0]};
                    tally <= tally - 2 * !q_m[8] + cur_tally;
                end else begin
                    // we leave the same
                    tmds_out <= {1'b1, q_m[8], ~q_m[7:0]};
                    tally <= tally + 2 * q_m[8] - cur_tally;
                end
            end
        end
    end
 
endmodule
 
`default_nettype wire