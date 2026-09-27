# Shared child config for the block build (ORFS BLOCKS convention).
export PLATFORM               = asap7

export VERILOG_FILES = $(sort $(wildcard ./designs/src/ethmac/*.v))
export SDC_FILE      = ./designs/asap7/ethmac/constraint.sdc

export CORE_UTILIZATION       = 55
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export PLACE_DENSITY          = 0.60

export ABC_AREA               = 1

export MAX_ROUTING_LAYER      = M5

export PLACE_PINS_ARGS = -annealing

export PDN_TCL                = $(PLATFORM_DIR)/openRoad/pdn/BLOCK_grid_strategy.tcl
