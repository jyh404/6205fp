module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/c/Users/ivann/Desktop/Main/Work/2024/Fall 2024/6.2050/proj02-fft/sim_build/windowed_fft.fst");
    $dumpvars(0, windowed_fft);
end
endmodule
