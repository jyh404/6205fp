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
from cocotb.binary import BinaryValue

def tobit32(a):
    return BinaryValue(value = a, n_bits = 32, bigEndian = False)

@cocotb.test()
async def test_a(dut):
    """cocotb test for f module at i = 4"""
    # all that seems reasonable is checking non-data outputs
    i = 4
    T = 50 # run for long time, see what happens
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    dut.begin_iter.value = 0

    await ClockCycles(dut.clk_in,3)

    dut.rst_in.value = 0
    dut.i.value = i
    dut.begin_iter = 1

    dut.e_prev.value = 0
    dut.f_prev.value = 0

    await ClockCycles(dut.clk_in, 1)

    dut.begin_iter.value = 0

    await ClockCycles(dut.clk_in, 100)

def is_runner():
    """F function Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))

    sources = [proj_path / "hdl" / "F.sv"]
    
    build_test_args = []
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="f",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="f",
        test_module="test_f",
        test_args=run_test_args,
        waves=True #magic trick
    )

if __name__ == "__main__":
    is_runner()
