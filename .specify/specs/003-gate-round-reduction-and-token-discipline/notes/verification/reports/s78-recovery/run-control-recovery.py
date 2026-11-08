import os,json,pathlib,subprocess,datetime,hashlib
P=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert pathlib.Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=pathlib.Path('.specify/specs/003-gate-round-reduction-and-token-discipline');C=S/'notes/verification/reports/s76-t029-control';D=S/'notes/verification/reports/s78-recovery';ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0');H=lambda b:hashlib.sha256(b).hexdigest()
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
cap=S/'notes/captures/CAP-867-DSKmw1';members=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt'];seal=b'verification:1\n'+b''.join((H((cap/n).read_bytes())+' '+n+'\n').encode() for n in members)
assert set(p.name for p in cap.iterdir())==set(members+['COMPLETE']) and (cap/'COMPLETE').read_bytes()==(S/'notes/verification/captures/CAP-867-DSKmw1').read_bytes()==seal
fields=(cap/'meta.nul').read_bytes().split(b'\0');assert fields.pop()==b'' and len(fields)%2==0;meta={a.decode():b.decode() for a,b in zip(fields[::2],fields[1::2])}
assert meta['no_tick']=='1' and meta['exit']=='0' and meta['input_before']==meta['input_after']=='03a560ada7b3f691a20cbc50a6fcbdf4d0ac9773f3f1fe3c309e9b3d70c82c6a'
assert b'18/18 passed' in (cap/'summary.txt').read_bytes()
rawreturn=(C/'returned.txt').read_bytes();assert rawreturn==(C/'actual-worker-return.txt').read_bytes()==(C/'canonical-worker-return.txt').read_bytes()==json.loads((C/'actual-message.json').read_text())['text'].encode()
assert H(rawreturn)=='edc4d49874807cfa996e3d35e53552d492dedde413f1109b157f682e896f15aa'
save('preaccept-capture-proof.json',dict(meta=meta,members={n:H((cap/n).read_bytes()) for n in members},sealedLedger=True,parentAuthenticatedLiteralReturn=True))
script='''set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"
vf_binding_snapshot "$spec" "$own/preaccept-bindings.nul"
vf_snapshot "$spec" "$PWD" "$PWD" "$own/preaccept-inputs.nul" > "$own/preaccept-source.txt"
vf_capture_check "$spec" CAP-867-DSKmw1 "$own/preaccept-inputs.nul" integrity
vf_capture_check "$spec" CAP-867-DSKmw1 "$own/preaccept-inputs.nul" current
vf_task_capture_matches "$own/preaccept-bindings.nul" T029 "$spec/notes/captures/CAP-867-DSKmw1"
'''
raw('preaccept-kernel.sh',script.encode());assert run('preaccept-kernel',['bash',str(D/'preaccept-kernel.sh'),str(S.resolve()),str(D)])==0
assert (D/'preaccept-source.txt').read_bytes()==b'03a560ada7b3f691a20cbc50a6fcbdf4d0ac9773f3f1fe3c309e9b3d70c82c6a\n'
assert not (C/'result.json').exists() and not (C/'reject.start.json').exists() and not (C/'accept.start.json').exists()
rc=run('control-wrapper',['python3',str(C/'control-once.py')]);raise SystemExit(rc)
