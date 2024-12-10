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
    """cocotb test for Emin module at i = 1"""
    i = 1
    T = 30 # run for long time, see what happens
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    dut.input_valid.value = 0
    await ClockCycles(dut.clk_in,3)

    dut.rst_in.value = 0
    dut.i.value = i
    dut.input_valid.value = 1

    T_BRAM_queue = [
        [tobit32(0), tobit32(0), tobit32(0)]
    ] # use a queue to fake BRAM with two cycle delay

    for _ in range(T):
        # pretend that BRAM has responded
        # assume that T values are all the same and equivalent to index i
        # we respond 1 cycle later for BRAM since assignment only occurs on next
        # rising edge to register; this should be equivalent to
        # actual BRAM (in terms of saving to T[i] occurs two cycles later)
        if (dut.T_req.value.is_resolvable):
            T_BRAM_queue.append(
                [
                    tobit32(dut.T_req.value.integer * 0),
                    tobit32(dut.T_req.value.integer * 1 * (1<<16)),
                    tobit32(dut.T_req.value.integer * 2 * (1<<16))
                ]
            )
        else:
            T_BRAM_queue.append(
                [
                    tobit32(0),
                    tobit32(0),
                    tobit32(0)
                ]
            )
        dut.T_resp.value = T_BRAM_queue[0]
        T_BRAM_queue.pop(0)
        dut._log.info(f"NEW CYCLE")
        dut._log.info(f"state: {dut.state.value}")
        dut._log.info(f"delay: {dut.delay.value}")
        dut._log.info(f"T_resp[0]: {dut.T_resp[0].value}")
        dut._log.info(f"T_resp[1]: {dut.T_resp[1].value}")
        dut._log.info(f"T_resp[2]: {dut.T_resp[2].value}")
        dut._log.info(f"T_i[0]: {dut.T_i[0].value}")
        dut._log.info(f"T_i[1]: {dut.T_i[1].value}")
        dut._log.info(f"T_i[2]: {dut.T_i[2].value}")
        dut._log.info(f"stage2j: {dut.stage2j.value}")
        dut._log.info(f"r0: {dut.r0.value}")
        dut._log.info(f"r1: {dut.r1.value}")
        dut._log.info(f"r2: {dut.r2.value}")
        for a in range(9):
            dut._log.info(f"a_factor[{a}]: {dut.a_factor[a].value}")
            dut._log.info(f"b_factor[{a}]: {dut.b_factor[a].value}")
            dut._log.info(f"mult_res[{a}]: {dut.mult_res[a].value}")
        dut._log.info(f"alpha_k_num: {dut.alpha_k_num.value}")
        dut._log.info(f"beta_k_num: {dut.beta_k_num.value}")
        dut._log.info(f"denom: {dut.denom.value}")
        dut._log.info(f"T_req: {dut.T_req.value}")
        dut._log.info(f"j_reg: {dut.j_reg.value}")
        dut._log.info(f"valid_pipeline: {dut.valid_pipeline.value}")
        dut._log.info(f"j_out: {dut.j_out.value}")
        dut._log.info(f"data_out: {dut.data_out.value}")
        dut._log.info(f"output_valid: {dut.output_valid.value}")
        await ClockCycles(dut.clk_in, 1)

def is_runner():
    """Emin function Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))

    sources = [proj_path / "hdl" / "Emin.sv"]
    sources += [proj_path / "hdl" / "divider4.sv"]
    sources += [proj_path / "hdl" / "Multiply_Real.v"]
    
    build_test_args = []
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="emin",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="emin",
        test_module="test_emin",
        test_args=run_test_args,
        waves=True #magic trick
    )

if __name__ == "__main__":
    is_runner()
