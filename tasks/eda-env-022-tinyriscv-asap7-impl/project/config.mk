export PLATFORM               = asap7

export DESIGN_NICKNAME        = tinyriscv
export DESIGN_NAME            = tinyriscv

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/tinyriscv/*.v))
export VERILOG_INCLUDE_DIRS = $(WS)/src/tinyriscv
export SDC_FILE      = $(WS)/constraint.sdc
