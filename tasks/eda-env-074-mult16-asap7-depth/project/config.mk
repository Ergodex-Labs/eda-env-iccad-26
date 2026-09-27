# mult16 @ asap7 — F12 recipe-only given: the WORKING stock recipe.
# The flow completes and closes its own 900 ps flow clock; the
# trapped eval clock is tighter, and the stock synthesis recipe does
# not reach it.
export PLATFORM               = asap7

export DESIGN_NICKNAME        = mult16
export DESIGN_NAME            = mult16

export VERILOG_FILES = $(WS)/src/mult16/mult16.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export TNS_END_PERCENT        = 100
