"""Submission checks and routing-metric parsing for the released tasks."""
from __future__ import annotations
import hashlib
import json
import os
import re
import subprocess
import sys
DIFF_MAX_BYTES = 5 * 1024 * 1024
DIFF_MAX_FILES = 200
HDL_EXTS = ('.v', '.sv', '.vh', '.svh', '.vhd', '.vhdl')
_HDR_OK = ('--- a/', '+++ b/', '--- /dev/null', '+++ /dev/null')

def diff_headers_canonical(diff_file: str):
    for ln, line in enumerate(open(diff_file, errors='replace'), 1):
        if line.startswith(('--- ', '+++ ')):
            if not line.rstrip('\n').startswith(_HDR_OK):
                return (False, f'line {ln}: non-canonical patch header {line.strip()[:60]!r}')
        if line.startswith('GIT binary patch'):
            return (False, f'line {ln}: binary patch not allowed')
    return (True, 'headers canonical')

def diff_paths(diff_file: str) -> set[str]:
    paths = set()
    for line in open(diff_file, errors='replace'):
        if line.startswith(('+++ b/', '--- a/')):
            p = line[6:].strip()
            if p and p != 'dev/null':
                paths.add(p)
    return paths

def check_whitelist(diff_file: str, profile: dict) -> tuple[bool, str]:
    ok, why = diff_headers_canonical(diff_file)
    if not ok:
        return (False, why)
    parsed = diff_paths(diff_file)
    if not parsed and os.path.getsize(diff_file) > 0:
        return (False, 'nonempty patch parsed to zero paths (rejected)')
    allowed = [re.compile(p) for p in profile['allowed_paths']]
    bad = [p for p in sorted(parsed) if not any((rx.fullmatch(p) for rx in allowed))]
    if bad:
        return (False, f'out-of-profile paths: {bad[:10]}')
    return (True, 'whitelist ok')

def _changed_files(workspace: str) -> set[str]:
    p = subprocess.run(['git', 'status', '--porcelain', '--untracked-files=all'], cwd=workspace, capture_output=True, text=True)
    out = set()
    for line in p.stdout.splitlines():
        entry = line[3:].strip()
        if ' -> ' in entry:
            a, b = entry.split(' -> ', 1)
            out |= {a.strip('"'), b.strip('"')}
        elif entry:
            out.add(entry.strip('"'))
    return out

def apply_diff(diff_file: str, workspace: str) -> tuple[bool, str]:
    ok, why = diff_headers_canonical(diff_file)
    if not ok:
        return (False, why)
    size = os.path.getsize(diff_file)
    if size > DIFF_MAX_BYTES:
        return (False, f'diff too large: {size} bytes')
    parsed = diff_paths(diff_file)
    if not parsed and size > 0:
        return (False, 'nonempty patch parsed to zero paths (rejected)')
    if len(parsed) > DIFF_MAX_FILES:
        return (False, f'diff touches too many files: {len(parsed)}')
    if subprocess.run(['git', 'rev-parse', '-q', '--verify', 'HEAD'], cwd=workspace, capture_output=True).returncode != 0:
        subprocess.run(['git', 'add', '-A'], cwd=workspace, capture_output=True)
        subprocess.run(['git', '-c', 'user.email=verifier@eda-env', '-c', 'user.name=verifier', 'commit', '-qm', 'pre-apply baseline'], cwd=workspace, capture_output=True)
    abs_diff = os.path.abspath(diff_file)
    chk = subprocess.run(['git', 'apply', '--check', '--whitespace=nowarn', abs_diff], cwd=workspace, capture_output=True, text=True)
    if chk.returncode != 0:
        return (False, f'git apply --check failed: {chk.stderr.strip()[:300]}')
    pre_links = _find_symlinks(workspace)
    p = subprocess.run(['git', 'apply', '--whitespace=nowarn', abs_diff], cwd=workspace, capture_output=True, text=True)
    if p.returncode != 0:
        return (False, f'git apply failed: {p.stderr.strip()[:300]}')
    changed = _changed_files(workspace)
    if changed != parsed:
        return (False, f'changed-file set differs from parsed headers: extra={sorted(changed - parsed)[:5]} missing={sorted(parsed - changed)[:5]}')
    new_links = _find_symlinks(workspace) - pre_links
    if new_links:
        return (False, f'diff introduced symlinks: {sorted(new_links)[:5]}')
    return (True, f'applied ({len(parsed)} files)')

