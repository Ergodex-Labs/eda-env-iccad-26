# Repair a broken flow recipe on ethquad @ ASAP7

This project is a four-MAC Ethernet cluster (`ethquad`) built
hierarchically: the MAC is implemented once as a reusable block and
instantiated four times. The flow recipe is broken: synthesis fails
with a port-width mismatch on the MAC block.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`) and the constraints (`constraint.sdc`, read-only).
Diagnose the failure from the flow's own logs, repair the recipe, and
deliver a working setup.

Goal: a FULL flow that produces a clean final layout with the four
MAC blocks integrated — worst setup slack >= 0 at the 1000 ps clock,
zero routing DRC violations, all four block instances placed and
connected.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`.
- You may NOT edit the design RTL or `constraint.sdc`, and you may not
  change which source files the design reads.
- Run the flow with: `orfs-agent-run finish` (or any make target).
  Flow outputs land under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/asap7/ethquad/base/6_finish.rpt`. Every metric is
  in `/tmp/orfs-work/logs/asap7/ethquad/base/6_report.json`. Routing DRC
  violations are listed in
  `/tmp/orfs-work/reports/asap7/ethquad/base/5_route_drc.rpt` (an empty file
  means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/ethquad/base/`.
- A full flow run takes roughly 30-60 minutes.
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
  `config.mk`, `block.mk`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch
  files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
