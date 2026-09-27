# mpb3 @ asap7 — F8 given: the flow crashes at macro placement: macros plus halos exceed the placeable area.
export PLATFORM               = asap7

export DESIGN_NAME            = mpb_soc3
export DESIGN_NICKNAME        = mpb3

export VERILOG_FILES = $(WS)/src/mpb3/mpb_soc3.v
export SDC_FILE      = $(WS)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram7_256x32.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/NLDM/fakeram7_256x32.lib

export CORE_UTILIZATION       = 80
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export MACRO_PLACE_HALO       = 3 3
export TNS_END_PERCENT        = 100
