# ethquad @ asap7 — F9 given: a WORKING FLAT recipe of the four-MAC
# cluster. The task mandates the MAC be implemented once as a reusable
# block and instantiated four times.
export PLATFORM               = asap7

export DESIGN_NAME            = ethquad
export DESIGN_NICKNAME        = ethquad

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/ethmac/*.v)) \
                       $(WS)/src/ethquad/ethquad.v
export SDC_FILE      = $(WS)/constraint.sdc

export CORE_UTILIZATION       = 40
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 4
export TNS_END_PERCENT        = 100
export BLOCKS = ethmac
export SYNTH_BLACKBOXES = ethmac
export SYNTH_HIERARCHICAL = 1
export MACRO_PLACE_HALO = 8 8

export SYNTH_USE_SYN            = 1
