import datetime, difflib, hashlib, json, os, pathlib, stat, subprocess, time

P = pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert pathlib.Path.cwd() == P and os.environ['GIT_OPTIONAL_LOCKS'] == '0'
S = pathlib.Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
D = S / 'notes/verification/reports/s59-analyzer-accept'
V = S / 'notes/verification'
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0')
EXPECTED = '7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff'
H = lambda b: hashlib.sha256(b).hexdigest()
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(name, value): (D / name).write_text(json.dumps(value, indent=2) + '\n')
def info(p):
    st = p.lstat()
    return dict(mode=stat.S_IMODE(st.st_mode), mtimeNs=st.st_mtime_ns, size=st.st_size,
                sha256=H(os.fsencode(os.readlink(p))) if p.is_symlink() else H(p.read_bytes()),
                type='symlink' if p.is_symlink() else 'file')
def git(*a): return subprocess.check_output(['git', *a], cwd=P, env=ENV).decode().strip()
def inventory():
    result = {}
    for root, dirs, files in os.walk('.', followlinks=False):
        for n in list(dirs):
            p = pathlib.Path(root) / n
            if p == D: dirs.remove(n)
            elif p.is_symlink(): result[str(p)] = info(p); dirs.remove(n)
        for n in files:
            p = pathlib.Path(root) / n
            result[str(p)] = info(p)
    return result
records = []
def run(label, argv):
    assert not (D / (label + '.start.json')).exists(), 'Refuse duplicate operation'
    rec = dict(label=label, argv=argv, cwd=str(P), envOverrides={'GIT_OPTIONAL_LOCKS':'0'}, started=now())
    with (D / (label + '.stdout')).open('xb') as out, (D / (label + '.stderr')).open('xb') as err:
        proc = subprocess.Popen(argv, cwd=P, env=ENV, stdout=out, stderr=err)
        rec['nativePid'] = proc.pid; save(label + '.start.json', rec)
        code = proc.wait()
    rec.update(ended=now(), exit=code)
    (D / (label + '.rc')).write_text(str(code) + '\n')
    for stream in ['stdout', 'stderr']: rec[stream + 'SHA256'] = H((D / (label + '.' + stream)).read_bytes())
    save(label + '.json', rec); records.append(rec); save('commands.json', records)
    print(json.dumps(rec), flush=True)
    return code
def meta(p):
    x = p.read_bytes().split(b'\0'); assert x.pop() == b'' and len(x) % 2 == 0
    assert len(set(x[::2])) == len(x[::2])
    return {a.decode(): b.decode() for a,b in zip(x[::2],x[1::2])}
def integrity(p, names):
    exact = ('verification:1\n' + ''.join(H((p/n).read_bytes()) + ' ' + n + '\n' for n in names)).encode()
    assert (p/'COMPLETE').read_bytes() == exact
    return H(exact)

assert not (D/'result.json').exists() and not (D/'accept.start.json').exists()
assert not (V/'lock').exists() and not list((S/'notes/captures').glob('.capture.*'))
assert git('rev-parse','HEAD') == '2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
assert git('branch','--show-current') == 'spec/003-gate-round-reduction-and-token-discipline'
idx = pathlib.Path(git('rev-parse','--git-path','index'))
protected = [idx, S/'STATUS.md', pathlib.Path('scripts/sdd-analyze.sh'), pathlib.Path('tests/test-sdd-analyze.sh'), pathlib.Path('tests/test-gate-contracts.sh')]
before_protected = {str(p):info(p) for p in protected}
assert info(idx)['sha256'] == 'c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700'
tasks = S/'tasks.md'; before_tasks = info(tasks)
assert before_tasks['sha256'] == '2380332731cede88cbcef942aed51847a80a1dd23166b03dc3b80f9381f1d9bd'
(D/'tasks.before').write_bytes(tasks.read_bytes())
raw = (D/'returned.txt').read_bytes()
assert raw == (D/'actual-worker-return.txt').read_bytes()
before = inventory(); save('inventory.before.json',before)
refs_before = git('for-each-ref','--format=%(refname) %(objectname)'); (D/'refs.before').write_text(refs_before+'\n')
events_before = set((V/'accept-events').iterdir()); receipts_before = set((V/'accepted/T031a5o1').iterdir())
save('baseline.json',dict(at=now(),protected=before_protected,tasks=before_tasks))
snap = '. scripts/lib.sh; . scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2" > "$3"'
assert run('source-before',['bash','-c',snap,'_',str(S.resolve()),str(D/'inputs-before.nul'),str(D/'source-before.txt')]) == 0
assert (D/'source-before.txt').read_text() == EXPECTED+'\n'
assert run('accept',['bash','scripts/spec-gate.sh','accept',str(S),'T031a5o1',str(D/'returned.txt')]) == 0
new_receipts = set((V/'accepted/T031a5o1').iterdir()) - receipts_before; assert len(new_receipts) == 1
accepted = new_receipts.pop(); digest = integrity(accepted,['meta.nul','return.txt','tasks.after','digests.nul'])
assert (accepted/'COMMITTED').read_text() == digest+'\n'
assert (accepted/'tasks.after').read_bytes() == tasks.read_bytes() and (accepted/'return.txt').read_bytes() == raw
final_events = set((V/'accept-events').iterdir()) - events_before; assert len(final_events) == 1
event = final_events.pop(); integrity(event,['meta.nul']); event_meta = meta(event/'meta.nul')
assert event_meta['outcome'] == 'accepted' and event_meta['class'] == 'none'
(D/'tasks.after').write_bytes(tasks.read_bytes())
(D/'tasks.diff').write_text(''.join(difflib.unified_diff((D/'tasks.before').read_text().splitlines(True),tasks.read_text().splitlines(True),fromfile='tasks.before',tofile='tasks.after')))
assert run('source-after',['bash','-c',snap,'_',str(S.resolve()),str(D/'inputs-after.nul'),str(D/'source-after.txt')]) == 0
assert (D/'source-after.txt').read_text() == EXPECTED+'\n'
assert {str(p):info(p) for p in protected} == before_protected
after = inventory(); save('inventory.after.json',after)
changes = {p:dict(before=a,after=after.get(p)) for p,a in before.items() if after.get(p)!=a}
additions = sorted(set(after)-set(before))
refs_after = git('for-each-ref','--format=%(refname) %(objectname)'); (D/'refs.after').write_text(refs_after+'\n')
assert git('rev-parse','HEAD') == '2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
assert not (V/'lock').exists()
result = dict(ended=now(),exit=0,task='T031a5o1',capture='CAP-845-hwbWOH',source=EXPECTED,accepted=True,
    acceptedReceipt=accepted.name,acceptedEvent=event.name,acceptedMeta=meta(accepted/'meta.nul'),
    beforeTasks=before_tasks,afterTasks=info(tasks),protectedUnchanged=True,currentSourceUnchanged=True,
    changedPreexisting=changes,newPaths=additions,unexpectedPreexistingChanges={p:a for p,a in changes.items() if p!=str(tasks)},
    strictGlobalRefsUnchanged=refs_before==refs_after,historicalStrictPreservation=False,
    allOtherOriginalWorktreeFilesPreserved=set(changes)=={str(tasks)},
    taskBytesFinalizedBeforeSnapshot=True,note='All task bytes now final after T029 control and T031a5o1 acceptance; no further task or Decisions edits before snapshot/CI/floor/gates.')
save('result.json',result)
print(json.dumps({k:v for k,v in result.items() if k not in ['changedPreexisting','newPaths']},indent=2),flush=True)
