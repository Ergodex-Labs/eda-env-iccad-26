export PLATFORM               = asap7

export DESIGN_NICKNAME        = sboxpipe
export DESIGN_NAME            = sboxpipe

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/sboxpipe/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 55
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export PLACE_DENSITY            = 0.55
export TNS_END_PERCENT          = 100
