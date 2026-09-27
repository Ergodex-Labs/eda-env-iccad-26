# systolic @ nangate45 — F12 depth-rewrite given (recipe misses the
# trapped clock; the PE file is the rewrite surface).
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = systolic
export DESIGN_NAME            = systolic

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/systolic/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
