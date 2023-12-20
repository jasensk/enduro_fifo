Asynchronous AX4-Stream FIFO block

Short description of the repository:
1. All RTL files written in SystemVerilog are located in rtl/ directory. Please, note that for reusability purposes and for good coding practices decided to add few more primary input parameters on top of the data width.
2. The synthesis constraints file for Vivado Design Suite Standard is located in scripts/ directory.
3. The Makefile is located in sim/ directory. The Makefile has 3 targets (rtl, sim and syn), which needs to be run in sim/ directory
4. Three .tcl scripts are located in scripts/ directory. They can eventually be used to run rtl compilation, simulation and synthesis with Vivado Design Suite Standard.
5. A simple basic direct testbench can be found in verif/ directory. It can be use just for initial sanity check.
