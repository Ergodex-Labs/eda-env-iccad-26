# mpb_soc8 @ asap7 — F4 given: DEGRADED macro-placement recipe.
# Dose: pin-constrained: single-edge IO. The flow completes but the layout fails sign-off
# (macro crowding -> routing DRCs / timing, per the 036 break class).
export PLATFORM               = asap7

export DESIGN_NAME            = mpb_soc8
export DESIGN_NICKNAME        = mpb8

export VERILOG_FILES = $(WS)/src/mpb8/mpb_soc8.v
export SDC_FILE      = $(WS)/constraint.sdc

export ADDITIONAL_LEFS = $(PLATFORM_DIR)/lef/fakeram7_256x32.lef
export ADDITIONAL_LIBS = $(PLATFORM_DIR)/lib/NLDM/fakeram7_256x32.lib

export CORE_UTILIZATION       = 80
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export MACRO_PLACE_HALO       = 3 3
export TNS_END_PERCENT        = 100
