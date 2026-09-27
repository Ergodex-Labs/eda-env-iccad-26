# aesround @ asap7 — F12 depth-rewrite given (recipe misses the trapped
# clock; the granted file is the rewrite surface).
export PLATFORM               = asap7

export DESIGN_NICKNAME        = aesround
export DESIGN_NAME            = aesround

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/aesround/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