def _find_symlinks(root: str) -> set[str]:
    links = set()
    for d, dirs, files in os.walk(root):
        for name in dirs + files:
            p = os.path.join(d, name)
            if os.path.islink(p):
                links.add(os.path.relpath(p, root))
    return links
_LINE_RX = re.compile('^\\s*(?:export\\s+)?([A-Za-z_][A-Za-z0-9_]*)\\s*([?+:]?=)\\s*(.*?)\\s*$')
_FORBIDDEN_IN_VALUE = re.compile('\\$\\(\\s*(shell|eval|call|foreach|if|or|and|file|guile)\\b|`')
_VALUE_CHARSET = re.compile('^[A-Za-z0-9_.\\-+=:,/"\\\' ()$*%\\[\\]{}]*$')
_VALUE_CHARSET_ARGS = re.compile('^[A-Za-z0-9_.\\-+=:,;/"\\\' ()$*%\\[\\]{}]*$')

def _value_charset_for(key: str):
    return _VALUE_CHARSET_ARGS if key.endswith('_ARGS') else _VALUE_CHARSET

def _parse_assignments(path: str):
    from collections import Counter
    out: Counter = Counter()
    for raw in open(path, errors='replace'):
        m = _LINE_RX.match(raw.rstrip('\n'))
        if m:
            out[m.group(1), m.group(3)] += 1
    return out

def _structure_lines(path: str) -> list[str]:
    out = []
    for raw in open(path, errors='replace'):
        line = raw.rstrip('\n')
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if not _LINE_RX.match(line):
            out.append(line.strip())
    return out

def sanitize_config_delta(baseline: str, submitted: str, profile: dict, out_path: str) -> tuple[bool, str]:
    if _structure_lines(submitted) != _structure_lines(baseline):
        return (False, 'config structure (ifeq/endif skeleton) differs from baseline')
    base_pairs = _parse_assignments(baseline)
    allowed = set(profile['allowed_variables'])
    blocked = set(profile.get('blocked_variables', []))
    out_lines = ['# regenerated by edaverify - config-as-data (delta mode)']
    n_agent = 0
    for ln, raw in enumerate(open(submitted, errors='replace'), 1):
        line = raw.rstrip('\n')
        if not line.strip() or line.lstrip().startswith('#'):
            out_lines.append(line)
            continue
        m = _LINE_RX.match(line)
        if not m:
            out_lines.append(line)
            continue
        key, op, value = m.groups()
        if base_pairs[key, value] > 0:
            base_pairs[key, value] -= 1
            out_lines.append(line)
            continue
        if key in blocked:
            return (False, f'config line {ln}: blocked variable {key}')
        if key not in allowed:
            return (False, f'config line {ln}: unknown variable {key}')
        if _FORBIDDEN_IN_VALUE.search(value):
            return (False, f'config line {ln}: forbidden make/shell construct')
        if not _value_charset_for(key).match(value) or '\\' in value:
            return (False, f'config line {ln}: illegal characters in value')
        out_lines.append(f'export {key} = {value}')
        n_agent += 1
    n_deleted = sum(base_pairs.values())
    with open(out_path, 'w') as fh:
        fh.write('\n'.join(out_lines) + '\n')
    return (True, f'delta ok ({n_agent} agent assignments, {n_deleted} baseline assignments deleted)')

def _hash_file(p: str) -> str:
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for c in iter(lambda: f.read(1 << 20), b''):
            h.update(c)
    return h.hexdigest()

def hdl_scan(workspace: str) -> dict[str, str]:
    out = {}
    for d, _, files in os.walk(workspace):
        for fn in files:
            if fn.lower().endswith(HDL_EXTS):
                p = os.path.join(d, fn)
                out[os.path.relpath(p, workspace)] = _hash_file(p)
    return out

