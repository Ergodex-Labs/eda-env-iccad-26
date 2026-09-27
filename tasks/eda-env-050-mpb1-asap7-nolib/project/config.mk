# mpb1 @ asap7 — F8 given: the flow fails at synthesis: the SRAM macro has no timing library.
export PLATFORM               = asap7

export DESIGN_NAME            = mpb_soc1
export DESIGN_NICKNAME        = mpb1

export VERILOG_FILES = $(WS)/src/mpb1/mpb_soc1.v
export SDC_FILE      = $(WS)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram7_256x32.lef

export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export MACRO_PLACE_HALO       = 2 2
export TNS_END_PERCENT        = 100
