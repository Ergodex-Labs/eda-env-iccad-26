# EDA-env: ICCAD 2026 research artifacts

This repository contains the benchmark artifacts for the ICCAD 2026 paper:
**Invited: EDA-env: A Reinforcement Learning Environment for RTL-to-GDS Design with Independent Scoring**.
The proceedings citation will be added after publication.

The release provides 85 chip-design tasks, final agent submissions, and tools to run and score submissions in Docker.
The tasks cover implementation, repair, and power, performance, and area (PPA) optimization.
RTL-to-GDS is the workflow from a register-transfer-level hardware design to its physical layout.

This release gives ML and EDA researchers a starting point for experiments with agents in that workflow.
Each task connects an engineering objective to editable design files, constraints, and measurable success criteria.
The task packages also give concrete examples of task and reward design for further benchmark and reinforcement-learning research.

[Project website](https://frontiereda.com) · [Archived artifacts](https://doi.org/10.5281/zenodo.22990248)

## What you can do

- **Evaluate your own agent.** Give it a task's instructions and starter files, then score its submitted patch or edited workspace.
- **Replay the paper's submissions.** Rebuild the supplied submissions and compare the measurements and rewards with the reported values.
- **Study task and reward design.** Inspect how permitted edits, physical constraints, and correctness checks determine the reward.

You supply the agent and its control loop.
The evaluator rebuilds the submitted design, measures it, and calculates the gate and reward.
The gate indicates whether the submission meets all required task conditions.
This release provides execution and scoring tools, but no agent or training loop.

The evaluator runs locally in Docker and requires no external service accounts.
An agent that uses a hosted model needs its own model access.
The initial Docker build requires internet access to download tools and dependencies.

## Start with a supplied submission

Task 019 brings up an elevator controller on SKY130.
The RTL is fixed.
The agent completes the implementation configuration under timing, routing, and utilization constraints.
Start with its supplied submission to check the execution and scoring workflow.

### 1. Get the repository and tools

Install Git, Docker with Linux amd64 support, and Python 3.10 or later on the host.
The evaluator uses eight threads and a 16 GB container memory limit.
Allocate enough memory to Docker for that container.
Large tasks can take several hours.
ARM hosts use emulation and can take substantially longer.

```sh
git clone https://github.com/Ergodex-Labs/eda-env-iccad-26.git
cd eda-env-iccad-26
```

Run the commands below from the repository root.

### 2. Build the image

```sh
docker build --platform linux/amd64 -t eda-env-evaluator:iccad26 .
```

### 3. Evaluate the supplied submission

```sh
python3 evaluator/evaluate.py --task 019 \
  --patch submissions/eda-env-019-elevatorfsm-sky130hd-impl/submission.diff \
  --out evaluation-output/019
```

The output directory must be new for each evaluation.
It contains `reward.json`, the measurements, and the flow logs.

```sh
cat evaluation-output/019/reward.json
```

A passing task 019 submission receives gate 1 and reward 1.
The [submission index](submissions/index.json) contains the paper's reported values for comparison.
See [Gate and reward](#gate-and-reward) for failed submissions and infrastructure errors.

## Evaluate your own agent

1. Read the task's [instructions](tasks/eda-env-019-elevatorfsm-sky130hd-impl/instruction.md) and [package guide](tasks/eda-env-019-elevatorfsm-sky130hd-impl/README.md).
2. Copy the starter project to a new directory.
3. Give your agent the instructions and the copied project.
4. Evaluate the edited project with the command below.

For task 019, copy the starter with:

```sh
mkdir -p workspaces
cp -R tasks/eda-env-019-elevatorfsm-sky130hd-impl/project workspaces/019
```

Task instructions use `/workspace` as the editable project path inside the task environment.
For this host-side workflow, give your agent the absolute path to `workspaces/019` as its editable project.
Your agent can call the evaluator after an attempt and read its output for feedback.
Choose a new output directory for each attempt.
The instructions also describe commands for use inside the task container.

After the agent edits the copied project, run:

```sh
python3 evaluator/evaluate.py --task 019 \
  --workspace "$PWD/workspaces/019" \
  --out evaluation-output/my-submission
```

Supply the complete edited project, not only its changed files.
The evaluator derives a patch against the starter and applies the task's edit rules.
Missing files in the submitted directory count as deletions.
Keep the original task package unchanged.

For another task, select its directory under `tasks/` and use its task ID and starter project.
The evaluator accepts a task ID or a task directory.
It also accepts a unified patch through `--patch`, as in the supplied-submission example.
Your agent's submission does not need to match the supplied patch to receive a reward.

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
