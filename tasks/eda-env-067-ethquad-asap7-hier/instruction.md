# Build this design as blocks on ASAP7

This project is a four-MAC Ethernet cluster (`ethquad`) on the ASAP7
platform. The flow completes as given, but as a single flat partition.
The build specification for this design mandates hierarchy: the
`ethmac` module must be implemented ONCE through the flow as a reusable
hard block, and the top level must be assembled with
those blocks placed as macros.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`), the constraints (`constraint.sdc`, read-only), and a
child configuration for block builds (`block.mk`) — the flow's
recursive block builds read `block.mk` from your workspace, and it IS
editable in this task. The design RTL is frozen in the image; you may
not edit it or change which source files the design reads.

Goal: deliver a setup whose FULL flow produces a clean ASSEMBLED
top-level layout: all four MAC instances present as placed macros of the one block in the
final top layout, with their signal pins connected and their power
pins on the power grid; worst setup slack >= 0 at the 1000 ps clock of
`constraint.sdc`, and zero routing DRC violations.

Rules and mechanics:

- Edit `/workspace/config.mk` and `/workspace/block.mk` values freely.
  To modify a flow stage script, place your copy under
  `/workspace/flow/scripts/` — your copy is used for that stage. Hook
  Tcl files go under `/workspace/hooks/`.
- You may NOT edit `constraint.sdc`, the design RTL, or which source
  files the design reads.
- Run the flow with: `orfs-agent-run finish` (or any make target, e.g.
  `orfs-agent-run synth`). It picks up your `config.mk` AND any stage-script
  copies you placed under `/workspace/flow/scripts/`. Flow outputs land
  under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/asap7/ethquad/base/6_finish.rpt`. Every metric is
  in `/tmp/orfs-work/logs/asap7/ethquad/base/6_report.json`. Routing DRC
  violations are listed in
  `/tmp/orfs-work/reports/asap7/ethquad/base/5_route_drc.rpt` (an empty file
  means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/ethquad/base/`.
- A full flow run takes roughly 10-25 minutes.
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
  `config.mk`, `block.mk`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch
  files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
