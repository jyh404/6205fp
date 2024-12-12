module tm_choice (
    input wire [7:0] data_in,
    output logic [8:0] qm_out
);
    logic [3:0] onecount;
    logic good;
    always_comb begin
        onecount = $countones(data_in);
        good = (onecount > 4) || (onecount == 4 && !data_in[0]);
        qm_out[0] = data_in[0];
        qm_out[1] = (good) ? qm_out[0] ~^ data_in[1] : qm_out[0] ^ data_in[1];
        qm_out[2] = (good) ? qm_out[1] ~^ data_in[2] : qm_out[1] ^ data_in[2];
        qm_out[3] = (good) ? qm_out[2] ~^ data_in[3] : qm_out[2] ^ data_in[3];
        qm_out[4] = (good) ? qm_out[3] ~^ data_in[4] : qm_out[3] ^ data_in[4];
        qm_out[5] = (good) ? qm_out[4] ~^ data_in[5] : qm_out[4] ^ data_in[5];
        qm_out[6] = (good) ? qm_out[5] ~^ data_in[6] : qm_out[5] ^ data_in[6];
        qm_out[7] = (good) ? qm_out[6] ~^ data_in[7] : qm_out[6] ^ data_in[7];
        qm_out[8] = (good) ? 1'b0 : 1'b1;
    end    
endmodule