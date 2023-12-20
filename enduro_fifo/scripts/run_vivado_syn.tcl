
# Set top level module
set design_top enduro_fifo_top

# the output directory
set outputDir ./fifo_output_syn 
file mkdir $outputDir

# RTL files
add_files -fileset ../scripts/rtl.filelist

# Sumthesis constraint file
read_xdc ../scripts/enduro_fifo_top.xdc

# Run synthesis
synth_design -top $design_top -part xc7k70tfbg676-2 -flatten_hierarchy none -lint

# Write design checkpoint
write_checkpoint -force $outputDir/post_synth.dcp

# Report timing
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt

# Report utilization estimates
report_utilization -file $outputDir/post_synth_util.rpt

# Report power
report_power -file $outputDir/post_synth_power.rpt

# Report on clock timing paths and unclocked registers (potentially can identify metastability issues)
report_clock_interaction -delay_type min_max -file $outputDir/post_synth_clock_interaction.rpt

# Report the fanout of nets 
report_high_fanout_nets -fanout_greater_than 200 -max_nets 50 -file $outputDir/post_synth_high_fanout_nets.rpt

# Optimize the synthesized netlist for the target part
opt_design

# Save the postsynthesis netlist
write_verilog -force $outputDir/enduro_fifo_top_postsyn_netlist.v -sdf_anno true
