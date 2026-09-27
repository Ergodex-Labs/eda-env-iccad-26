"""Calculate gates and rewards from measurements in the task's declared units."""

import math


def number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def needs_starter(targets):
    return any(g.get("ref") == "noop" for g in targets["gates"])


def score(metrics, targets, starter=None):
    failures = []
    checks = []
    for requirement in targets["gates"]:
        name, op = requirement["metric"], requirement["op"]
        if op not in ("<=", ">="):
            raise ValueError(f"unsupported gate operator: {op}")
        limit = requirement.get("value")
        if "ref" in requirement:
            if requirement["ref"] != "noop":
                raise ValueError("unsupported gate reference")
            baseline = (starter or {}).get(name)
            if not number(baseline):
                raise ValueError(f"starter measurement missing or invalid: {name}")
            limit = baseline * requirement["scale"]
        if not number(limit):
            raise ValueError(f"invalid threshold: {name}")
        actual = metrics.get(name)
        passed = number(actual) and (actual <= limit if op == "<=" else actual >= limit)
        checks.append({"metric": name, "value": actual, "op": op, "limit": limit, "passed": passed})
        if not passed:
            failures.append(f"{name}: {actual!r} does not satisfy {op} {limit}")
    gate = float(not failures)
    rule = targets["reward"]
    if rule["form"] == "gate":
        reward = gate * rule.get("scale", 1.0)
    elif rule["form"] == "inverse":
        value = metrics.get(rule["metric"])
        reward = gate * rule.get("scale", 1.0) / value if gate and number(value) and value > 0 else 0.0
    else:
        raise ValueError(f"unsupported reward form: {rule['form']}")
    return {"status": "scored", "gate": gate, "reward": round(reward, 6),
            "reward_units": rule.get("units"), "checks": checks,
            "failures": failures, "metrics": metrics, "starter_metrics": starter}
