# sharound @ nangate45 — F12 depth-rewrite given (recipe misses the trapped
# clock; the granted file is the rewrite surface).
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = sharound
export DESIGN_NAME            = shastep

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/sharound/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
