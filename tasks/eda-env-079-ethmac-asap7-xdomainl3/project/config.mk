# ethmac @ asap7 — stock in-image recipe (util 70, ABC_AREA,
# density 0.75), with the flow SDC moved onto the workspace edit
# surface for the constraint-repair task.
export PLATFORM               = asap7

export DESIGN_NAME            = ethmac
export DESIGN_NICKNAME        = ethmac

export VERILOG_FILES         = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE              = $(WS)/constraint.sdc
export ABC_AREA               = 1

export CORE_UTILIZATION       = 70
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
export PLACE_DENSITY          = 0.75

export HOLD_SLACK_MARGIN      = -10

export TNS_END_PERCENT        = 100
