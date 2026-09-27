# Rebalance the pipeline on ASAP7

This project is a 4-tap FIR filter (`fir4`) on the ASAP7 platform.
The flow runs to the end and closes its own flow clock, but the
layout misses the 450 ps evaluation clock: the datapath is unbalanced
— one pipeline stage carries the whole multiply-accumulate chain
while the tail stages are pass-through registers.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`), the constraints (`constraint.sdc`, read-only), and the
RTL (`src/fir4/fir4.v`) — the RTL file IS editable in this task.
Register rebalancing (retiming) is allowed and is the intended lever:
any rewrite must keep the module name, the ports, the FIR function,
and the EXACT 4-cycle latency stated in the file header. A frozen
testbench checks the function and the latency; an implementation that
changes either does not count.

Goal: deliver a setup whose FULL flow closes timing at the 450 ps
evaluation clock — worst setup slack >= 0, zero routing DRC
violations. Then push the effective clock period as low as you can.
Faster is better; there is no point at which further gains stop being
useful.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`. A custom ABC
  synthesis script can go at `/workspace/abc.script`.
- You may NOT edit `constraint.sdc`, and you may not change which
  source files the design reads. `src/fir4/fir4.v` IS editable under
  the function-and-latency contract above.
- Run the flow with: `orfs-agent-run finish` (or any make target, e.g.
  `orfs-agent-run synth`). It picks up your `config.mk` AND any stage-script
  copies you placed under `/workspace/flow/scripts/`. Flow outputs land
  under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/asap7/fir4/base/6_finish.rpt`. Every metric is in
  `/tmp/orfs-work/logs/asap7/fir4/base/6_report.json`. Routing DRC
  violations are listed in
  `/tmp/orfs-work/reports/asap7/fir4/base/5_route_drc.rpt` (an empty file
  means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/fir4/base/`.
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
  `config.mk`, `abc.script`, `src/fir4/fir4.v`, `hooks/*.tcl`,
  `flow/scripts/*.tcl`. Scratch files elsewhere are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
