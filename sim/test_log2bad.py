import cocotb
import os
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner


@cocotb.test()
async def test_a(dut):
    """cocotb test for lightweight sqrt module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    await ClockCycles(dut.clk_in,3)
    for i in range(10000,1000000,10000):
        dut.log_in.value = i
        dut._log.info("Input: "+str(dut.log_in.value)+" Output: "+str(dut.log_out.value))
        await ClockCycles(dut.clk_in,1)

    """
    dut.start.value = 1
    dut._log.info("Giving inputs...")
    for i in range(512):
        dut.rst_in.value = 0
        dut.input_sample.value = fft_input[i]
        await ClockCycles(dut.clk_in,1)
        dut.start.value = 0
    dut._log.info("All inputs given")
    while True:
        await ClockCycles(dut.clk_in,1)
        if dut.fft_output_valid.value == 1:
            break
    dut._log.info("Outputs begin")
    outputs = []
    for i in range(512):
        assert dut.fft_output_valid.value == 1
        out_re = dut.fft_output_re.value
        out_im = dut.fft_output_im.value
        outputs += [(out_re,out_im)]
        await ClockCycles(dut.clk_in,1)

    dut._log.info("Outputs finished, writing to file")
    
    with open(Path(__file__).parent/"simulation_output.txt","w") as z:
        for i in range(512):
            #undoing the bit-reverse input garbage
            j = format(i,"09b")
            j = j[::-1]
            j = int(j,2)
            #print(j)
            z.write(str(outputs[j])+"\n")
    """


def is_runner():
    """FFT Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "log2bad.sv"]
    
    
    build_test_args = []
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="log2bad",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="log2bad",
        test_module="test_log2bad",
        test_args=run_test_args,
        waves=True #magic trick
    )

if __name__ == "__main__":
    is_runner()
