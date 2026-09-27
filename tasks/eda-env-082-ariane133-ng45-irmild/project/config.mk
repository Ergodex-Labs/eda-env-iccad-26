# ariane133 @ nangate45 — F6 given: the WORKING macro recipe (the
# admitted 032 witness floorplan/RTLMP values) with a starved power
# grid (PDN_TCL below). Timing and placement are healthy; static IR
# on VDD is not.
export DESIGN_NAME = ariane
export DESIGN_NICKNAME = ariane133
export PLATFORM    = nangate45

export SYNTH_HIERARCHICAL = 1

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/ariane.sv2v.v \
                       $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/macros.v

export SDC_FILE      = $(WS)/constraint.sdc
export PDN_TCL       = $(WS)/pdn.tcl

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram45_256x16.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/fakeram45_256x16.lib

export IO_CONSTRAINTS = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/io.tcl
export CORE_UTILIZATION = 50
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 5
export MACRO_PLACE_HALO    = 8 8
export SKIP_GATE_CLONING   = 1
export RTLMP_MAX_LEVEL = 1
export RTLMP_MAX_MACRO = 30
export RTLMP_MIN_MACRO = 10
export RTLMP_MAX_INST = 80000
export RTLMP_MIN_INST = 8000
export GPL_RANDOM_SEED = 3
export TNS_END_PERCENT = 100
