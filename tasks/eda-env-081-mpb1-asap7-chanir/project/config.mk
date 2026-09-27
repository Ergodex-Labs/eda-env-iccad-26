# mpb_soc1 @ asap7 — F6 given: the WORKING macro recipe (util 50,
# halo 1 1) with a channel-starved power grid (PDN_TCL below). Timing
# and placement are healthy; static IR on VDD is not.
export PLATFORM               = asap7

export DESIGN_NAME            = mpb_soc1
export DESIGN_NICKNAME        = mpb1

export VERILOG_FILES = $(WS)/src/mpb1/mpb_soc1.v
export SDC_FILE      = $(WS)/constraint.sdc
export PDN_TCL       = $(WS)/pdn.tcl

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram7_256x32.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/NLDM/fakeram7_256x32.lib

export CORE_UTILIZATION       = 50
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export MACRO_PLACE_HALO       = 1 1
export TNS_END_PERCENT        = 100
