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

fft_values = [1, 131072, 101070, 7692387, 39903169, 25874004, 1359834, 7053950, 79806338, 87029429, 12937002, 9147841, 268435456, 536870912, 159612677, 3526975, 56431603, 246156398, 123078199, 4987896, 16777216, 112863206, 87029429, 4573920, 12937002, 146365470, 268435456, 47453132, 3526975, 36591367, 87029429, 36591367, 1048576, 1048576, 4194304, 1763487, 77935, 55108, 110217, 285870, 11585, 11585, 19483, 169979, 8192, 11585, 8192, 23170, 8192, 32768, 23170, 92681, 38967, 11585, 1, 1, 32768, 4096, 8192, 27554, 77935, 4096, 27554, 27554, 110217, 11585, 1, 8192, 4096, 4096, 35733, 1, 8192, 19483, 4096, 46340, 1, 1, 4096, 1, 4096, 131072, 84989, 32768, 19483, 71467, 404281, 262144, 262144, 2493948, 4987896, 1482910, 11585, 142935, 110217, 131072, 92681, 11585, 131072, 202140, 131072, 71467, 50535, 38967, 27554, 8192, 27554, 60096, 38967, 19483, 19483, 77935, 202140, 110217, 16384, 169979, 1048576, 571740, 1246974, 9975792, 16777216, 4194304, 11585, 55108, 440871, 571740, 65536, 50535, 262144, 285870, 285870, 92681, 65536, 65536, 4096, 19483, 142935, 155871, 11585, 27554, 11585, 1, 16384, 110217, 77935, 8192, 4096, 8192, 11585, 46340, 71467, 4096, 55108, 71467, 1, 16384, 65536, 185363, 370727, 285870]

