# jpeg @ nangate45 — F6 given: the power grid is starved.
export PLATFORM               = nangate45

export DESIGN_NAME            = jpeg_encoder
export DESIGN_NICKNAME        = jpeg

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export VERILOG_INCLUDE_DIRS = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/include
export SDC_FILE      = $(WS)/constraint.sdc
export PDN_TCL       = $(WS)/pdn.tcl

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
