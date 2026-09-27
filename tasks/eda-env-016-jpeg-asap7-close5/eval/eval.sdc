# JPEG ASAP7 candidate at the published ICCAD-2025 nominal period.
set_units -time ps -capacitance fF -resistance kOhm -voltage V -current mA -power pW
current_design jpeg_encoder
set clk_period 560.5
create_clock [get_ports {clk}] -name clk -period $clk_period \
  -waveform [list 0 [expr {$clk_period / 2.0}]]
set_clock_uncertainty [expr {$clk_period * 0.05}] [get_clocks {clk}]
set non_clock_inputs [all_inputs]
foreach control [get_ports {clk rst}] {
  set control_idx [lsearch $non_clock_inputs $control]
  if {$control_idx >= 0} {
    set non_clock_inputs [lreplace $non_clock_inputs $control_idx $control_idx]
  }
}
set_input_delay [expr {$clk_period * 0.2}] -clock clk $non_clock_inputs
set_output_delay [expr {$clk_period * 0.2}] -clock clk [all_outputs]
set_false_path -from [get_ports {rst}]
set_clock_gating_check -rise -setup 0
set_clock_gating_check -fall -setup 0
set_wire_load_mode enclosed
