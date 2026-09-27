# ethmac @ nangate45 — Tier-1 port context: the stock ethmac RTL
# (platform-neutral Verilog) on NG45 with the flow SDC on the
# workspace edit surface.
export PLATFORM               = nangate45

export DESIGN_NAME            = ethmac
export DESIGN_NICKNAME        = ethmac

export VERILOG_FILES         = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE              = $(WS)/constraint.sdc

export CORE_UTILIZATION       = 50
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2

export TNS_END_PERCENT        = 100
