# 128-bit Combinational Low Latency Signed Integer Multiplier

A 128-bit signed fully combinational integer multiplier built **from scratch (from full and half adders)** for FPGA implementation. The design fully avoids behavioral arithmetic operators(+, -).

## Architecture
* **Booth Encoding:** Radix-4 Booth encoding handles the initial partial product generation and reduces the matrix height by half. Implements a hardwired modified sign extension to eliminate wide sign-extension bits.
* **Reduction Tree:** A 10-stage Dadda tree compresses the 64 partial products down to two final rows. 
* **Kogge-Stone:** A 256-bit Kogge-Stone parallel prefix adder computes the final sum. 

## Hardware generation scripts

Because the dadda tree needs to accumulate 64 large width numbers, thousands of wires and adders need to be managed. therefore a python scripts is made to programmatically generate the system verilog file. check `simulations/python_src/` for the files.

The free edition of Questa simulator only allows a limited number of module instantiations so had to flatten the hierarchy and have the full and half adder logic directly in the `mult_128.sv`.

similar python script is made for the final kogge stone adder.



## Performance measurements
Synthesized and routed on an Intel Cyclone V FPGA (5CSEBA6U23I7). The design uses register boundary isolation to accurately measure the combinational delay of the mathematical operations. The frequency (or critical delay) values might not be the full picture because i didn't assign any pins and default pin assignments add significant delays to the module. still working on that...

the questa project files are in `quartus_22_1_project` folder. as the name suggest need **quartus prime lite version 22.1**.

if you perform tests in other architectures and would like to share data feel free to modify this section of the README and submit a pull request including the project folder named with the specific tool version used.

* **Max Frequency (Fmax):** 45.12 MHz (Slow 1100mV 100C Model)
* **Minimum Clock Period:** 22.16 ns


## Current progress and how to run
The module is fully developed and verified for 128 bit signed integer multiplication. the testbenches and the scripts to run the testbenches are available in `simulations/tb` and `simulations/scripts`. please note that i made the scripts for questa sim in windows. 

>to run the simulation, open terminal in the parent folder (`int-multiplier-rtl`):
>
>1) to compile only: `.\simulations\scripts\sim.ps1 -comp_only`
>2) to run testbench: `.\simulations\scripts\sim.ps1`


## Things yet to do...
Need to make a wrapper to input any lower bit width and sign extend and pass into the multiplier. additionally need to test performance on newer Agilex 5 FPGA architectures.


