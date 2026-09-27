# Repair the macro placement on mpb_soc3 @ ASAP7

This project is a 24-bank scratchpad SoC (mpb_soc3) with 24 SRAM
macros on the ASAP7 platform. The flow runs to the end, but the
floorplan is bad: macros crowd together with starved routing channels,
and the layout fails sign-off — routing shows violations.

Your workspace is `/workspace`. It holds the flow configuration
(`config.mk`), the constraints (`constraint.sdc`, read-only), and the
frozen design RTL (`src/mpb3/`, read-only).

Goal: deliver a floorplan and macro placement whose FULL flow produces
a clean final layout — worst setup slack >= 0 at the 850 ps clock of
`constraint.sdc` and zero routing DRC violations, with every macro
legally placed at 50% core utilization.
The finished layout must use between 40% and 60% of the core (standard-cell
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
  `/tmp/orfs-work/reports/asap7/mpb3/base/6_finish.rpt`. Every metric is in
  `/tmp/orfs-work/logs/asap7/mpb3/base/6_report.json`. Routing DRC
  violations are listed in
  `/tmp/orfs-work/reports/asap7/mpb3/base/5_route_drc.rpt` (an empty file
  means zero violations). Per-stage logs are under
  `/tmp/orfs-work/logs/asap7/mpb3/base/`.
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
  `config.mk`, `hooks/*.tcl`, `flow/scripts/*.tcl`. Scratch files elsewhere
  are ignored.
- The final layout is produced by running `orfs-agent-run finish` on your
  change set in a clean work dir. Express any flow-sequence change through
  `config.mk`, hooks, or stage scripts.