@cocotb.test()
async def test_a(dut):
    """cocotb test for formant module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    dut.fft_valid = 0
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0
    for i in range(160): #input
        dut.fft_valid.value = 1
        dut.fft_data.value = fft_values[i]
        dut._log.info(" fft_valid: "+str(dut.fft_valid.value))
        dut._log.info(" fft_data: "+str(dut.fft_data.value))
        dut._log.info(" Address: "+str(dut.T_write_address.value))
        dut._log.info(" Sums: "+str(dut.T_input_data.value))
        dut._log.info(" Valid: "+str(dut.T_input_data_valid.value))
        await ClockCycles(dut.clk_in,1)
    print("************************************\n\n\nALL INPUTS GIVEN \n\n************************************")
    for i in range(5): #wait
        dut.fft_valid.value = 0
        dut.fft_data.value = 0
        dut._log.info(" Address: "+str(dut.T_write_address.value))
        #dut._log.info(" Sums: "+str(dut.T_input_data.value))
        #dut._log.info(" Valid: "+str(dut.T_input_data_valid.value))
        #dut._log.info(" State: "+str(dut.state_tracker.value))
        dut._log.info(" E writing: "+str(dut.E_input_data_valid.value))
        dut._log.info(" T address: "+str(dut.T_read_address.value))
        dut._log.info(" Analyzed i: " + str(dut.current_i.value))
        dut._log.info(" E in valid: " + str(dut.emin_input_valid.value))
        await ClockCycles(dut.clk_in,1)
    print("************************************\n\n\nT FINISHED \n\n************************************")

    # raise AssertionError
    which_state = 0
    for i in range(100000):
        #dut._log.info(" State: "+str(dut.state_tracker.value))
        """
        if (which_state == 2 and dut.E_input_data_valid.value==1):
            dut._log.info(" i/current_i: "+str(dut.current_i.value))
            #dut._log.info(" input_valid/emin_input_valid: "+str(dut.emin_input_valid.value))
            #dut._log.info(" T_resp/T_output[0]: "+str(dut.T_output_data.value))
            #dut._log.info(" State: "+str(dut.state_tracker.value))
            #dut._log.info(" T address: "+str(dut.T_read_address.value))
            dut._log.info(" E write address: "+str(dut.E_write_address.value))
            dut._log.info(" E data: "+str(dut.E_input_data.value))
            dut._log.info(" E writing: "+str(dut.E_input_data_valid.value))
            print("-----------------------1 CLOCK CYCLE-----------------------")
        """


        #check all I/O from f
        #if (which_state == 3):
        if (which_state == 3 and dut.f_output_valid.value==1):
            pass # sorry silenced output so that it can run faster
        # #if (which_state == 3 and dut.f_iter_done.value==1):
        #     #dut._log.info(" f_begin_iter "+str(dut.f_begin_iter.value))
        #     dut._log.info(" i/current_i "+str(dut.current_i.value))
        #     #dut._log.info(" e_prev/E_output_data "+str(dut.E_output_data.value))
        #     #dut._log.info(" f_prev/F_output_data "+str(dut.F_output_data.value))        
        #     #dut._log.info(" k_req/k_req_begin "+str(dut.k_req_begin.value))
        #     #dut._log.info(" j_req/j_req "+str(dut.j_req.value))
        #     #dut._log.info(" k_write/k_write "+str(dut.k_write.value))
        #     dut._log.info(" f_data/F_input_data "+str(dut.F_input_data.value))
        #     dut._log.info(" b_data/B_input_data "+str(dut.B_input_data.value))
        #     #dut._log.info(" output_valid/f_output_valid "+str(dut.f_output_valid.value))
        #     dut._log.info(" iter_done/f_iter_done "+str(dut.f_iter_done.value))
        #     print("-----------------------1 CLOCK CYCLE-----------------------")
        which_state = dut.state_tracker.value
        await ClockCycles(dut.clk_in,1)

        if (which_state == 4):
            print("F and B finished.")
            break
#currently finishes completely at 78295 cycles
        
    for i in range(100):
        dut._log.info(" segment_values/the good stuff "+str(dut.segment_values.value))
        dut._log.info(" segment "+str(dut.segment.value))
        dut._log.info(" B_output_data "+str(dut.B_output_data.value))
        dut._log.info(" B_read_address " + str(dut.B_read_address.value))
        dut._log.info(" delay "+str(dut.delay.value))
        if (which_state == 5):
            print("SEGMENT complete, moving to PHI_CALC")
            break
        print("-----------------------1 CLOCK CYCLE-----------------------")
        await ClockCycles(dut.clk_in,1)
        which_state = dut.state_tracker.value

    for i in range(1000):
        #dut._log.info(" T_vals/T_output_data " + str(dut.T_output_data.value))
        #dut._log.info(" T_read_address " + str(dut.T_read_address.value))
        #dut._log.info(" input_start/phi_input_start " + str(dut.phi_input_start.value))
        #dut._log.info(" input_valid/phi_input_valid " + str(dut.phi_input_valid.value))
        #dut._log.info(" output_data " + str(dut.phi_output.value))
        if dut.phi_input_valid.value == 1:
            dut._log.info(" input data from T " + str(dut.T_output_data.value))
        dut._log.info(" debug_to_acos " + str(dut.debug_to_acos.value))
        if dut.phi_output_valid.value == 1:
            dut._log.info(" output_valid " + str(dut.phi_output_valid.value))
            dut._log.info(" output_data " + str(dut.phi_output.value))
            dut._log.info(" formant 1 " + str(int(str(dut.phi_output.value)[-1:-31], 2)))
            break
        #print("-----------------------1 CLOCK CYCLE-----------------------")
        await ClockCycles(dut.clk_in,1)
        which_state = dut.state_tracker.value


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
    sources += [proj_path / "hdl" / "CosineLookup.sv"]
    sources += [proj_path / "hdl" / "Multiply_Real.v"]
    sources += [proj_path / "hdl" / "Multiply_Real_extrashift.v"]
    sources += [proj_path / "hdl" / "Emin.sv"]
    sources += [proj_path / "hdl" / "T.sv"]
    sources += [proj_path / "hdl" / "F.sv"]
    sources += [proj_path / "hdl" / "phi.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    sources += [proj_path / "hdl" / "acos.sv"]
    sources += [proj_path / "hdl" / "divider2.sv"]
    sources += [proj_path / "hdl" / "divider3.sv"]
    
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
