module video_sig_gen #(
    parameter ACTIVE_H_PIXELS = 1280,
    parameter H_FRONT_PORCH = 110,
    parameter H_SYNC_WIDTH = 40,
    parameter H_BACK_PORCH = 220,
    parameter ACTIVE_LINES = 720,
    parameter V_FRONT_PORCH = 5,
    parameter V_SYNC_WIDTH = 5,
    parameter V_BACK_PORCH = 20,
    parameter FPS = 60) 
    (
    input wire pixel_clk_in,
    input wire rst_in,
    output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
    output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
    output logic vs_out, //vertical sync out
    output logic hs_out, //horizontal sync out
    output logic ad_out,
    output logic nf_out, //single cycle enable signal
    output logic [5:0] fc_out // frame
);

    localparam TOTAL_PIXELS = (ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH);
    localparam TOTAL_LINES = (ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH);
    logic [$clog2(TOTAL_PIXELS)-1:0] hcount;
    logic [$clog2(TOTAL_LINES)-1:0] vcount;

    // BAD VERSION part 1
    /* 
    always_comb begin
        if (hcount_out == TOTAL_PIXELS - 1) begin
            hcount = 0;
            vcount = (vcount_out == TOTAL_LINES - 1) ? 0 : vcount_out + 1;
        end else begin
            hcount = hcount_out + 1;
        end
    end
    */

    always_ff @(posedge pixel_clk_in) begin
        if (rst_in) begin
            hcount_out <= 0;
            vcount_out <= 0;
            hcount <= 1; // hcount is ahead
            vcount <= 0;
            vs_out <= 1'b0;
            hs_out <= 1'b0;
            ad_out <= 1'b0;
            nf_out <= 1'b0;
            fc_out <= 6'b0;
        end else begin
            // BAD VERSION part 2
            /* 
            hcount_out <= hcount;
            vcount_out <= vcount;
            */

            // GOOD VERSION
            // /*
            if (hcount == TOTAL_PIXELS - 1) begin
                hcount <= 0;
                vcount <= (vcount == TOTAL_LINES - 1) ? 0 : vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end
            if (hcount_out == TOTAL_PIXELS - 1) begin
                hcount_out <= 0;
                vcount_out <= (vcount_out == TOTAL_LINES - 1) ? 0 : vcount_out + 1;
            end else begin
                hcount_out <= hcount_out + 1;
            end
            // */

            ad_out <= (hcount < ACTIVE_H_PIXELS && vcount < ACTIVE_LINES);
            hs_out <= (hcount >= ACTIVE_H_PIXELS + H_FRONT_PORCH && hcount < TOTAL_PIXELS - H_BACK_PORCH);
            vs_out <= (vcount >= ACTIVE_LINES + V_FRONT_PORCH && vcount < TOTAL_LINES - V_BACK_PORCH);
            nf_out <= (hcount == ACTIVE_H_PIXELS && vcount == ACTIVE_LINES);
            if (hcount == ACTIVE_H_PIXELS && vcount == ACTIVE_LINES) begin
                nf_out <= 1'b1;
                fc_out <= (fc_out == FPS - 1) ? 6'b0 : fc_out + 1;
            end else begin
                nf_out <= 1'b0;
            end
        end
    end
endmodule