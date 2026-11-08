#!/usr/bin/env python3
import collections
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
AUDIT = Path(__file__).resolve().parent
PLATFORM = AUDIT.parent
HEAD = '5aee77672d03a2c7811e28e55172817da6dee012'
TREE = 'd685ec420ba6ce338e72727638e1ccff0bbb3846'
SOURCE = 'c7a82b3ae3b900dcb02a4839decad74db1a13457c5bab9ff859625a5357f0be6'
PARENT = '2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
BRANCH = 'ci-snapshot/spec-003-20261025-s26'
REPO = 'Rehan712/sdd-kit'
RESULT = {'status': 'INCOMPLETE', 'collector_exit': None, 'binding_before': 'NOT_RUN', 'binding_after': 'NOT_RUN', 'scope': 'Actual hosted collection only; no floor or gates executed', 'head': HEAD, 'tree': TREE, 'source': SOURCE, 'audit_dir': str(AUDIT)}


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def write(path, value):
    with path.open('x') as f:
        f.write(json.dumps(value, indent=2) + '\n')


def run(name, argv, env=None, output=None):
    start = now()
    stdout = output or AUDIT / (name + '.stdout')
    stderr = AUDIT / (name + '.stderr')
    with stdout.open('xb') as out, stderr.open('xb') as err:
        done = subprocess.run(argv, cwd=ROOT, env=env, stdout=out, stderr=err)
    write(AUDIT / (name + '.receipt.json'), {'argv': argv, 'cwd': str(ROOT), 'started_utc': start, 'completed_utc': now(), 'exit': done.returncode, 'stdout': str(stdout), 'stderr': str(stderr)})
    return done.returncode


def require_run(name, argv, env=None, output=None):
    rc = run(name, argv, env, output)
    assert rc == 0, name + ' exited ' + str(rc) + '; see private stdout/stderr receipts'


def api(name, endpoint, env):
    output = AUDIT / (name + '.json')
    require_run(name, ['gh', 'api', endpoint], env, output)
    return json.loads(output.read_bytes())


def compatible(run):
    return (run.get('head_sha') == HEAD and run.get('head_branch') == BRANCH and
            run.get('event') == 'pull_request' and run.get('path') == '.github/workflows/ci.yml' and
            run.get('status') == 'completed' and
            any(p.get('number') == 21 for p in run.get('pull_requests', [])))


def binding(phase):
    name = 'binding-' + phase
    rc = run(name, ['bash', str(AUDIT / ('binding-verifier-' + phase + '.sh'))])
    RESULT['binding_' + phase] = 'PASS' if rc == 0 else 'FAIL'
    assert rc == 0, name + ' strict verifier failed; no retry permitted'
    proof = json.loads((AUDIT / ('verification-' + phase + '.json')).read_bytes())
    assert proof['source'] == SOURCE and proof['tree'] == TREE and proof['parent'] == PARENT
    freeze = Path(json.loads((PLATFORM / 'summary.json').read_bytes())['manifest'])
    actual = (AUDIT / ('inputs-' + phase + '.nul')).read_bytes()
    assert actual == freeze.read_bytes()
    assert hashlib.sha256(actual).hexdigest() == SOURCE
    fields = actual.split(b'\0')[:-1]
    assert len(fields) % 6 == 0
    counts = collections.Counter(fields[i].decode() for i in range(0, len(fields), 6))
    assert counts['path'] == 177 and counts['harness'] == 8 and counts['document'] == 4
    write(AUDIT / ('manifest-' + phase + '.json'), {'source': SOURCE, 'builder_freeze': str(freeze), 'byte_for_byte_equal': True, 'record_counts': dict(counts)})


