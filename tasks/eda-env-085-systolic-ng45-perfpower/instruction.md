# Close the clock on systolic @ NG45

This project implements a 4x4 weight-stationary systolic array on the NG45 platform. The
flow runs to the end, but the final layout misses the evaluation clock:
worst setup slack is negative at 1.40 ns.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`) and the constraints (`constraint.sdc`, read-only for this
task).

Goal: deliver a setup whose FULL flow closes timing at the 1.40 ns
evaluation clock — worst setup slack >= 0, zero routing DRC violations —
while keeping the design's cost in check: total cell area within 12% and
total power within 26% of the given setup's. Then push the effective
clock period (clock period minus worst setup slack) as low as you can.
Faster is better; there is no point at which further gains stop being
useful.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`.
- You may NOT edit the design RTL or `constraint.sdc`, and you may not
  change which source files the design reads.
- Run the flow with: `orfs-agent-run finish` (or any make target, e.g.
  `orfs-agent-run synth`). It picks up your `config.mk` AND any stage-script
  copies you placed under `/workspace/flow/scripts/`. Flow outputs land
  under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/nangate45/systolic/base/6_finish.rpt`. Every
  metric is in `/tmp/orfs-work/logs/nangate45/systolic/base/6_report.json`.
  Routing DRC violations are listed in
  `/tmp/orfs-work/reports/nangate45/systolic/base/5_route_drc.rpt` (an empty
  file means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/nangate45/systolic/base/`.
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
  `config.mk`, `abc.script`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch
  files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
