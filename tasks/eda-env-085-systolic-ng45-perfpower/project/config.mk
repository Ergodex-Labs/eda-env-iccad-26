# systolic @ nangate45 — F10 perf-power given. Configuration-only task:
# do NOT edit RTL; the tuning surface is config.mk + stage Tcl + hooks.
export PLATFORM               = nangate45

export DESIGN_NICKNAME        = systolic
export DESIGN_NAME            = systolic

export VERILOG_FILES = $(sort $(wildcard $(WS)/src/systolic/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 50
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 2
export TNS_END_PERCENT          = 100
