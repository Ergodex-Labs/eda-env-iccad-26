# EDA-env

EDA-env is a benchmark for evaluating agents on chip-design tasks in the RTL-to-GDS flow, from a hardware description to a physical layout.
This repository contains 85 tasks and a Docker evaluator for scoring an agent's changes to the design files.
The tasks include completing an implementation flow, repairing a power grid, and improving timing under physical constraints.

You can run your own agent on these tasks or reproduce the supplied final submissions from the paper.
The evaluator rebuilds each submission and returns measurements, a pass/fail result, and a reward.
You choose the agent and control how it uses that feedback between attempts.

For ML and EDA researchers building similar environments, the task files specify the allowed edits, design constraints, and reward formulas.
The evaluator shows how we check those constraints and measure the resulting layout independently of the agent.
A timing improvement earns a reward only if the design also passes the task's required checks.

This is the artifact release for the ICCAD 2026 paper
*Invited: EDA-env: A Reinforcement Learning Environment for RTL-to-GDS Design with Independent Scoring*.
The proceedings citation will be added after publication.

[Project website](https://frontiereda.com) · [Archived artifacts](https://doi.org/10.5281/zenodo.22990248)

## Start with a supplied submission

Task 019 asks the agent to complete the implementation configuration for an elevator controller on SKY130.
The RTL stays fixed, and the resulting layout must meet the task's timing, routing, and utilization limits.
Run its supplied submission first to check your installation.

### 1. Get the repository and tools

Install Git, Docker with Linux amd64 support, and Python 3.10 or later on the host.
Each evaluation container has a limit of eight CPUs and 16 GB of memory.
Allocate enough memory to Docker for that container.
Large tasks can take several hours.
ARM hosts use emulation and can take substantially longer.

```sh
git clone https://github.com/Ergodex-Labs/eda-env-iccad-26.git
cd eda-env-iccad-26
```

Run the commands below from the repository root.

### 2. Build the image

The build downloads the tools and dependencies, so it needs internet access.
Evaluation runs locally without external service accounts.

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

A passing task 019 submission receives `gate: 1` and `reward: 1`.
The gate records whether the submission passes all required checks.
The [submission index](submissions/index.json) contains the paper's reported values for comparison.
See [Gate and reward](#gate-and-reward) for failed submissions and infrastructure errors.

## Evaluate your own agent

Read task 019's [instructions](tasks/eda-env-019-elevatorfsm-sky130hd-impl/instruction.md) and [package guide](tasks/eda-env-019-elevatorfsm-sky130hd-impl/README.md).
Then copy its starter project to a new directory:

```sh
mkdir -p workspaces
cp -R tasks/eda-env-019-elevatorfsm-sky130hd-impl/project workspaces/019
```

Give your agent the instructions and the absolute path to `workspaces/019`.
The instructions refer to this project as `/workspace` and include commands for use inside the task container.
For this example, the agent edits the local copy at `workspaces/019`.

After the agent edits the copied project, run:

```sh
python3 evaluator/evaluate.py --task 019 \
  --workspace "$PWD/workspaces/019" \
  --out evaluation-output/my-submission
```

Supply the complete edited project with `--workspace`.
The evaluator compares it with the starter to identify edits and check whether they are allowed.
Missing files in the submitted directory count as deletions.
Keep the original task package unchanged.

Your agent can read the evaluation output and revise its submission after each attempt.
Use a new output directory for each attempt.
This repository does not include an agent or training loop.
If your agent uses a hosted model, it needs its own model access.

For another task, use its starter project from `tasks/` and pass its ID or directory to `--task`.
To submit a unified patch instead, use `--patch` as in the first example.
The evaluator scores any submission that follows the task's edit rules.

## Contents

| Path | Contents |
|---|---|
| `tasks/` | Task instructions, starter files, edit rules, thresholds, and evaluation inputs. |
| `submissions/` | Final agent patches and an index of the reported gates and rewards. |
| `evaluator/` | Docker runner, measurement scripts, task checks, and reward calculation. |
| `Dockerfile` | Pinned OpenROAD-flow-scripts (ORFS) image, flow patches, and simulation tools. |
| `results/` | Recorded RDF-2024 calibration measurements. |

The release does not include agent trajectories or the pipelines used to create and qualify tasks.
Tasks include reference RTL and testbenches where these are needed for evaluation.

## Gate and reward

The evaluator checks the submitted edits, applies them to the starter, and rebuilds the design in a fresh container without network access.
It measures the final layout in a separate container with the task's fixed constraints and library views.
Depending on the task, EQY checks RTL equivalence or Icarus Verilog runs a simulation testbench.

The 85 tasks use these reward rules:

- 57 completion tasks: `reward = gate`.
- 26 timing tasks: `reward = gate * scale / ECP`.
- 2 area tasks: `reward = gate * scale / area`.

ECP is the effective clock period.
Each task's `targets.json` gives the scale, units, and gate thresholds.
The gate is 1 only if every required condition passes and all required measurements are present.
For 37 tasks, some thresholds depend on the starter's measurements, so the evaluator also runs the starter automatically.

A rejected submission or failed flow receives gate 0 and reward 0.
An infrastructure error or failed required starter replay produces `status: error` and no numerical score.

## Final submissions

The [submission index](submissions/index.json) lists each task's final patch and its reported gate and reward.
Use these values to compare a new evaluation with the paper's results.
The evaluator calculates scores from each new run and does not use the reported values as inputs.

Tasks 034 and 071 have two patch files.
For these tasks, use `replay.diff` with the evaluator.
The original `submission.diff` includes a `runner.sh` wrapper that the edit rules do not permit.
The replay patch removes that wrapper and keeps all design and flow edits.
The evaluator runs the flow directly, so it does not need the wrapper.
The original patches and their checksums are also included.

## License and citation

See [LICENSE](LICENSE), [NOTICE](NOTICE), and [CITATION.cff](CITATION.cff).
Third-party design sources and models retain their own licenses.
