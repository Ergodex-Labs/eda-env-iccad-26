# pktstore @ nangate45 — F8 given: synthesis refuses the design's
# behavioral memories under the platform default cap.
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = pktstore
export DESIGN_NAME            = pktstore

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/pktstore/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 45
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
