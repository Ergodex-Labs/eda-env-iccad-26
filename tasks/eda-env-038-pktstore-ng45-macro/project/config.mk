# pktstore @ nangate45 — F5 macro-integration given: a WORKING macro-less
# recipe. The banks are behavioral flop arrays (src/pktstore/spram_256x32.v),
# so the flow completes and closes timing, but the memory spec of the task
# (two fakeram45_256x32 SRAM macros) is not met.
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = pktstore
export DESIGN_NAME            = pktstore

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/pktstore/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

# The behavioral banks are 8192 bits each; the platform default cap
# (4096) would refuse to synthesize them. The macro-less recipe is a
# WORKING baseline by family contract, so the cap is raised here.
export SYNTH_MEMORY_MAX_BITS    = 32768

export CORE_UTILIZATION         = 45
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
