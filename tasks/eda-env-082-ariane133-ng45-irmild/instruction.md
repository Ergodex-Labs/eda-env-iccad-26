# Repair the power grid on ariane133 @ Nangate45

This project implements a RISC-V application core with 37 SRAM macros
(`ariane133`) on the Nangate45 platform. The flow runs to the end and
timing is met, but the power-delivery network is too weak: static IR
analysis shows an excessive worst-case voltage drop on VDD, and the
chip cannot ship this way.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`), the constraints (`constraint.sdc`, read-only for this
task), and the power-grid strategy (`pdn.tcl`) — the grid strategy IS
editable in this task.

Goal: repair the power delivery so the FULL flow produces a clean final
layout with worst-case static IR drop on VDD within 5.3 mV, while
keeping worst setup slack >= 0 at the 3.6 ns clock, zero routing DRC
violations, and total power within 5% of the given setup.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`.
- You may NOT edit the design RTL or `constraint.sdc`, and you may not
  change which source files the design reads. `pdn.tcl` IS editable.
- Run the flow with: `orfs-agent-run finish` (or any make target).
  Flow outputs land under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/nangate45/ariane133/base/6_finish.rpt`. Every
  metric is in `/tmp/orfs-work/logs/nangate45/ariane133/base/6_report.json`.
  Routing DRC violations are listed in
  `/tmp/orfs-work/reports/nangate45/ariane133/base/5_route_drc.rpt` (an
  empty file means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/nangate45/ariane133/base/`.
- A full flow run takes roughly 45-90 minutes.
  The flow must RUN TO COMPLETION before your session ends: either run
  it in the foreground with a timeout larger than the flow's runtime, or
  — if your shell tool caps foreground timeouts — run it with your
  tool's MANAGED background mechanism and then WAIT for it to finish
  before you end your turn. Any process still running when your session
  ends is killed, and a killed flow leaves you with nothing.
- IMPORTANT: keep your CURRENT BEST setup written into the files of
  `/workspace` at all times. Only the `/workspace` change set is your
  answer.
- Your final answer is the change set of `/workspace` on these paths only:
  `config.mk`, `pdn.tcl`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch files
  elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
