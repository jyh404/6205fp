module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/jyh404/6.205/6205fp/sim_build/emin.fst");
    $dumpvars(0, emin);
end
endmodule
