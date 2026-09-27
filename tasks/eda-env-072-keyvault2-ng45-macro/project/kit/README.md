# Macro kit — fakeram45_256x32 (Nangate45)

Contents:

- `fakeram45_256x32.v` — behavioral model of the SRAM macro. It states
  the port contract: control pins are ACTIVE-LOW (`ce_in`, `we_in`),
  writes are masked by `w_mask_in`, and reads have a 1-cycle latency.
  The flow does not read this file; it is the reference for integration
  and for simulation.

Physical views (already installed in the platform):

- `$(PLATFORM_DIR)/lef/fakeram45_256x32.lef`
- `$(PLATFORM_DIR)/lib/fakeram45_256x32.lib`

The flow needs both views declared in `config.mk` (`ADDITIONAL_LEFS`,
`ADDITIONAL_LIBS`): the liberty file makes synthesis treat the macro as
a black box, and the LEF gives placement its physical footprint.
