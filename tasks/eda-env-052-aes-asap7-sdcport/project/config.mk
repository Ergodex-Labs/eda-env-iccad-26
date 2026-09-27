# aes @ asap7 — F8 given: the flow completes, but timing is vacuous: the clock is defined on a port that does not exist.
export PLATFORM               = asap7

export DESIGN_NAME            = aes_cipher_top
export DESIGN_NICKNAME        = aes

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 55
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export PLACE_DENSITY            = 0.55
export TNS_END_PERCENT          = 100
