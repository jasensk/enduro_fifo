
set outputDir ./fifo_output_sim
file mkdir $outputDir

#create_project project_1 project_1 -part xc7vx485tffg1157-1
add_files ./verif/testbench.sv
add_files -fileset ./sim_and_syn/rtl.filelist

import_files -force -norecurse
update_compile_order
launch_simulation -verbose -noclean_dir
log_wave -r /
run 10000ns