# whack-an-engineer
An engineer-themed whack-a-mole game written in Verilog. Originally for the Altera Cyclone V FPGA on Terasic's DE-1 SoC platform. Supports PS/2 keyboard input and VGA display.

Created by: Nicholas Biancolin, Eric Liu, and Jason Zhang

## Installation
If running on the DE-1 SoC platform, the game can be programmed with Quartus Prime onto the FPGA with `output_files/whack_an_engineer.sof`. No re-build necessary!

For other platforms, pin assignments must be changed and the project must be recompiled. Open `whack_an_engineer.qpf` in Quartus Prime (or the CAD tool of your choice) and in `Assignments > Import Assignments`, remove the old assignments then import in your platform-specific mapping. The assignments for Terasic's DE10-Lite are in `config/DE10_LITE.qsf`.

The top-level module is `whack_an_engineer`. Ensure that pin assignments in the module correspond with your platform. You may need to change some names (i.e., `CLOCK_50` to `CLOCK`). When done, re-compile and program onto the FPGA.