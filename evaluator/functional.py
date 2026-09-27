"""Task-declared RTL equivalence and simulation checks."""
import os

def lec_fn(golden: dict, gate: dict, top: str) -> dict:
    import subprocess
    os.makedirs('/tmp/lec/gold', exist_ok=True)
    os.makedirs('/tmp/lec/gate', exist_ok=True)
    for name, text in golden.items():
        open(f'/tmp/lec/gold/{name}', 'w').write(text)
    for name, text in gate.items():
        open(f'/tmp/lec/gate/{name}', 'w').write(text)
    cfg = ['[gold]']
    cfg += [f'read_verilog /tmp/lec/gold/{n}' for n in golden]
    cfg += [f'prep -top {top}', 'memory_map', '', '[gate]']
    cfg += [f'read_verilog /tmp/lec/gate/{n}' for n in gate]
    cfg += [f'prep -top {top}', 'memory_map', '', '[strategy basic]', 'use sat', 'depth 5', '']
    open('/tmp/lec/task.eqy', 'w').write('\n'.join(cfg) + '\n')
    import sys as _sys
    p = subprocess.run([_sys.executable, '/usr/local/bin/eqy', '-f', '-d', '/tmp/lec/run', '/tmp/lec/task.eqy'], capture_output=True, text=True, timeout=1500)
    out = {'rc': p.returncode, 'tail': p.stdout[-800:] + p.stderr[-300:]}
    if p.returncode == 0:
        out['lec_equivalent'] = 1
    elif 'partition' in p.stdout or 'unproved' in p.stdout.lower() or 'not equivalent' in p.stdout.lower():
        out['lec_equivalent'] = 0
    return out

def tb_fn(files: dict, tb_top: str) -> dict:
    import subprocess
    os.makedirs('/tmp/tb', exist_ok=True)
    for name, text in files.items():
        open(f'/tmp/tb/{name}', 'w').write(text)
    srcs = [f'/tmp/tb/{n}' for n in files]
    c = subprocess.run(['iverilog', '-g2005', '-s', tb_top, '-o', '/tmp/tb/sim', *srcs], capture_output=True, text=True, timeout=600)
    if c.returncode != 0:
        return {'rc': c.returncode, 'tail': c.stderr[-500:]}
    p = subprocess.run(['vvp', '/tmp/tb/sim'], capture_output=True, text=True, timeout=1200)
    out = {'rc': p.returncode, 'tail': p.stdout[-500:] + p.stderr[-200:]}
    if p.returncode == 0 and 'TB_PASS' in p.stdout:
        out['tb_pass'] = 1
    elif 'TB_FAIL' in p.stdout:
        out['tb_pass'] = 0
    return out
