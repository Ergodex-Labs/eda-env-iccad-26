export PLATFORM               = asap7

export DESIGN_NICKNAME        = systolic
export DESIGN_NAME            = systolic

export VERILOG_FILES = $(WS)/src/systolic/systolic.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export PLACE_DENSITY            = 0.50
export TNS_END_PERCENT          = 100
