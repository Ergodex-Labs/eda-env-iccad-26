# Integrate the provided SRAM macro on Nangate45

This project is a key vault (`keyvault1`) on the Nangate45 platform: it
stores 32 keys of 256 bits (8 words of 32), loads a key as an
8-word stream on the load handshake, and streams a fetched key out on
the fetch handshake. The one storage bank is currently a behavioral flop array
(`src/keyvault1/spram_256x32.v`), and the flow completes as given. The
memory specification for this design, however, requires the storage to
be implemented with the platform SRAM macro `fakeram45_256x32` — one
macro instance per bank, one in total.

A macro kit is provided in `/workspace/kit/`: the behavioral model of
the macro (`fakeram45_256x32.v`, which states the port contract and pin
polarities) and a README that names the platform's physical views
(LEF and liberty) for the macro.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`), the constraints (`constraint.sdc`, read-only), the
frozen top (`src/keyvault1/keyvault1.v`, read-only), and the bank
implementation (`src/keyvault1/spram_256x32.v`) — the bank file IS
editable in this task. Its module interface and behavior must not
change: same module name, same ports, same cycle-level semantics (the
contract is stated in the file header).

Goal: deliver a setup whose FULL flow produces a clean final layout
with the SRAM macro integrated: one
`fakeram45_256x32` instance present, legally placed, with
signal pins connected and power pins on the power grid; worst setup
slack >= 0 at the 1 ns clock of `constraint.sdc`, and zero routing
DRC violations.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`.
- You may NOT edit `keyvault1.v`, `constraint.sdc`, or the kit files, and
  you may not change which source files the design reads.
  `src/keyvault1/spram_256x32.v` IS editable; it must keep its interface
  and cycle-level behavior.
- Run the flow with: `orfs-agent-run finish` (or any make target, e.g.
  `orfs-agent-run synth`). It picks up your `config.mk` AND any stage-script
  copies you placed under `/workspace/flow/scripts/`. Flow outputs land
  under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/nangate45/keyvault1/base/6_finish.rpt`. Every
  metric is in `/tmp/orfs-work/logs/nangate45/keyvault1/base/6_report.json`.
  Routing DRC violations are listed in
  `/tmp/orfs-work/reports/nangate45/keyvault1/base/5_route_drc.rpt` (an
  empty file means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/nangate45/keyvault1/base/`.
- A full flow run takes roughly 5-15 minutes.
  The flow must RUN TO COMPLETION before your session ends: either run
  it in the foreground with a timeout larger than the flow's runtime, or
  — if your shell tool caps foreground timeouts — run it with your
  tool's MANAGED background mechanism and then WAIT for it to finish
  before you end your turn. Any process still running when your session
  ends is killed, and a killed flow leaves you with nothing.
- IMPORTANT: keep your CURRENT BEST setup written into the files of
  `/workspace` at all times, and improve it in place as you go. Only the
  `/workspace` change set is your answer. Work that lives elsewhere (for
  example scratch copies under `/tmp`) is discarded at the end, and an
  answer that was never written into `/workspace` does not exist.
- Your final answer is the change set of `/workspace` on these paths only:
  `config.mk`, `src/keyvault1/spram_256x32.v`, `hooks/*.tcl`,
  `flow/scripts/*.tcl`. Scratch files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
