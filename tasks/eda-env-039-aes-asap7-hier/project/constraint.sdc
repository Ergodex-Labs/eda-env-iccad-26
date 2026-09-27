set clk_name clk
set clk_port_name clk
set clk_period 450

# Match the platform budget style (optimization targets only — see the
# rationale in $PLATFORM_DIR/constraints.sdc).
set in2reg_max [expr { $clk_period * 0.8 }]
set reg2out_max [expr { $clk_period * 0.8 }]
set in2out_max [expr { $clk_period * 0.6 }]

source $::env(PLATFORM_DIR)/constraints.sdc
