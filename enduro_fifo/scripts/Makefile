#--------------------------------------------------------------------------
# ------------------------------ TARGET LIST ------------------------------
#--------------------------------------------------------------------------


all:
#--------------------------------------------------------------------------
# This is the default target - execute all targets
#--------------------------------------------------------------------------
	make rtl
	make sim
	make syn


rtl:
#--------------------------------------------------------------------------
# Compile the rtl model
#--------------------------------------------------------------------------
	vivado -mode batch -source ../scripts/run_vivado_rtl.tcl


sim:
#--------------------------------------------------------------------------
# Start simulation
#--------------------------------------------------------------------------
	vivado -mode batch -source ../scripts/run_vivado_sim.tcl


#--------------------------------------------------------------------------
# Run synthesis
#--------------------------------------------------------------------------
syn:
	vivado -mode batch -source ../scripts/run_vivado_syn.tcl
