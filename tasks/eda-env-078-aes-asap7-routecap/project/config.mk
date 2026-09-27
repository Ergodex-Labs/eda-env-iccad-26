# aes @ asap7 — F8 given: the router is starved of capacity and the
# flow ends with a mass of routing DRC violations.
export PLATFORM               = asap7

export DESIGN_NAME            = aes_cipher_top
export DESIGN_NICKNAME        = aes

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 70
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export PLACE_DENSITY            = 0.65
export TNS_END_PERCENT          = 100

export SYNTH_USE_SYN            = 1

export FASTROUTE_TCL            = $(WS)/fastroute.tcl
