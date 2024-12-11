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

TAG = "phi"

test_data = [
 [7676740.0392966970, 7465928.6800850965, 6846390.899481758],
 [11719292.361691387, 11240274.798456930, 9853506.503504550],
 [15773416.471161013, 14738154.012597336, 11840052.53840149],
 [15845682.369966634, 14724785.495262526, 11773938.94613662],
 [16085847.938818932, 14552764.993609684, 11782283.71480135]]

"""
EXPECTED:
ak/bk/theta (acos not done yet)
1.9419951786458125 -0.9968302381643053 0.9725413983805323
1.8640690529123913 -0.9965303770831017 0.9336570602126669
1.721624823194193 -0.9954035791050597 0.8627998748925602
-0.3667842214856589 -0.9827173627073321 -0.1850047307354046
-1.4197271095101778 -0.9821449512957314 -0.7163160892444307

"""

test_data = [[int(i) for i in t] for t in test_data]

@cocotb.test()
async def test_a(dut):
    """cocotb test for phi module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in = 0
    await ClockCycles(dut.clk_in,3)
    dut.input_start = 1 #flare/pulse
    dut.input_valid = 0
    await ClockCycles(dut.clk_in,1)
    dut.input_start = 0
    await ClockCycles(dut.clk_in,4)
    for i in range(5):
        dut.T_vals = test_data[i]
        dut.input_valid = 1
        await ClockCycles(dut.clk_in,1)
        dut.input_valid = 0
        await ClockCycles(dut.clk_in,1)
        dut._log.info(" Inputs: "+str(dut.T_vals.value))
        dut._log.info(" T_vals seen: "+str(dut.T_vals_seen.value))
    await ClockCycles(dut.clk_in,83) #to align the clock cycle in sim
    dut._log.info(" All seen: "+str(dut.all_seen.value))
    dut._log.info(" Cycle count: "+str(dut.cycle_count.value))
    await ClockCycles(dut.clk_in,240)
    for i in range(100):
        dut._log.info(" Formant index: "+str(dut.formant_index.value))
        #dut._log.info(" All seen: "+str(dut.all_seen.value))
        dut._log.info(" r: " + str(dut.r.value))
        #dut._log.info(" a_in: " + str(dut.a_in.value))
        #dut._log.info(" bnum: " + str(dut.bnum.value))
        #dut._log.info(" abdenom: " + str(dut.abdenom.value))
        #dut._log.info(" full_num: " + str(dut.full_num.value))
        #dut._log.info(" full_denom: " + str(dut.full_denom.value))
        #dut._log.info(" div_num: " + str(dut.div_num.value))
        #dut._log.info(" div_denom: " + str(dut.div_denom.value))
        #dut._log.info(" div_valid: " + str(dut.div_data_valid.value))
        #dut._log.info(" div_sign: " + str(dut.division_sign.value))
        #dut._log.info(" quotient: " + str(dut.quotient.value))
        #dut._log.info(" remainder: " + str(dut.remainder.value))
        #dut._log.info(" to_acos: " + str(dut.to_acos.value))
        #dut._log.info(" acos_val: " + str(dut.acos_data.value))
        dut._log.info(" Output: " + str(dut.output_data.value))
        dut._log.info(" Output valid:" + str(dut.output_valid.value))
        await ClockCycles(dut.clk_in,1)
    #dut._log.info(" All seen: "+str(dut.all_seen.value))
    



def is_runner():
    """FFT Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    filenamehere = TAG+".sv"
    sources = [proj_path / "hdl" / filenamehere]
    sources += [proj_path / "hdl" / "divider2.sv"]
    sources += [proj_path / "hdl" / "Multiply_Real.v"]
    sources += [proj_path / "hdl" / "acos.sv"]
    
    
    
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
