import os,json,pathlib,subprocess,datetime,hashlib
P=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert pathlib.Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=pathlib.Path('.specify/specs/003-gate-round-reduction-and-token-discipline');C=S/'notes/verification/reports/s76-t029-control';D=S/'notes/verification/reports/s77-analyzer-refresh';ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0');H=lambda b:hashlib.sha256(b).hexdigest()
def save(n,v):
 with (D/n).open('x') as f:json.dump(v,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
def raw(n,b):
 with (D/n).open('xb') as f:f.write(b);f.flush();os.fsync(f.fileno())
def run(stem,argv):
 rec=dict(argv=argv,cwd=str(P),envOverrides={'GIT_OPTIONAL_LOCKS':'0'},started=datetime.datetime.now(datetime.timezone.utc).isoformat())
 save(stem+'.invocation.json',rec)
 with (D/(stem+'.stdout')).open('xb') as out,(D/(stem+'.stderr')).open('xb') as err:
  p=subprocess.Popen(argv,cwd=P,env=ENV,stdout=out,stderr=err);rec['nativePid']=p.pid;save(stem+'.started.json',rec);print(json.dumps(rec),flush=True);rc=p.wait()
 rec.update(exit=rc,ended=datetime.datetime.now(datetime.timezone.utc).isoformat());save(stem+'.completed.json',rec);raw(stem+'.exit',str(rc).encode()+b'\n');print(json.dumps(rec),flush=True);return rc

import stat,re
V=S/'notes/verification';EXPECTED='03a560ada7b3f691a20cbc50a6fcbdf4d0ac9773f3f1fe3c309e9b3d70c82c6a'
def info(p):
 st=p.lstat();return dict(mode=stat.S_IMODE(st.st_mode),mtimeNs=st.st_mtime_ns,size=st.st_size,sha256=H(p.read_bytes()))
assert json.loads((C/'result.json').read_text())['accepted'] is True
assert not (V/'lock').exists() and not list((S/'notes/captures').glob('.capture.*'))
protected=[S/'tasks.md',S/'STATUS.md',pathlib.Path('scripts/sdd-analyze.sh'),pathlib.Path('tests/test-sdd-analyze.sh'),pathlib.Path('tests/test-gate-contracts.sh'),pathlib.Path('/Users/babar/projects/sdd-kit-public/.git/worktrees/003-gate-round-reduction-and-token-discipline/index')]
before={str(p):info(p) for p in protected};save('recovery-protected-before.json',before)
raw('recovery-tasks.before', (S/'tasks.md').read_bytes());raw('recovery-evidence.before',(S/'notes/evidence.md').read_bytes())
sequence=int((V/'sequence').read_text());assert sequence==867
ps=subprocess.check_output(['ps','-axo','pid,ppid,state,command'],cwd=P,env=ENV).decode();raw('recovery-processes-before.txt',ps.encode())
assert not [l for l in ps.splitlines() if any(x in l for x in ['bash scripts/spec-run.sh','bash scripts/spec-gate.sh','bash scripts/spec-floor.sh','control-once.py'])]
script=r"""set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"; phase="$3"; cap="${4:-}"
vf_binding_snapshot "$spec" "$own/recovery-bindings-$phase.nul"
vf_task_info "$own/recovery-bindings-$phase.nul" T031a5o1
printf '%s\n' "$VF_TASK_COMMAND" > "$own/recovery-command-$phase.txt"
vf_snapshot "$spec" "$PWD" "$PWD" "$own/recovery-inputs-$phase.nul" > "$own/recovery-source-$phase.txt"
if [[ -n "$cap" ]]; then
 vf_capture_check "$spec" "$cap" "$own/recovery-inputs-$phase.nul" integrity
 vf_capture_check "$spec" "$cap" "$own/recovery-inputs-$phase.nul" current
 vf_task_capture_matches "$own/recovery-bindings-$phase.nul" T031a5o1 "$spec/notes/captures/$cap"
fi
"""
raw('recovery-kernel.sh',script.encode())
assert run('recovery-kernel-before',['bash',str(D/'recovery-kernel.sh'),str(S.resolve()),str(D),'before'])==0
assert (D/'recovery-source-before.txt').read_text()==EXPECTED+'\n'
assert (D/'recovery-command-before.txt').read_bytes()==b'bash tests/test-sdd-analyze.sh\n'
assert {str(p):info(p) for p in protected}==before
assert run('recovery-native',['bash','scripts/spec-run.sh',str(S),'T031a5o1','--from-task','--no-tick','--summary'])==0
assert {str(p):info(p) for p in protected}==before
summary=(D/'recovery-native.stdout').read_bytes();m=re.fullmatch(rb'capture=(CAP-[1-9][0-9]*-[A-Za-z0-9]+) [^\r\n]*\n',summary);assert m,summary
cap=m.group(1).decode();raw('recovery-actual-capture.txt',cap.encode()+b'\n')
assert run('recovery-kernel-after',['bash',str(D/'recovery-kernel.sh'),str(S.resolve()),str(D),'after',cap])==0
assert (D/'recovery-source-after.txt').read_text()==EXPECTED+'\n'
d=S/'notes/captures'/cap;members=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']
assert set(p.name for p in d.iterdir())==set(members+['COMPLETE'])
seal=b'verification:1\n'+b''.join((H((d/n).read_bytes())+' '+n+'\n').encode() for n in members)
assert (d/'COMPLETE').read_bytes()==(V/'captures'/cap).read_bytes()==seal
fields=(d/'meta.nul').read_bytes().split(b'\0');assert fields.pop()==b'' and len(fields)%2==0 and len(set(fields[::2]))==len(fields[::2])
meta={a.decode():b.decode() for a,b in zip(fields[::2],fields[1::2])}
assert meta['id']==cap and int(meta['sequence'])==sequence+1 and int((V/'sequence').read_text())==sequence+1
assert meta['no_tick']=='1' and meta['exit']=='0' and meta['input_before']==meta['input_after']==EXPECTED
assert meta['repo']==meta['cwd']==str(P)
assert summary==(d/'summary.txt').read_bytes()
assert (d/'argv.nul').read_bytes()==(meta['shell']+'\0-o\0pipefail\0-c\0bash tests/test-sdd-analyze.sh\0').encode()
for phase in ['before','after']:
 assert (D/('recovery-inputs-'+phase+'.nul')).read_bytes()==(d/'inputs.nul').read_bytes()==(d/'inputs-after.nul').read_bytes()
 assert H((d/'inputs.nul').read_bytes())==EXPECTED
 assert (D/('recovery-bindings-'+phase+'.nul')).read_bytes()==(d/'bindings.nul').read_bytes()
 assert (D/('recovery-command-'+phase+'.txt')).read_bytes()==b'bash tests/test-sdd-analyze.sh\n'
output=(d/'output.log').read_bytes();assert H(output)==meta['output_digest'] and str(len(output))==meta['output_bytes']
suites=[l for l in output.decode().splitlines() if re.match(r'^\s+ok\s+test_',l)]
assert len(suites)==19 and b'19 passed' in output and not re.search(rb'^\s*(FAIL|not ok)\b',output,re.M)
rows=(d/'bindings.nul').read_bytes().split(b'\0');assert rows.pop()==b'' and len(rows)%12==0
rows=[[x.decode() for x in rows[i:i+12]] for i in range(0,len(rows),12)]
loc='tests/test-sdd-analyze.sh::test_verification_bindings';bound=[r for r in rows if r[0]=='binding' and r[2]=='T031a5o1']
assert all(len([r for r in bound if r[1]==fm and r[7]==loc])==1 for fm in ['FM-001','INV-005'])
assert {str(p):info(p) for p in protected}==before
assert (S/'tasks.md').read_bytes()==(D/'recovery-tasks.before').read_bytes()
evidence=(D/'recovery-evidence.before').read_bytes()+(f'\n## {cap} — {meta["end"]}\n\nCaptured run, exit {meta["exit"]}. Full log: `notes/captures/{cap}/output.log`.\n\n').encode()+summary
assert (S/'notes/evidence.md').read_bytes()==evidence
assert not (V/'lock').exists() and not list((S/'notes/captures').glob('.capture.*'))
body='Verification-Return: 1\nTask: T031a5o1\nCaptures: '+cap+'\nSummary: '+summary.decode().rstrip('\n')+'\nFailure modes:\nFM-001, '+loc+', '+cap+'\nINV-005, '+loc+', '+cap+'\n'
raw('worker-return.txt',body.encode())
save('result.json',dict(capture=cap,summary=summary.decode().rstrip('\n'),source=EXPECTED,metadata=meta,members={n:H((d/n).read_bytes()) for n in members},bindingRows=bound,suitePasses=suites,verified=True,accepted=False,taskBytesModeMtimeUnchanged=True,oneInvocation=True,automaticRetries=0,historicalStrictPreservation=False,workerReturnSHA256=H(body.encode()),oneTerminalLF=True,noFormalClearance=True))
print(body,flush=True)
