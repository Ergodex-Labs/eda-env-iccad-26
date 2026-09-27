#!/usr/bin/env python3
"""Rebuild a submission in Docker, check the task, and report its reward."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from score import needs_starter, score

ROOT = Path(__file__).resolve().parent.parent


def docker(image, task, case, phase, kind="patch", submission=None):
    command = ["docker", "run", "--rm", "--platform", "linux/amd64", "--network", "none",
               "--cpus", "8", "--memory", "16g", "--pids-limit", "4096",
               "--mount", f"type=bind,src={task},dst=/task,readonly",
               "--mount", f"type=bind,src={ROOT / 'evaluator'},dst=/evaluator,readonly",
               "--mount", f"type=bind,src={case},dst=/work" + (",readonly" if phase != "flow" else "")]
    if phase != "flow":
        destination = case / phase
        destination.mkdir()
        command += ["--mount", f"type=bind,src={destination},dst=/result"]
    if submission is not None:
        command += ["--mount", f"type=bind,src={submission},dst=/submission,readonly"]
    command += ["--entrypoint", "python3", image, "/evaluator/worker.py", phase, "--kind", kind]
    with (case / (phase + "-container.log")).open("w") as log:
        process = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT)
    receipt = case / "flow.json" if phase == "flow" else case / phase / (phase + ".json")
    if not receipt.is_file():
        raise RuntimeError(f"{phase} produced no result; see {case / (phase + '-container.log')}")
    outcome = json.loads(receipt.read_text())
    if process.returncode or outcome["status"] == "error":
        raise RuntimeError(outcome.get("error", f"{phase} container exited {process.returncode}"))
    return outcome


def run_case(image, task, case, kind, submission=None):
    case.mkdir()
    outcome = docker(image, task, case, "flow", kind, submission)
    if outcome["status"] != "ok":
        return outcome
    outcome = docker(image, task, case, "measure")
    if (task / "eval/lec.json").exists() or (task / "eval/tb_check.json").exists():
        result = docker(image, task, case, "functional")
        outcome["metrics"].update(result["metrics"])
    return outcome


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task", required=True, help="task directory or three-digit task ID")
    inputs = parser.add_mutually_exclusive_group(required=True)
    inputs.add_argument("--patch", type=Path, help="unified patch against the task starter")
    inputs.add_argument("--workspace", type=Path, help="complete edited copy of the task project directory")
    parser.add_argument("--image", default="eda-env-evaluator:iccad26")
    parser.add_argument("--out", required=True, type=Path, help="new directory for measurements, logs, and reward.json")
    args = parser.parse_args()
    task = Path(args.task).resolve()
    if args.task.isdigit():
        matches = list((ROOT / "tasks").glob(f"eda-env-{int(args.task):03d}-*"))
        if len(matches) != 1:
            parser.error("task ID must identify exactly one released task")
        task = matches[0]
    if not (task / "targets.json").is_file():
        parser.error("task directory must contain targets.json")
    kind, submission = ("patch", args.patch) if args.patch is not None else ("workspace", args.workspace)
    submission = submission.resolve()
    if kind == "patch" and not submission.is_file() or kind == "workspace" and not submission.is_dir():
        parser.error("submission path has the wrong type or does not exist")
    out = args.out.resolve()
    if out.exists():
        parser.error("--out must be a new directory")
    if out.is_relative_to(task) or out.is_relative_to(submission):
        parser.error("--out must be outside the task and submitted workspace")
    out.mkdir(parents=True)
    try:
        image = subprocess.check_output(["docker", "image", "inspect", args.image,
                                         "--format", "{{.Id}}"], text=True).strip()
        targets = json.loads((task / "targets.json").read_text())
        outcome = run_case(image, task, out / "submission", kind, submission)
        if outcome["status"] in ("failed", "rejected"):
            result = dict(outcome, gate=0.0, reward=0.0)
        else:
            baseline = None
            if needs_starter(targets):
                starter = run_case(image, task, out / "starter", "starter")
                if starter["status"] != "ok":
                    raise RuntimeError(f"required starter replay failed: {starter}")
                baseline = starter["metrics"]
            result = score(outcome["metrics"], targets, baseline)
        result.update(task=task.name, image=image,
                      targets_sha256=hashlib.sha256((task / "targets.json").read_bytes()).hexdigest())
    except Exception as exc:
        result = {"status": "error", "error": str(exc)}
    (out / "reward.json").write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")
    print(json.dumps(result, indent=2))
    return 2 if result["status"] == "error" else 0


if __name__ == "__main__":
    sys.exit(main())
