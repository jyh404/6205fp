module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/c/Users/ivann/Desktop/Main/Work/2024/Fall 2024/6.2050/6205fp/hdl/sim_build/log2bad.fst");
    $dumpvars(0, log2bad);
end
endmodule
