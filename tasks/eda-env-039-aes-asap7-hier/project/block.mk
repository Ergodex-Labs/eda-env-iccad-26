# Shared child config for the block builds (ORFS BLOCKS convention:
# block.mk next to the parent config; the recursive make reads it for
# every block). Baseline values from the platform's own aes-block
# reference. Paths are $(FLOW)-relative — the recursive make runs in
# the flow directory.
export PLATFORM               = asap7

export VERILOG_FILES = $(sort $(wildcard ./designs/src/aes/*.v))
export SDC_FILE      = ./designs/$(PLATFORM)/aes/constraint.sdc

export ABC_AREA               = 1

export CORE_UTILIZATION       = 40
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export PLACE_DENSITY          = 0.70

export MAX_ROUTING_LAYER      = M5

export PLACE_PINS_ARGS = -annealing

export PDN_TCL                = $(PLATFORM_DIR)/openRoad/pdn/BLOCK_grid_strategy.tcl
