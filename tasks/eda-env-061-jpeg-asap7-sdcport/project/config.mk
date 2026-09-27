# jpeg @ asap7 — RTL-based (the image's asap7/jpeg dir is the NETLIST-input
# AutoTuner variant, which kills the synthesis levers). Freeze-replica
# inputs (DataIn/jpeg_encoder/ASAP7): fixed floorplan DEF + freeze SDC
# (400 ps, ICCAD-2025 nominal). RTL from designs/src/jpeg.
export PLATFORM               = asap7

export DESIGN_NAME            = jpeg_encoder
export DESIGN_NICKNAME        = jpeg

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export VERILOG_INCLUDE_DIRS = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/include
export SDC_FILE      = $(WS)/constraint.sdc

export FLOORPLAN_DEF = $(WS)/floorplan.def
export TNS_END_PERCENT        = 100
