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

TAG = "formant"

@cocotb.test()
async def test_a(dut):
    """cocotb test for lightweight sqrt module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    dut.fft_valid = 0
    await ClockCycles(dut.clk_in,3)
    for i in range(160):
        dut.fft_valid.value = 1
        dut.fft_data.value = 2**31-1
        dut._log.info(" Address: "+str(dut.output_address.value))
        dut._log.info(" Sums: "+str(dut.output_written.value))
        dut._log.info(" Valid: "+str(dut.output_valid.value))
        await ClockCycles(dut.clk_in,1)
    for i in range(10):
        dut.fft_valid.value = 0
        dut.fft_data.value = 2**31-1
        dut._log.info(" Address: "+str(dut.output_address.value))
        dut._log.info(" Sums: "+str(dut.output_written.value))
        dut._log.info(" Valid: "+str(dut.output_valid.value))
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
    filenamehere = TAG+".sv"
    sources = [proj_path / "hdl" / filenamehere]
    sources += [proj_path / "hdl" / "CosineLookup.v"]
    sources += [proj_path / "hdl" / "Multiply_Real.v"]
    sources += [proj_path / "hdl" / "Emin.sv"]
    sources += [proj_path / "hdl" / "T.sv"]
    sources += [proj_path / "hdl" / "F.sv"]
    sources += [proj_path / "hdl" / "phi.v"]
    
    
    build_test_args = []
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=TAG,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=TAG,
        test_module="test_"+TAG,
        test_args=run_test_args,
        waves=True #magic trick
    )

if __name__ == "__main__":
    is_runner()
