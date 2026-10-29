#!/usr/bin/env bash
# Read-only binding check; outputs stay in this spec's excluded verification dir.
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
out="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s26"
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
source_id="$(vf_snapshot "$s" "$PWD" "$PWD" "$out/publication-20261025T164211Z/inputs-current-after.nul")"
[[ "$source_id" == a7e7dd326b27c7565c26349485c440af26f718a7f16e400ea42ed6961d03cd1a ]]
python3 - "$out" <<'PY'
from pathlib import Path
import collections
import csv
import hashlib
import json
import os
import subprocess
import sys

owned = Path(sys.argv[1])
root = Path.cwd()
scratch = Path((owned / 'scratch-path.txt').read_text().strip())
snapshot = scratch / 'snapshot'
summary = json.loads((owned / 'summary.json').read_text())
before = json.loads((owned / 'state-before.json').read_text())

def git(*args, **kwargs):
    return subprocess.check_output(['git', *args], **kwargs)

index = Path(before['index_path'])
head_file = Path(git('rev-parse', '--git-path', 'HEAD').decode().strip())
after = dict(head=git('rev-parse', 'HEAD').decode().strip(), index_path=str(index),
             index_sha256=hashlib.sha256(index.read_bytes()).hexdigest(),
             index_bytes=index.stat().st_size, index_mtime_ns=index.stat().st_mtime_ns,
             head_file_sha256=hashlib.sha256(head_file.read_bytes()).hexdigest(),
             refs_sha256=hashlib.sha256(git('show-ref')).hexdigest())
assert all(after[k] == before[k] for k in before if k != 'refs_sha256'), 'HEAD/index changed'
assert (owned / 'publication-20261025T164211Z/inputs-current-after.nul').read_bytes() == (snapshot / 'inputs.nul').read_bytes()
assert hashlib.sha256((snapshot / 'inputs.nul').read_bytes()).hexdigest() == summary['source']
assert git('ls-tree', '-r', '-z', summary['tree']) == (snapshot / 'tree.nul').read_bytes()
env = dict(os.environ, GIT_INDEX_FILE=str(snapshot / 'index'))
assert git('write-tree', env=env).decode().strip() == summary['tree']
subprocess.run(['git', 'diff', '--cached', '--quiet', summary['parent'], '--'], check=True)
origin = json.loads((owned / 'helper-origin.json').read_text())
assert hashlib.sha256(Path(origin['path']).read_bytes()).hexdigest() == origin['sha256']
old = Path(origin['path']).read_text()
assert (owned / 'build-snapshot.sh').read_text() == old.replace('vf_bookkeeping_path "$p" ||', 'vf_bookkeeping_path "$p" "$s" ||')
collector = json.loads((owned / 'collector-origin.json').read_text())
assert hashlib.sha256(Path(collector['path']).read_bytes()).hexdigest() == collector['sha256']
entries = {}
for record in (snapshot / 'tree.nul').read_bytes().split(b'\0')[:-1]:
    header, path = record.split(b'\t', 1)
    mode, kind, oid = header.decode().split()
    entries[os.fsdecode(path)] = (mode, kind, oid)
rows = list(csv.DictReader((owned / 'source-mapping.tsv').open(), delimiter='\t'))
assert len(rows) == summary['path_records_verified'] == 177
for row in rows:
    path = root / row['path']
    content = path.read_bytes()
    mode = '100755' if os.access(path, os.X_OK) else '100644'
    oid = hashlib.sha1(b'blob ' + str(len(content)).encode() + b'\0' + content).hexdigest()
    assert entries[row['path']] == (mode, 'blob', oid)
    assert mode == row['mode'] and oid == row['git_blob']
    assert hashlib.sha256(content).hexdigest() == row['raw_sha256']
    assert len(content) == int(row['bytes'])
mapping = {r['path']: r for r in rows}
fields = (snapshot / 'inputs.nul').read_bytes().split(b'\0')[:-1]
assert len(fields) % 6 == 0
for i in range(0, len(fields), 6):
    kind, path, value, mode, digest, target = fields[i:i+6]
    if kind == b'path':
        row = mapping[os.fsdecode(path)]
        assert value == b'file' and mode.decode() == row['mode']
        assert digest.decode() == row['semantic_sha256']
    elif kind in (b'harness', b'document'):
        relative = str(Path(os.fsdecode(path)).relative_to(root))
        key = 'raw_sha256' if kind == b'harness' else 'semantic_sha256'
        assert mapping[relative][key] == value.decode()
result = dict(source=summary['source'], tree=summary['tree'], parent=summary['parent'],
              source_files=177, harness_records=8, document_records=4,
              mapping='PASS', parent_index='PASS', head_index='UNCHANGED',
              tree_modes=dict(collections.Counter(e[0] for e in entries.values())),
              state_after=after,
              global_refs_changed_since_baseline=after['refs_sha256'] != before['refs_sha256'])
(owned / 'publication-20261025T164211Z/verification-binding-after.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
PY
