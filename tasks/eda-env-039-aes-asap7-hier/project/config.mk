# aes @ asap7 — F9 hierarchical given: a WORKING FLAT recipe. The flow
# completes as a single-partition build, but the task mandates the
# design be built as blocks (aes_rcon, aes_sbox) implemented through
# the flow and assembled at top — the flat result has no block macros.
#
# Knob set == the platform's aes-block parent MINUS the hierarchy
# variables, so the witness (which restores exactly those variables)
# reproduces the feasibility-spike context. Classic HDL frontend
# deliberately (run-1c finding: the SYN path width-checks blackboxed
# modules against block abstracts that carry PG pins).
export PLATFORM               = asap7

export DESIGN_NAME            = aes_cipher_top
export DESIGN_NICKNAME        = aes

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v))
export SDC_FILE      = $(WS)/constraint.sdc

export ABC_AREA               = 1

export CORE_UTILIZATION       = 47
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2
