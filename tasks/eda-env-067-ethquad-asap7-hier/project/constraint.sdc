set clk_period 1000
set clk_io_pct 0.2
create_clock -name wb_clk_i -period 1000 [get_ports wb_clk_i]
create_clock -name vclk_wb_clk_i -period 1000
set_clock_latency 229.195 [get_clocks wb_clk_i]
set_clock_latency 229.195 [get_clocks vclk_wb_clk_i]
set non_clock_inputs [all_inputs -no_clocks]
set_input_delay [expr 1000 * $clk_io_pct] -clock vclk_wb_clk_i $non_clock_inputs
set_output_delay [expr 1000 * $clk_io_pct] -clock vclk_wb_clk_i [all_outputs]
create_clock -name mtx_clk_pad_i_0 -period 300 [get_ports mtx_clk_pad_i_0]
set_clock_latency 55.660 [get_clocks mtx_clk_pad_i_0]
create_clock -name mrx_clk_pad_i_0 -period 300 [get_ports mrx_clk_pad_i_0]
set_clock_latency 76.515 [get_clocks mrx_clk_pad_i_0]
create_clock -name mtx_clk_pad_i_1 -period 300 [get_ports mtx_clk_pad_i_1]
set_clock_latency 55.660 [get_clocks mtx_clk_pad_i_1]
create_clock -name mrx_clk_pad_i_1 -period 300 [get_ports mrx_clk_pad_i_1]
set_clock_latency 76.515 [get_clocks mrx_clk_pad_i_1]
create_clock -name mtx_clk_pad_i_2 -period 300 [get_ports mtx_clk_pad_i_2]
set_clock_latency 55.660 [get_clocks mtx_clk_pad_i_2]
create_clock -name mrx_clk_pad_i_2 -period 300 [get_ports mrx_clk_pad_i_2]
set_clock_latency 76.515 [get_clocks mrx_clk_pad_i_2]
create_clock -name mtx_clk_pad_i_3 -period 300 [get_ports mtx_clk_pad_i_3]
set_clock_latency 55.660 [get_clocks mtx_clk_pad_i_3]
create_clock -name mrx_clk_pad_i_3 -period 300 [get_ports mrx_clk_pad_i_3]
set_clock_latency 76.515 [get_clocks mrx_clk_pad_i_3]
set_clock_groups -name core_clock -logically_exclusive \
  -group [concat [get_clocks wb_clk_i] [get_clocks vclk_wb_clk_i]] \
  -group [get_clocks mtx_clk_pad_i_0] \
  -group [get_clocks mrx_clk_pad_i_0] \
  -group [get_clocks mtx_clk_pad_i_1] \
  -group [get_clocks mrx_clk_pad_i_1] \
  -group [get_clocks mtx_clk_pad_i_2] \
  -group [get_clocks mrx_clk_pad_i_2] \
  -group [get_clocks mtx_clk_pad_i_3] \
  -group [get_clocks mrx_clk_pad_i_3]
set_max_fanout 10 [current_design]
