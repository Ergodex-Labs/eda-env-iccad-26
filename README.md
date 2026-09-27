# EDA-env: ICCAD 2026 artifacts

This release contains the 85 RTL-to-GDS tasks evaluated in the paper and their final Kimi-k3 submissions.
The evaluator rebuilds a submission in Docker, measures the resulting design, and calculates the gate and reward.
It needs no Modal account, agent API key, task generator, or training service.

## Contents

| Path | Contents |
|---|---|
| `tasks/` | Task instructions, starter files, edit rules, thresholds, and evaluation inputs. |
| `submissions/` | Final agent patches and an index of the reported gates and rewards. |
| `evaluator/` | Docker runner, measurement scripts, task checks, and reward calculation. |
| `Dockerfile` | Pinned ORFS tools, required flow patches, and simulation tools. |
| `results/` | Recorded RDF-2024 calibration measurements. |

Task-generation code, qualification pipelines, development probes, regression infrastructure, audit pipelines, and agent trajectories are outside this release.
Reference RTL and testbenches remain where the task needs them for evaluation.

## Run an evaluation

Use Docker with Linux amd64 support and Python 3.10 or later on the host.
The flow uses eight threads and a 16 GB container memory limit.
Large SoC tasks can take several hours.
ARM hosts use emulation and can take substantially longer.

Build the image from the repository root:

```sh
docker build --platform linux/amd64 -t eda-env-evaluator:iccad26 .
```

Evaluate a released submission:

```sh
python3 evaluator/evaluate.py --task 019 \
  --patch submissions/eda-env-019-elevatorfsm-sky130hd-impl/submission.diff \
  --out evaluation-output/019
```

The output directory must be new for each evaluation.
It contains `reward.json`, the measurements, and the flow logs.
A task ID or a task directory identifies the task.

To evaluate edited files, supply a complete copy of the task's `project/` directory:

```sh
python3 evaluator/evaluate.py --task 019 \
  --workspace /absolute/path/to/edited-project \
  --out evaluation-output/my-submission
```

The evaluator derives a patch against the starter and applies the same edit rules.
Missing files in the submitted directory count as deletions.

## Gate and reward

The evaluator checks permitted edits before it runs the flow.
It rebuilds from the starter in a fresh container without network access.
A separate container measures the final layout under the task's fixed constraints and library views.
Tasks with RTL checks also run EQY or Icarus Verilog.

The 85 tasks use these reward rules:

- 57 completion tasks: `reward = gate`.
- 26 timing tasks: `reward = gate * scale / ECP`.
- 2 area tasks: `reward = gate * scale / area`.

`targets.json` gives the scale, units, and gate thresholds for each task.
A gate passes only when every required condition passes.
Missing required measurements do not pass.
37 tasks need a starter replay to calculate relative thresholds.
The evaluator runs that replay automatically.
No reward calculation requires an oracle solution.

A rejected submission or failed flow receives gate 0 and reward 0.
An infrastructure error or failed required starter replay produces `status: error` and no numerical score.

## Final submissions

`submissions/index.json` maps each evaluated task to its final patch and the paper's reported gate and reward.
These reported values are comparison data, not inputs to the evaluator.
The evaluator calculates new results from the submitted files.

Tasks 034 and 071 have two patch files.
The original `submission.diff` includes a `runner.sh` convenience wrapper outside the current edit policy.
Their `replay.diff` omits only that wrapper and preserves every design and flow edit.
Use `replay.diff` for these two tasks.
The evaluator invokes the flow directly and does not use `runner.sh`.
Both original patches remain available with their checksums.

## License and citation

See `LICENSE`, `NOTICE`, and `CITATION.cff`.
Third-party design sources and models retain their own licenses.
