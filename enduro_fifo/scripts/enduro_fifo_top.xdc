# Clock definitions
create_clock -name s_axis_clk -period 4.0 -waveform {0.000 2.000}  [get_ports s_axis_clk]
create_clock -name m_axis_clk -period 5.0 -waveform {0.000 2.500}  [get_ports m_axis_clk]

# IO delays (30% from the clock period for max delays and 5% for min delays)
set_input_delay –clock s_axis_clk –max 1.2 [get_ports { s_axis_tdata s_axis_tvalid } ]
set_input_delay –clock s_axis_clk –min 0.2 [get_ports { s_axis_tdata s_axis_tvalid } ]
set_input_delay –clock s_axis_clk –max 1.2 [get_ports { s_axis_aresetn } ]
set_input_delay –clock s_axis_clk –min 0.2 [get_ports { s_axis_aresetn } ]
set_input_delay –clock m_axis_clk –max 1.5 [get_ports { m_axis_tready } ]
set_input_delay –clock m_axis_clk –min 0.25 [get_ports { m_axis_tready } ]
set_output_delay –clock s_axis_clk –max 1.2 [get_ports { s_axis_tready } ]
set_output_delay –clock s_axis_clk –min 0.2 [get_ports { s_axis_tready } ]
set_output_delay –clock m_axis_clk –max 1.5 [get_ports { m_axis_tdata m_axis_tvalid } ]
set_output_delay –clock m_axis_clk –min 0.25 [get_ports { m_axis_tdata m_axis_tvalid } ]

# Flase paths
set_false_path -from [get_clocks s_axis_clk] -to [get_clocks m_axis_clk]
set_false_path -from [get_clocks m_axis_clk] -to [get_clocks s_axis_clk]
