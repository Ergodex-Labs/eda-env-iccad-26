# icache1 @ nangate45 — F5 macro-integration given: a WORKING
# macro-less recipe. The store is behavioral flop
# array (src/icache1/spram_256x32.v), so the flow completes as
# given, but the memory spec of the task (one fakeram45_256x32
# SRAM macro) is not met.
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = icache1
export DESIGN_NAME            = icache1

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/icache1/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

# Each behavioral bank is 8192 bits; the platform default cap (4096)
# would refuse to synthesize it. The macro-less recipe is a WORKING
# baseline by family contract, so the cap is raised here.
export SYNTH_MEMORY_MAX_BITS    = 32768

export CORE_UTILIZATION         = 45
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
