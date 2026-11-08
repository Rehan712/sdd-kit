"""Offline binding controls only; synthetic fixtures, no GitHub calls."""
from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile

owned = Path(__file__).resolve().parent
scratch = Path(tempfile.mkdtemp(prefix='collector-test-', dir=owned / 'hosted-40213790327-retry1'))
bin_dir = scratch / 'bin'
bin_dir.mkdir()
head = 'a' * 40
merge = 'b' * 40
tree = json.loads((owned / 'summary.json').read_text())['tree']
( bin_dir / 'gh').write_text('#!' + sys.executable + '\n' + '''
import json, os, stat, sys
endpoint = sys.argv[2]
case = os.environ['FIXTURE_CASE']
head = 'a' * 40
merge = 'b' * 40
tree = os.environ['FIXTURE_TREE']
if '--allow-escape-sequences' in sys.argv:
    assert '/actions/jobs/' in endpoint and endpoint.endswith('/logs')
    assert stat.S_ISREG(os.fstat(1).st_mode), 'raw logs must go to an artifact file'
if '/actions/runs/' in endpoint and endpoint.endswith('/jobs?per_page=50'):
    names = ['shellcheck', 'tests (ubuntu-latest)', 'tests (macos-latest)', 'tests-bash32']
    print(json.dumps({'jobs': [{'id': i, 'name': name, 'status': 'completed',
        'conclusion': 'failure' if case == 'bad-job' and i == 1 else 'success',
        'runner_name': 'offline', 'labels': ['offline'], 'started_at': '',
        'completed_at': '', 'steps': []} for i, name in enumerate(names, 1)]}))
elif '/actions/runs/' in endpoint:
    print(json.dumps({'status': 'completed', 'conclusion': 'success', 'event': 'pull_request',
        'head_sha': 'c' * 40 if case == 'bad-head' else head, 'run_attempt': 1}))
elif '/actions/jobs/' in endpoint:
    if '--allow-escape-sequences' not in sys.argv:
        raise SystemExit('the response contains terminal escape sequences; pass --allow-escape-sequences to output it anyway')
    if case == 'download-failure':
        raise SystemExit(23)
    if case == 'escape-guard':
        sys.stdout.write('\\x1b[31mRunner Image: offline\\x1b[0m\\r\\n')
    print('HEAD is now at ' + merge[:7])
    if case != 'missing-checkout':
        print('git -c protocol.version=2 fetch origin +' + merge + ':refs/remotes/pull/1/merge')
elif '/git/commits/' in endpoint:
    print(('d' * 40 if case == 'bad-tree' else tree) if sys.argv[-1] == '.tree.sha' else head)
else:
    raise SystemExit('unexpected offline endpoint: ' + endpoint)
''')
(bin_dir / 'gh').chmod(0o755)
results = []
for case, expected in [('good', 0), ('bad-head', 1), ('bad-tree', 1), ('bad-job', 1), ('missing-checkout', 1), ('escape-guard', 0), ('download-failure', 1)]:
    env = dict(os.environ, PATH=str(bin_dir) + os.pathsep + os.environ['PATH'],
               FIXTURE_CASE=case, FIXTURE_TREE=tree)
    result = subprocess.run(['bash', str(owned / 'collect.sh'), '1', str(scratch / case), head],
                            cwd=Path.cwd(), env=env, text=True, capture_output=True)
    (scratch / (case + '.log')).write_text(result.stdout + result.stderr)
    assert result.returncode == expected, (case, result.returncode, result.stdout, result.stderr)
    if case == 'escape-guard':
        raw = (b'\x1b[31mRunner Image: offline\x1b[0m\r\nHEAD is now at ' + merge[:7].encode()
               + b'\ngit -c protocol.version=2 fetch origin +' + merge.encode() + b':refs/remotes/pull/1/merge\n')
        logs = list((scratch / case).glob('job-*.log'))
        assert len(logs) == 4 and all(log.read_bytes() == raw for log in logs)
        assert all(ord(c) >= 32 or c in '\t\n' for c in result.stdout + result.stderr)
    if case == 'download-failure':
        assert result.stdout.count('log-fetch-exit=23') == 4
        assert 'collect result: FAIL' in result.stdout
    results.append(case + ': PASS')
(owned / 'collector-self-check.log').write_text('\n'.join(results) + '\n')
print('\n'.join(results))
print('fixtures: ' + str(scratch))
