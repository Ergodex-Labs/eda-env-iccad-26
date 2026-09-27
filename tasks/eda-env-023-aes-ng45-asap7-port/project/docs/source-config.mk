# aes @ nangate45 — freeze-replica inputs (DataIn/aes_cipher_top/NG45):
# fixed floorplan DEF + the freeze SDC (0.5 ns, ICCAD-2025 nominal).
# The image ships aes only for asap7; RTL comes from designs/src/aes.
export PLATFORM               = nangate45

export DESIGN_NAME            = aes_cipher_top
export DESIGN_NICKNAME        = aes

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

# Free floorplan (009 redesign): on a FIXED floorplan the area metric
# saturates to the constant row area (filler-inclusive gater sum) — an
# area task needs the floorplan to scale with the netlist.
export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export PLACE_DENSITY_LB_ADDON = 0.20
export TNS_END_PERCENT        = 100
