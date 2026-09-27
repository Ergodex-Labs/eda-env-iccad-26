# fir4 @ asap7 — F12.6 given: a WORKING recipe of the unbalanced
# 4-tap FIR (one deep MAC stage + pass-through tail registers). The
# flow completes and closes its own flow clock; the trapped eval
# clock needs the registers rebalanced.
export PLATFORM               = asap7

export DESIGN_NICKNAME        = fir4
export DESIGN_NAME            = fir4

export VERILOG_FILES = $(WS)/src/fir4/fir4.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export TNS_END_PERCENT        = 100