def main():
    assert Path.cwd() == ROOT
    os.umask(0o077)
    for phase in ('before', 'after'):
        require_run('syntax-' + phase, ['bash', '-n', str(AUDIT / ('binding-verifier-' + phase + '.sh'))])
    require_run('syntax-collector', ['bash', '-n', str(PLATFORM / 'collect.sh')])
    require_run('syntax-driver', ['python3', '-c', 'import ast,sys; ast.parse(open(sys.argv[1]).read())', str(Path(__file__).resolve())])
    invocation = json.loads((AUDIT / 'invocation.json').read_bytes())
    assert hashlib.sha256((PLATFORM / 'collect.sh').read_bytes()).hexdigest() == invocation['collector_sha256']
    substitutions = json.loads((AUDIT / 'substitutions.json').read_bytes())
    original = (PLATFORM / 'verify-prepublish.sh').read_text()
    assert hashlib.sha256(original.encode()).hexdigest() == substitutions['original_sha256']
    for phase in ('before', 'after'):
        copied = (AUDIT / ('binding-verifier-' + phase + '.sh')).read_text()
        for item in substitutions['substitutions'][phase]:
            assert original.count(item['original']) == item['count'] == 1
            assert copied.count(item['replacement']) == 1
            copied = copied.replace(item['replacement'], item['original'])
        assert copied == original, 'verifier logic changed'
    # Read the stored account credential privately; never switch the active account.
    auth_start = now()
    auth = subprocess.run(['gh', 'auth', 'token', '--hostname', 'github.com', '--user', 'Rehan712'], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    write(AUDIT / 'credential.receipt.json', {'argv': ['gh', 'auth', 'token', '--hostname', 'github.com', '--user', 'Rehan712'], 'started_utc': auth_start, 'completed_utc': now(), 'exit': auth.returncode, 'handling': 'Captured in subprocess memory only; no token/auth-config output persisted'})
    assert auth.returncode == 0 and auth.stdout.strip(), 'stored Rehan712 credential unavailable'
    env = dict(os.environ, GH_TOKEN=auth.stdout.decode().strip(), GH_PAGER='cat', PAGER='cat', GIT_OPTIONAL_LOCKS='0')
    del auth
    endpoint = 'repos/' + REPO + '/actions/workflows/ci.yml/runs?head_sha=' + HEAD + '&event=pull_request&branch=' + BRANCH + '&status=completed&per_page=100'
    candidates = api('candidates', endpoint, env)
    matches = [r for r in candidates['workflow_runs'] if compatible(r)]
    assert matches, 'No observed compatible completed run; no polling or guessed run ID used'
    selected = max(matches, key=lambda r: (r['created_at'], r['id'], r['run_attempt']))
    write(AUDIT / 'selection.json', {'selected_utc': now(), 'query_count': 1, 'compatible_count': len(matches), 'selection_rule': 'latest observed compatible completed run by created_at/id/attempt', 'run_id': selected['id'], 'attempt': selected['run_attempt'], 'url': selected['html_url'], 'run': selected})
    RESULT.update(run_id=selected['id'], attempt=selected['run_attempt'], url=selected['html_url'])
    assert selected['conclusion'] == 'success', 'Observed current completed run was not successful'
    print('Selected actual completed run ' + str(selected['id']) + ', attempt ' + str(selected['run_attempt']), flush=True)
    binding('before')
    print('Strict binding BEFORE: PASS', flush=True)
    collection = AUDIT / ('hosted-' + str(selected['id']) + '-attempt-' + str(selected['run_attempt']))
    assert not collection.exists(), 'Fresh collection output already exists'
    # Atomic reservation ensures the unchanged collector cannot overwrite old proof.
    collection.mkdir(mode=0o700)
    write(AUDIT / 'collection-reservation.json', {'path': str(collection), 'reserved_utc': now(), 'previously_absent': True, 'entries_before_collector': []})
    assert not any(collection.iterdir())
    rc = run('collector', ['bash', str(PLATFORM / 'collect.sh'), str(selected['id']), str(collection), HEAD], env)
    RESULT.update(collector_exit=rc, collection_dir=str(collection))
    assert rc == 0, 'unchanged collector failed; no retry permitted'
    hosted = json.loads((collection / 'run.json').read_bytes())
    assert compatible(hosted) and hosted['conclusion'] == 'success'
    assert hosted['id'] == selected['id'] and hosted['run_attempt'] == selected['run_attempt']
    jobs = json.loads((collection / 'jobs.json').read_bytes())
    assert jobs['total_count'] == len(jobs['jobs']) == 4
    expected = {'shellcheck', 'tests (ubuntu-latest)', 'tests (macos-latest)', 'tests-bash32'}
    assert {j['name'] for j in jobs['jobs']} == expected
    evidence = []
    merges = set()
    for job in jobs['jobs']:
        assert job['status'] == 'completed' and job['conclusion'] == 'success'
        assert job['head_sha'] == HEAD and job['run_id'] == selected['id']
        safe = re.sub('[^A-Za-z0-9._-]', '_', job['name'])
        log_path = collection / ('job-' + safe + '.log')
        log = log_path.read_bytes().decode('utf-8', errors='replace')
        fetched = set(re.findall(r'git -c protocol.version=2 fetch [^\r\n]* \+?([0-9a-f]{40}):refs/remotes/pull/21/merge', log))
        checkout = set(re.findall(r'HEAD is now at ([0-9a-f]+)', log))
        assert len(fetched) == len(checkout) == 1, job['name'] + ': missing/ambiguous checkout merge SHA evidence'
        full = next(iter(fetched))
        assert full.startswith(next(iter(checkout))), job['name'] + ': checkout/fetch SHA differs'
        assert 'refs/remotes/pull/21/merge' in log
        merges.add(full)
        evidence.append({'id': job['id'], 'name': job['name'], 'status': job['status'], 'conclusion': job['conclusion'], 'url': job['html_url'], 'merge_sha': full, 'checkout_short': next(iter(checkout)), 'raw_log': str(log_path), 'raw_log_sha256': hashlib.sha256(log_path.read_bytes()).hexdigest()})
    assert len(merges) == 1, 'Jobs tested different merge commits'
    merge = next(iter(merges))
    commit = api('tested-merge-commit', 'repos/' + REPO + '/git/commits/' + merge, env)
    assert commit['sha'] == merge and commit['tree']['sha'] == TREE
    parents = [p['sha'] for p in commit['parents']]
    assert len(parents) == 2 and HEAD in parents, 'Merge does not bind final snapshot parent'
    snapshot = api('final-snapshot-commit', 'repos/' + REPO + '/git/commits/' + HEAD, env)
    assert snapshot['sha'] == HEAD and snapshot['tree']['sha'] == TREE
    assert [p['sha'] for p in snapshot['parents']] == [PARENT]
    downloads = re.findall(r'log-fetch-exit=(\d+) log-bytes=(\d+)', (AUDIT / 'collector.stdout').read_text())
    assert len(downloads) == 4 and all(int(rc) == 0 and int(size) > 0 for rc, size in downloads)
    write(AUDIT / 'download-exits.json', {'ordered_jobs': [j['name'] for j in jobs['jobs']], 'downloads': [{'exit': int(rc), 'bytes': int(size)} for rc, size in downloads]})
    write(AUDIT / 'hosted-assertions.json', {'run_id': selected['id'], 'attempt': selected['run_attempt'], 'conclusion': hosted['conclusion'], 'jobs': evidence, 'merge_sha': merge, 'merge_tree': TREE, 'merge_parents': parents, 'snapshot_parent': PARENT, 'source': SOURCE, 'source_binding': '177 path + 8 harness + 4 document mappings validated by unchanged strict verifier logic against builder frozen manifest'})
    RESULT.update(jobs=evidence, merge_sha=merge, merge_tree=TREE, merge_parents=parents, snapshot_parent=PARENT)
    binding('after')
    assert (AUDIT / 'inputs-before.nul').read_bytes() == (AUDIT / 'inputs-after.nul').read_bytes()
    assert hashlib.sha256((PLATFORM / 'collect.sh').read_bytes()).hexdigest() == invocation['collector_sha256']
    assert hashlib.sha256((PLATFORM / 'verify-prepublish.sh').read_bytes()).hexdigest() == substitutions['original_sha256']
    print('Strict binding AFTER: PASS; all four hosted jobs passed with identical source-bound merge tree', flush=True)
    RESULT['status'] = 'PASS'


try:
    main()
except Exception as error:
    RESULT.update(status='FAIL', failure=str(error), failure_type=type(error).__name__)
finally:
    RESULT['completed_utc'] = now()
    write(AUDIT / 'result.json', RESULT)
    content = '# Hosted CI collection handoff\n\n' + json.dumps(RESULT, indent=2) + '\n\nNo CI rerun, floor, captures, full suites or gates were launched. Existing source, helpers and historical artifacts were preserved. Floor waiter activity was outside this collection; excluded capture/floor bookkeeping was not required to remain frozen.\n'
    with (AUDIT / 'handoff.md').open('x') as f:
        f.write(content)
    manifest = {str(f.relative_to(AUDIT)): {'sha256': hashlib.sha256(f.read_bytes()).hexdigest(), 'bytes': f.stat().st_size} for f in sorted(AUDIT.rglob('*')) if f.is_file()}
    write(AUDIT / 'artifact-sha256.json', manifest)
    reports = PLATFORM.parent.parent / 'reports'
    prefix = 's27-final-hosted-' + AUDIT.name.removeprefix('hosted-audit-')
    write(reports / (prefix + '-result-provenance.json'), {'completed_utc': RESULT['completed_utc'], 'status': RESULT['status'], 'result': str(AUDIT / 'result.json'), 'result_sha256': hashlib.sha256((AUDIT / 'result.json').read_bytes()).hexdigest(), 'handoff': str(AUDIT / 'handoff.md'), 'handoff_sha256': hashlib.sha256((AUDIT / 'handoff.md').read_bytes()).hexdigest(), 'artifact_manifest': str(AUDIT / 'artifact-sha256.json'), 'artifact_manifest_sha256': hashlib.sha256((AUDIT / 'artifact-sha256.json').read_bytes()).hexdigest()})
    print(json.dumps({k: v for k, v in RESULT.items() if k != 'jobs'}, indent=2), flush=True)
sys.exit(0 if RESULT['status'] == 'PASS' else 1)
