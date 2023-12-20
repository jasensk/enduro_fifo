
set outputDir ./fifo_output_rtl
file mkdir $outputDir

#create_project project_1 project_1 -part xc7vx485tffg1157-1
add_files -fileset ./sim_and_syn/rtl.filelist

import_files -force -norecurse
update_compile_order
launch_simulation -step { compile elaborate } -verbose
