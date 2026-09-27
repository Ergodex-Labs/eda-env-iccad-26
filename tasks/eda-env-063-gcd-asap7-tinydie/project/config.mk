# gcd @ asap7 — F8 given: the utilization-derived die is smaller than
# the power grid's strap pitch.
export PLATFORM               = asap7

export DESIGN_NAME            = gcd
export DESIGN_NICKNAME        = gcd

export VERILOG_FILES          = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NAME)/*.v))
export SDC_FILE               = $(WS)/constraint.sdc

export CORE_UTILIZATION         = 99
export CORE_ASPECT_RATIO        = 1
export CORE_MARGIN              = 0.5
export PLACE_DENSITY            = 0.35
export TNS_END_PERCENT          = 100
