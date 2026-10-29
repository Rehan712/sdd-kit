"""Collect this completed run once; keep raw output on disk, never execute logs."""
from pathlib import Path
import datetime
import hashlib
import json
import os
import re
import shlex
import subprocess
import time

retry = Path(__file__).resolve().parent
owned = retry.parent
head = '781b963e6777b44059b24e696dafa37c69242a05'
tree = '43292032de54f25df06531471b07ada5da0becf0'
source = 'a7e7dd326b27c7565c26349485c440af26f718a7f16e400ea42ed6961d03cd1a'
env = dict(os.environ, GIT_OPTIONAL_LOCKS='0')
for key in ('GH_DEBUG', 'GIT_TRACE', 'GIT_TRACE_CURL', 'GIT_CURL_VERBOSE'):
    env.pop(key, None)
argv = ['bash', str(owned / 'collect.sh'), '40213790327', str(retry), head]
assert not (retry / 'collector-start-utc.txt').exists(), 'collection already attempted'
(retry / 'collector-argv.json').write_text(json.dumps(argv, indent=2) + '\n')
(retry / 'collector-argv.txt').write_text(shlex.join(argv) + '\n')
(retry / 'collector-start-utc.txt').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat() + '\n')
start = time.monotonic()
with (retry / 'collector.log').open('wb') as log:
    result = subprocess.run(argv, env=env, stdout=log, stderr=subprocess.STDOUT)
(retry / 'collector-exit-code.txt').write_text(str(result.returncode) + '\n')
(retry / 'collector-elapsed-seconds.txt').write_text(str(time.monotonic() - start) + '\n')
(retry / 'collector-end-utc.txt').write_text(datetime.datetime.now(datetime.timezone.utc).isoformat() + '\n')
assert result.returncode == 0, 'collector failed; inspect artifact files without printing raw logs'
run = json.loads((retry / 'run.json').read_bytes())
jobs = json.loads((retry / 'jobs.json').read_bytes())['jobs']
assert run['id'] == 40213790327 and run['run_attempt'] == 1
assert run['head_sha'] == head and run['head_branch'] == 'ci-snapshot/spec-003-20261025-s26'
assert run['event'] == 'pull_request' and run['status'] == 'completed' and run['conclusion'] == 'success'
assert run['path'] == '.github/workflows/ci.yml'
assert sorted(job['name'] for job in jobs) == sorted(['shellcheck', 'tests (ubuntu-latest)', 'tests (macos-latest)', 'tests-bash32'])
assert all(job['status'] == 'completed' and job['conclusion'] == 'success' for job in jobs)
merge_shas = set()
matrix = []
for job in jobs:
    safe = re.sub('[^A-Za-z0-9._-]', '_', job['name'])
    path = retry / ('job-' + safe + '.log')
    raw = path.read_bytes()
    fetched = set(re.findall(rb'git -c protocol.version=2 fetch .*? \+?([0-9a-f]{40}):refs/remotes/pull/21/merge', raw))
    checked_out = set(re.findall(rb'HEAD is now at ([0-9a-f]+)', raw))
    assert len(fetched) == len(checked_out) == 1, job['name']
    merge = fetched.pop().decode('ascii')
    assert merge.startswith(checked_out.pop().decode('ascii')), job['name']
    merge_shas.add(merge)
    matrix.append(dict(name=job['name'], id=job['id'], status=job['status'], conclusion=job['conclusion'], runner=job['runner_name'], labels=job['labels'], started_at=job['started_at'], completed_at=job['completed_at'], tested_merge=merge, raw_log=path.name, raw_bytes=len(raw), raw_sha256=hashlib.sha256(raw).hexdigest()))
assert len(merge_shas) == 1, 'jobs tested different merge commits'
merge = merge_shas.pop()
api_argv = ['gh', 'api', 'repos/Rehan712/sdd-kit/git/commits/' + merge]
(retry / 'merge-commit-api-argv.json').write_text(json.dumps(api_argv, indent=2) + '\n')
with (retry / 'tested-merge-commit.json').open('wb') as output, (retry / 'tested-merge-commit.err').open('wb') as error:
    api = subprocess.run(api_argv, env=env, stdout=output, stderr=error)
assert api.returncode == 0, 'tested merge API request failed'
commit = json.loads((retry / 'tested-merge-commit.json').read_bytes())
assert commit['sha'] == merge and commit['tree']['sha'] == tree
assert head in [parent['sha'] for parent in commit['parents']]
binding = json.loads((retry / 'verification-binding-before.json').read_bytes())
assert binding['source'] == source and binding['tree'] == tree and binding['mapping'] == 'PASS'
(retry / 'source-mapping.tsv').write_bytes((owned / 'source-mapping.tsv').read_bytes())
proof = dict(result='PASS', run_url=run['html_url'], run_id=run['id'], attempt=run['run_attempt'], snapshot_head=head, tested_merge=merge, tested_tree=commit['tree']['sha'], frozen_tree=tree, exact_tree_equality=True, source=source, source_paths=177, harness_records=8, document_records=4, source_mapping='source-mapping.tsv', matrix=matrix)
(retry / 'hosted-proof.json').write_text(json.dumps(proof, indent=2) + '\n')
print(json.dumps(proof, indent=2))