def check_hdl_scan(scan: dict[str, str], frozen: dict[str, str], mode: str, scope: list[str]) -> tuple[bool, str]:
    if mode == 'RECORD':
        return (True, 'hdl recorded')
    extra = {p for p in scan if p not in frozen}
    changed = {p for p in scan if p in frozen and scan[p] != frozen[p]}
    missing = {p for p in frozen if p not in scan}
    if mode == 'SCOPED':
        rx = [re.compile(s) for s in scope]
        in_scope = lambda p: any((r.fullmatch(p) for r in rx))
        extra = {p for p in extra if not in_scope(p)}
        changed = {p for p in changed if not in_scope(p)}
        missing = {p for p in missing if not in_scope(p)}
    if extra or changed or missing:
        return (False, f'hdl manifest violation: extra={sorted(extra)[:5]} changed={sorted(changed)[:5]} missing={sorted(missing)[:5]}')
    return (True, 'hdl manifest ok')
_YS_FILE_RX = re.compile('^\\s*\\d*[>]?\\s*(?:read_verilog|read_slang|read_systemverilog|sv_elaborate)\\b(.*)$')
_YS_DEFINE_RX = re.compile('(?:^|\\s)(?:-D\\s*|--define\\s+)([A-Za-z_][\\w=]*)')
_YS_TOP_RX = re.compile('(?:hierarchy.*-top|--top)\\s+(\\S+)')
_YS_CHPARAM_RX = re.compile('^\\s*\\d*[>]?\\s*chparam\\b(.*)$')

def parse_yosys_log(log_path: str) -> dict:
    files, defines, tops, chparams = ([], set(), [], [])
    for line in open(log_path, errors='replace'):
        m = _YS_FILE_RX.match(line)
        if m:
            args = m.group(1)
            for d in _YS_DEFINE_RX.findall(args):
                defines.add(d)
            for tok in args.split():
                if tok.lower().endswith(HDL_EXTS):
                    files.append(tok)
        for d in _YS_DEFINE_RX.findall(line) if 'read_' in line else []:
            defines.add(d)
        t = _YS_TOP_RX.search(line)
        if t:
            tops.append(t.group(1))
        c = _YS_CHPARAM_RX.match(line)
        if c:
            chparams.append(c.group(1).strip()[:120])
    return {'files': files, 'defines': sorted(defines), 'tops': tops, 'chparams': chparams}

def check_consumed(consumed: dict, frozen: dict, mode: str, allowed_extra_basenames: set | None=None) -> tuple[bool, str]:
    if mode == 'RECORD':
        return (True, 'consumed recorded')
    frozen_names = set(frozen['basenames'])
    got_names = {os.path.basename(f) for f in consumed['files']}
    extra = got_names - frozen_names
    if mode == 'SCOPED' and allowed_extra_basenames:
        extra -= set(allowed_extra_basenames)
    if extra:
        return (False, f'synthesis consumed unmanifested files: {sorted(extra)[:5]}')
    if set(consumed['defines']) != set(frozen.get('defines', [])):
        return (False, f"defines mismatch: got {consumed['defines']} expected {frozen.get('defines', [])}")
    tops = [t for t in consumed['tops']]
    if tops and frozen.get('top') and (tops[-1] != frozen['top']):
        return (False, f"top module changed: {tops[-1]} != {frozen['top']}")
    if consumed['chparams']:
        if mode == 'EXACT':
            return (False, f"chparam used: {consumed['chparams'][:2]}")
        if mode == 'SCOPED' and (not frozen.get('allow_chparam')):
            return (False, f"chparam used without task declaration: {consumed['chparams'][:2]}")
    return (True, 'consumed inputs ok')

def hash_paths(paths: list) -> dict:
    return {p: _hash_file(p) for p in paths if os.path.isfile(p)}

def drc_resolve(json_drc, check_drc):
    if check_drc is not None:
        if json_drc is not None and int(json_drc) != int(check_drc):
            return (max(int(json_drc), int(check_drc)), 'check_drc+json-disagree')
        return (int(check_drc), 'check_drc')
    if json_drc is not None:
        return (int(json_drc), 'stage-json')
    return (None, 'none')

def drc_from_stage_jsons(d: str):
    import glob as _g
    import json as _j
    final, iters = (None, {})
    for jf in _g.glob(os.path.join(d, '*.json')):
        try:
            for k, v in _j.load(open(jf)).items():
                if k == 'detailedroute__route__drc_errors':
                    final = int(v)
                elif k.startswith('detailedroute__route__drc_errors__iter:'):
                    iters[int(k.rsplit(':', 1)[1])] = int(v)
        except Exception:
            continue
    if final is not None:
        return final
    if iters:
        return iters[max(iters)]
    return None
