# Bring up elevator_fsm on SKY130

This project is an 8-floor elevator controller FSM (`elevator_fsm`) to be implemented
on the SKY130 platform. The RTL is final. The flow configuration is not
written yet: `/workspace/config.mk` pins only the design identity, and
the flow will not run as it stands.

Your workspace is `/workspace`. It holds the flow configuration stub
(`config.mk`) and the constraints (`constraint.sdc`, read-only for this
task).

Goal: complete the flow configuration and deliver a setup whose FULL
flow produces a clean final layout: worst setup slack >= 0 at the 10 ns
clock of `constraint.sdc`, zero routing DRC violations, and a floorplan
at 40% core utilization.
The finished layout must use between 42% and 60% of the core (standard-cell
utilization after sign-off).

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
  `/tmp/orfs-work/reports/sky130hd/elevator_fsm/base/6_finish.rpt`. Every
  metric is in
  `/tmp/orfs-work/logs/sky130hd/elevator_fsm/base/6_report.json`. Routing
  DRC violations are listed in
  `/tmp/orfs-work/reports/sky130hd/elevator_fsm/base/5_route_drc.rpt` (an
  empty file means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/sky130hd/elevator_fsm/base/`.
- A full flow run takes roughly 2-6 minutes.
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
  `config.mk`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch files elsewhere
  are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
