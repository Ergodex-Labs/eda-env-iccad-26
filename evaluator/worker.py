"""Run one fresh flow or measure its outputs inside the execution image."""

import argparse
import glob
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

import checks
from functional import lec_fn, tb_fn

TASK = Path("/task")
WORK = Path("/work")
FLOW = Path("/OpenROAD-flow-scripts/flow")
LIBRARIES = {"asap7": "lib/NLDM/*_FF_nldm_*.lib*",
             "nangate45": "lib/*typical*.lib*", "sky130hd": "lib/sky130_fd_sc_hd__tt_*.lib*"}


class Rejected(Exception):
    pass


def read_json(path, default=None):
    return json.loads(path.read_text()) if path.exists() else default


def require(result):
    ok, message = result
    if not ok:
        raise Rejected(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def manifest_check(ws):
    decl = read_json(TASK / "eval/hdl_scan.json", {"mode": "EXACT", "scope": []})
    require(checks.check_hdl_scan(checks.hdl_scan(str(ws)),
            read_json(TASK / "eval/ws_hdl_manifest.json", {}), decl["mode"], decl["scope"]))


def prepare(kind):
    ws = WORK / "ws"
    shutil.copytree(TASK / "project", ws)
    subprocess.run(["git", "init", "-q", str(ws)], check=True)
    subprocess.run(["git", "-C", str(ws), "add", "-A"], check=True)
    profile = read_json(TASK / "profile.json")
    patch = Path("/submission")
    if kind == "workspace":
        if checks._find_symlinks(str(patch)):
            raise Rejected("submitted workspace contains symbolic links")
        subprocess.run(["git", "-C", str(ws), "-c", "user.email=evaluator@localhost",
                        "-c", "user.name=evaluator", "commit", "-qm", "starter"], check=True)
        for p in ws.iterdir():
            if p.name != ".git":
                shutil.rmtree(p) if p.is_dir() else p.unlink()
        shutil.copytree(patch, ws, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git"))
        subprocess.run(["git", "-C", str(ws), "add", "-A"], check=True)
        patch = WORK / "submitted.diff"
        with patch.open("w") as stream:
            subprocess.run(["git", "-C", str(ws), "diff", "--cached", "--no-ext-diff",
                            "--no-color", "--src-prefix=a/", "--dst-prefix=b/"], stdout=stream, check=True)
        shutil.rmtree(ws)
        shutil.copytree(TASK / "project", ws)
        subprocess.run(["git", "init", "-q", str(ws)], check=True)
    if kind != "starter" and patch.stat().st_size:
        require(checks.check_whitelist(str(patch), profile))
        require(checks.apply_diff(str(patch), str(ws)))
    require(checks.sanitize_config_delta(str(TASK / "project/config.mk"),
            str(ws / "config.mk"), profile, str(ws / "sanitized.mk")))
    for rel in read_json(TASK / "eval/block_configs.json", []):
        require(checks.sanitize_config_delta(str(TASK / "project" / rel),
                str(ws / rel), profile, str(ws / rel)))
    manifest_check(ws)
    for rel, digest in read_json(TASK / "eval/hdl_manifest.json", {}).items():
        if checks._hash_file(str(Path("/OpenROAD-flow-scripts") / rel)) != digest:
            raise RuntimeError(f"execution image source differs: {rel}")
    return ws


def extra_libs():
    p = TASK / "eval/extra_libs.txt"
    return p.read_text().splitlines() if p.exists() else []


def run_flow(kind):
    ws = prepare(kind)
    targets = read_json(TASK / "targets.json")
    workspace_libs = [p for pattern in extra_libs() if pattern.startswith("ws:")
                      for p in glob.glob(str(ws / pattern[3:]))]
    lib_hashes = checks.hash_paths(workspace_libs)
    out = WORK / "out"
    out.mkdir()
    subprocess.run(["chown", "-R", "1001:1001", str(ws), str(out)], check=True)
    command = ("set -e; export PYTHONPATH=; unset PYTHONSTARTUP; "
               "source /OpenROAD-flow-scripts/env.sh >/dev/null 2>&1; "
               "export LEC_CHECK=0 WS=/work/ws WORK_HOME=/work/out "
               "DESIGN_CONFIG=/work/ws/sanitized.mk PROFILE=/task/profile.json; "
               "bash /evaluator/run_flow.sh build_macros NUM_CORES=8 >/dev/null 2>&1 || true; "
               "bash /evaluator/run_flow.sh finish NUM_CORES=8")
    with (WORK / "flow.log").open("w") as log:
        try:
            p = subprocess.run(["su", "agent", "-s", "/bin/bash", "-c", command],
                               stdout=log, stderr=subprocess.STDOUT, timeout=targets["budget_sec"])
        except subprocess.TimeoutExpired:
            return {"status": "failed", "failures": ["flow exceeded the task time budget"]}
    if p.returncode:
        return {"status": "failed", "failures": ["flow failed; see flow.log"]}
    if checks.hash_paths(workspace_libs) != lib_hashes:
        raise Rejected("workspace timing libraries changed during execution")
    manifest_check(ws)
    platform = (TASK / "eval/platform.txt").read_text().strip()
    design = (TASK / "eval/design.txt").read_text().strip()
    logdir = out / "logs" / platform / design / "base"
    merged = {"files": [], "defines": set(), "tops": [], "chparams": []}
    for logfile in sorted(set(logdir.glob("*yosys*.log")) | set(logdir.glob("1_*.log"))):
        parsed = checks.parse_yosys_log(str(logfile))
        merged["files"].extend(f for f in parsed["files"]
                               if not any(x in f for x in ("/work/out", "/objects/", "/results/")))
        merged["defines"].update(parsed["defines"])
        merged["tops"].extend(parsed["tops"])
        merged["chparams"].extend(parsed["chparams"])
    merged["defines"] = sorted(merged["defines"])
    expected = read_json(TASK / "eval/consumed.json")
    if expected.get("check_sources", True):
        if merged["files"] or merged["tops"]:
            require(checks.check_consumed(merged, expected, "EXACT"))
        elif expected["basenames"]:
            raise Rejected("synthesis did not report the declared sources")
    if not (out / "results" / platform / design / "base/6_final.odb").is_file():
        return {"status": "failed", "failures": ["flow produced no final ODB"]}
    return {"status": "ok"}


def measure():
    result = Path("/result")
    targets = read_json(TASK / "targets.json")
    platform = (TASK / "eval/platform.txt").read_text().strip()
    design = (TASK / "eval/design.txt").read_text().strip()
    platform_dir = FLOW / "platforms" / platform
    artifact = WORK / "out/results" / platform / design / "base"
    libs = sorted(glob.glob(str(platform_dir / LIBRARIES[platform])))
    for pattern in extra_libs():
        base, pattern = (TASK / "project", pattern[3:]) if pattern.startswith("ws:") else (platform_dir, pattern)
        libs.extend(sorted(glob.glob(str(base / pattern))))
    libs.extend(str(p) for p in sorted((WORK / "out/results" / platform).glob("*/base/*_typ.lib")))
    env = dict(os.environ, ODB_FILE=str(artifact / "6_final.odb"),
               EVAL_SDC=str(TASK / "eval/eval.sdc"), OUT_JSON=str(result / "signoff.json"),
               LIB_FILES=" ".join(libs), PLATFORM_DIR=str(platform_dir))
    rcx = platform_dir / "rcx_patterns.rules"
    env["RCX_RULES"] = str(rcx) if rcx.exists() else ""
    ir = TASK / "eval/ir_net.txt"
    if ir.exists():
        env["IR_NET"], env["IR_VOLTAGE"] = ir.read_text().split()
    macro = TASK / "eval/macro_check.txt"
    if macro.exists():
        env["MACRO_MASTER"] = macro.read_text().strip()
    with (result / "measurement.log").open("w") as log:
        p = subprocess.run(["/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad",
                            "-no_splash", "-exit", "/evaluator/measure.tcl"], env=env,
                           stdout=log, stderr=subprocess.STDOUT, timeout=8000)
    if p.returncode or not (result / "signoff.json").exists():
        raise RuntimeError("layout measurement failed; see measurement.log")
    metrics = read_json(result / "signoff.json")
    if ir.exists():
        import re
        match = re.search(r"Worstcase IR drop\s*:\s*([0-9.eE+-]+)", (result / "measurement.log").read_text())
        if match:
            metrics["ir_drop_v"] = float(match.group(1))
    logdir = WORK / "out/logs" / platform / design / "base"
    count, source = checks.drc_resolve(checks.drc_from_stage_jsons(str(logdir)),
                                      metrics.pop("drc_check_violations", None))
    if count is not None:
        metrics["drc_violations"], metrics["drc_source"] = count, source
    if "wns" in metrics:
        metrics["ecp"] = targets["eval_clk_ps"] - metrics["wns"]
    return {"status": "ok", "metrics": metrics}


def functional():
    metrics = {}
    decl = read_json(TASK / "eval/lec.json")
    if decl:
        golden = {Path(f).name: (TASK / "eval" / f).read_text() for f in decl["golden"]}
        revised = {Path(f).name: (WORK / "ws" / f).read_text() for f in decl["targets"]
                   if (WORK / "ws" / f).exists()}
        verdict = lec_fn(golden, revised, decl["top"]) if revised else {}
        if "lec_equivalent" in verdict:
            metrics["lec_equivalent"] = verdict["lec_equivalent"]
        print("Equivalence:", verdict, flush=True)
    decl = read_json(TASK / "eval/tb_check.json")
    if decl:
        files = {Path(f).name: (TASK / "eval" / f).read_text()
                 for f in [decl["tb"]] + decl.get("frozen", []) + decl.get("extra", [])}
        complete = all((WORK / "ws" / f).exists() for f in decl["targets"])
        if complete:
            files.update({Path(f).name: (WORK / "ws" / f).read_text() for f in decl["targets"]})
            verdict = tb_fn(files, decl["top"])
            if "tb_pass" in verdict:
                metrics["tb_pass"] = verdict["tb_pass"]
            print("Simulation:", verdict, flush=True)
    return {"status": "ok", "metrics": metrics}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=["flow", "measure", "functional"])
    parser.add_argument("--kind", choices=["starter", "patch", "workspace"], default="patch")
    args = parser.parse_args()
    destination = WORK / "flow.json" if args.phase == "flow" else Path("/result") / (args.phase + ".json")
    try:
        outcome = run_flow(args.kind) if args.phase == "flow" else measure() if args.phase == "measure" else functional()
    except Rejected as exc:
        outcome = {"status": "rejected", "failures": [str(exc)]}
    except Exception as exc:
        outcome = {"status": "error", "error": f"{type(exc).__name__}: {exc}"}
    write_json(destination, outcome)
    print(json.dumps(outcome), flush=True)
    sys.exit(2 if outcome["status"] == "error" else 0)
