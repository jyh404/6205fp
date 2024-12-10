module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/jyh404/6.205/6205fp/sim_build/f.fst");
    $dumpvars(0, f);
end
endmodule
