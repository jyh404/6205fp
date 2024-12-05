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


with open(Path(__file__).parent/"440hz_stud.txt") as z:
    fft_input = z.read().split("\n")[1000:1512]
fft_input = [int(format((int(inp)<<24),"032b"),2)-(1<<31)  for inp in fft_input]
#print(fft_input)

@cocotb.test()
async def test_a(dut):
    """cocotb test for windowed_fft module, just fft for now"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,1)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,3)
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
        if dut.output_valid.value == 1:
            break
    dut._log.info("Outputs begin")
    outputs = []
    for i in range(512):
        assert dut.output_valid.value == 1
        #out_re = dut.fft_output_re.value
        #out_im = dut.fft_output_im.value
        #outputs += [(out_re,out_im)]
        outputs += [(dut.output_valid.value,dut.wfft_result.value)]
        await ClockCycles(dut.clk_in,1)

    dut._log.info("Outputs finished, writing to file")
    
    with open(Path(__file__).parent/"simulation_output.txt","w") as z:
        for i in range(512):
            #undoing the bit-reverse input garbage
            j = format(i,"09b")
            j = j[::-1]
            j = int(j,2)
            #print(j)
            z.write(str(outputs[i])+"\n")
            #i to ignore bit reverse
            #j to correct it


def is_runner():
    """FFT Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "windowed_fft.sv"]
    
    sources += [proj_path / "hdl" / "FFT512_32B.v"]
    sources += [proj_path / "hdl" / "SdfUnit_TC.v"]
    sources += [proj_path / "hdl" / "SdfUnit2.v"]
    sources += [proj_path / "hdl" / "Twiddle512_32B.v"]
    sources += [proj_path / "hdl" / "Butterfly.v"]
    sources += [proj_path / "hdl" / "DelayBuffer.v"]
    sources += [proj_path / "hdl" / "Multiply.v"]
    sources += [proj_path / "hdl" / "TwiddleConvert8.v"]
    sources += [proj_path / "hdl" / "Multiply_Real.v"]
    sources += [proj_path / "hdl" / "HammingWindow.v"]
    sources += [proj_path / "hdl" / "sqrt.sv"]
    
    
    build_test_args = []
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="windowed_fft",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="windowed_fft",
        test_module="test_fft",
        test_args=run_test_args,
        waves=True #magic trick
    )

if __name__ == "__main__":
    is_runner()
