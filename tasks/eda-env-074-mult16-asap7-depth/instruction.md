# Shorten the multiply critical path on ASAP7

This project is a 16x16 pipelined multiplier (`mult16`) on the ASAP7 platform. The flow
runs to the end and closes its own flow clock, but the layout misses
the 653 ps evaluation clock: the combinational depth of the
multiply stage dominates the critical path, and the stock synthesis
recipe does not reach the target.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`) and the constraints (`constraint.sdc`, read-only). The
RTL (`src/mult16/mult16.v`) is FROZEN in this task — the lever is
the implementation recipe, not the source.

Goal: deliver a setup whose FULL flow closes timing at the 653 ps
evaluation clock — worst setup slack >= 0, zero routing DRC
violations. Then push the effective clock period as low as you can.
Faster is better; there is no point at which further gains stop being
useful.

Rules and mechanics:

- Edit `/workspace/config.mk` values freely. To modify a flow stage script,
  place your copy under `/workspace/flow/scripts/` — your copy is used for
  that stage. Hook Tcl files go under `/workspace/hooks/`. A custom ABC
  synthesis script can go at `/workspace/abc.script`.
- You may NOT edit `src/mult16/mult16.v` or `constraint.sdc`, and you
  may not change which source files the design reads.
- Run the flow with: `orfs-agent-run finish` (or any make target, e.g.
  `orfs-agent-run synth`). It picks up your `config.mk` AND any stage-script
  copies you placed under `/workspace/flow/scripts/`. Flow outputs land
  under `/tmp/orfs-work`, never in `/workspace`.
- Results to read after the flow: the timing, power, and area summary is
  `/tmp/orfs-work/reports/asap7/mult16/base/6_finish.rpt`. Every metric is
  in `/tmp/orfs-work/logs/asap7/mult16/base/6_report.json`. Routing DRC
  violations are listed in
  `/tmp/orfs-work/reports/asap7/mult16/base/5_route_drc.rpt` (an empty file
  means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/mult16/base/`.
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
