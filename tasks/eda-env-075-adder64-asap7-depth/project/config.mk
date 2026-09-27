# adder64 @ asap7 — F12 recipe-only given: the WORKING stock recipe.
# The flow completes and closes its own 400 ps flow clock; the
# trapped eval clock is tighter, and the stock synthesis recipe does
# not reach it.
export PLATFORM               = asap7

export DESIGN_NICKNAME        = adder64
export DESIGN_NAME            = adder64

export VERILOG_FILES = $(WS)/src/adder64/adder64.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export TNS_END_PERCENT        = 100
