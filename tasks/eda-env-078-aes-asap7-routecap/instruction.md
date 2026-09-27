# Repair the routing on aes @ ASAP7

This project implements an AES cipher core (`aes_cipher_top`) on the
ASAP7 platform. The flow DIES at global route: the router reports
unresolvable congestion (GRT-0116) and never reaches a final
layout. The design team suspects the flow configuration — the routing resources the
router is allowed to use do not look right for this platform.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`, editable) and the constraints (`constraint.sdc`,
read-only).

Goal: repair the flow configuration so that the FULL flow produces a
clean final layout at the 410 ps clock of `constraint.sdc` — worst
setup slack >= 0 and ZERO routing DRC violations.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`.
- You may NOT edit the design RTL or `constraint.sdc`, and you may not
  change which source files the design reads.
- Run the flow with: `orfs-agent-run finish` (or any make target).
  Flow outputs land under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/asap7/aes/base/6_finish.rpt`. Every metric is in
  `/tmp/orfs-work/logs/asap7/aes/base/6_report.json`. Routing DRC violations
  are listed in `/tmp/orfs-work/reports/asap7/aes/base/5_route_drc.rpt` (an
  empty file means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/aes/base/`.
- A full flow run takes roughly 5-15 minutes.
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
  `config.mk`, `fastroute.tcl`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch
  files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
