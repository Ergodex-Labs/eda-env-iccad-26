# EDA-env

EDA-env is a benchmark for evaluating agents on chip-design tasks in the RTL-to-GDS flow, from a hardware description to a physical layout.
This repository contains 85 tasks and a Docker evaluator for scoring an agent's changes to the design files.
The tasks include completing an implementation flow, repairing a power grid, and improving timing under physical constraints.

Use it to evaluate your own agent or replay the paper's final submissions.
For each submission, the evaluator rebuilds the design and returns measurements, a pass/fail result, and a reward.
Your agent can use that feedback to revise its design and try again.

Each task specifies the allowed edits, design constraints, and reward formula.
Scoring is independent of the agent: a timing improvement earns a reward only if the design also passes the task's required checks.

This is the artifact release for the ICCAD 2026 paper
*Invited: EDA-env: A Reinforcement Learning Environment for RTL-to-GDS Design with Independent Scoring*.
The proceedings citation will be added after publication.

[Project website](https://frontiereda.com) · [Archived artifacts](https://doi.org/10.5281/zenodo.22990248)

## Quickstart

We'll use task 019, a SKY130 elevator controller, as the example for this walkthrough.
First, build the evaluator and run the included submission to check your setup; then try your own agent.
The same steps apply to the other tasks.

### 1. Install prerequisites and clone the repository

Install Git, Docker with Linux amd64 support, and Python 3.10 or later on the host.
Each evaluation container is limited to eight CPUs and 16 GB of memory; Docker needs enough memory to accommodate it.
Large tasks can take several hours, and ARM hosts run through emulation, which can take substantially longer.

```sh
git clone https://github.com/Ergodex-Labs/eda-env-iccad-26.git
cd eda-env-iccad-26
```

Run the commands below from the repository root.

### 2. Build the image

The build needs internet access to download tools and dependencies.
Evaluation runs locally.

```sh
docker build --platform linux/amd64 -t eda-env-evaluator:iccad26 .
```

### 3. Run an example

Run task 019's included submission:

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

For this submission, expect `gate: 1` and `reward: 1` in `reward.json`.
The gate is 1 when all required checks pass.
See [Scoring](#scoring) for reward formulas and error handling, and the [submission index](submissions/index.json) for the paper's reported values.

## Evaluate your own agent

To run an agent on a task, give it the task instructions and a copy of the starter project.
For task 019, read the [instructions](tasks/eda-env-019-elevatorfsm-sky130hd-impl/instruction.md) and [package guide](tasks/eda-env-019-elevatorfsm-sky130hd-impl/README.md), then copy the project:

```sh
mkdir -p workspaces
cp -R tasks/eda-env-019-elevatorfsm-sky130hd-impl/project workspaces/019
```

Give your agent the absolute path to `workspaces/019`.
In the task instructions, `/workspace` refers to this project inside the task container; the commands there assume that container environment.

After the agent edits the copied project, run:

```sh
python3 evaluator/evaluate.py --task 019 \
  --workspace "$PWD/workspaces/019" \
  --out evaluation-output/my-submission
```

The `--workspace` directory must contain the complete edited project, since the evaluator compares it with the starter and checks the changes against the task's edit rules.
Missing files count as deletions.
Keep the original task package unchanged and work in the copy.

Use a new output directory for each attempt, and pass the results back to your agent as needed.
You provide the agent, any training loop, and model access if it uses a hosted model.

For another task, use its starter project from `tasks/` and pass its ID or directory to `--task`.
The evaluator also accepts a unified patch through `--patch`, as in the quickstart.

## Repository contents

| Path | Contents |
|---|---|
| `tasks/` | Task instructions, starter files, edit rules, thresholds, and evaluation inputs. |
| `submissions/` | Final agent patches and an index of the reported gates and rewards. |
| `evaluator/` | Docker runner, measurement scripts, task checks, and reward calculation. |
| `Dockerfile` | Pinned OpenROAD-flow-scripts (ORFS) image, flow patches, and simulation tools. |
| `results/` | Recorded RDF-2024 calibration measurements. |

In task directory names, `3d` means "3-objective": improve timing while meeting power and area limits.

The release does not include agent trajectories or the pipelines used to create and qualify tasks.
Tasks include reference RTL and testbenches where these are needed for evaluation.

## Scoring

The evaluator checks the submitted edits, applies them to the starter, and rebuilds the design in a fresh container without network access.
It measures the final layout in a separate container with the task's fixed constraints and library views.
Depending on the task, EQY checks RTL equivalence or Icarus Verilog runs a simulation testbench.

Rewards depend on the task type:

- 57 completion tasks: `reward = gate`.
- 26 timing tasks: `reward = gate * scale / ECP`.
- 2 area tasks: `reward = gate * scale / area`.

ECP is the effective clock period; each task's `targets.json` gives the scale, units, and gate thresholds.
The gate is 1 only if every required condition passes and all required measurements are present.
For 37 tasks, the evaluator also runs the starter because some thresholds depend on its measurements.

A rejected submission or failed flow receives gate 0 and reward 0.
An infrastructure error or failed required starter replay produces `status: error` and no numerical score.

## Final submissions

The [submission index](submissions/index.json) lists each task's final patch and the gate and reward reported in the paper.
These are reference values for comparison; the evaluator computes scores from the new run.

For tasks 034 and 071, use `replay.diff` with the evaluator.
Their original `submission.diff` files include a `runner.sh` wrapper that the edit rules do not permit and the evaluator does not need, since it runs the flow directly.
The replay patches remove only that wrapper, keeping all design and flow edits.
Both versions and the original checksums are included.

## License and citation

See [LICENSE](LICENSE), [NOTICE](NOTICE), and [CITATION.cff](CITATION.cff).
Third-party design sources and models retain their own licenses.
