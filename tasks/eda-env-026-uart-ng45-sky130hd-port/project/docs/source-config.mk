export PLATFORM               = nangate45

export DESIGN_NICKNAME        = uart
export DESIGN_NAME            = uart

export VERILOG_FILES = $(WS)/src/uart/uart.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 45
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export PLACE_DENSITY            = 0.45
export TNS_END_PERCENT          = 100
