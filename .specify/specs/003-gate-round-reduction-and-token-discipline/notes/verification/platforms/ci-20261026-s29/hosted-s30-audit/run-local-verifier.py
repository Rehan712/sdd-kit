import datetime,hashlib,json,os,subprocess,sys,time
from pathlib import Path
root=Path.cwd(); a=Path(__file__).resolve().parent; p=a.parent
assert str(root)=="/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline"
phase=sys.argv[1]; assert phase in ("before","after")
env={k:v for k,v in os.environ.items() if k in ("PATH","HOME","TMPDIR","LANG","LC_ALL","SHELL","USER","LOGNAME")}; env["GIT_OPTIONAL_LOCKS"]="0"
assert not any(k.startswith(("GH_","GITHUB_","GIT_TRACE")) for k in env)
protected=json.loads((p/"protected-before.json").read_text())
state={}
for key in ("index","head_file","status","tasks"):
 f=Path(protected[key]["path"]); st=f.stat()
 state[key]=dict(path=str(f),sha256=hashlib.sha256(f.read_bytes()).hexdigest(),mtime_ns=st.st_mtime_ns,size=st.st_size,mode=oct(st.st_mode & 0o777))
 assert state[key]==protected[key],key+" differs from frozen protected state"
for name in ("verify-prepublish.sh","collect.sh"):
 f=p/name;st=f.stat();state[name]=dict(sha256=hashlib.sha256(f.read_bytes()).hexdigest(),mtime_ns=st.st_mtime_ns,mode=oct(st.st_mode & 0o777))
(a/("protected-"+phase+".json")).write_text(json.dumps(state,indent=2)+"\n")
argv=["bash",str(a/("verify-"+phase+".sh"))];started=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic()
r=subprocess.run(argv,cwd=root,env=env,capture_output=True)
(a/("verify-"+phase+".stdout")).write_bytes(r.stdout);(a/("verify-"+phase+".stderr")).write_bytes(r.stderr)
receipt=dict(argv=argv,started=started,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-t,3),exit=r.returncode,environment="allowlist; no credential/debug/trace variables")
(a/("verify-"+phase+"-execution.json")).write_text(json.dumps(receipt,indent=2)+"\n")
assert r.returncode==0,"strict verifier failed; see audit-local stderr"
frozen=Path(json.loads((p/"summary.json").read_text())["manifest"]).read_bytes()
for name in ("inputs-prepared.nul","inputs-completed.nul"):
 assert (p/name).read_bytes()==frozen,name+" differs from frozen manifest"
assert (a/("inputs-"+phase+".nul")).read_bytes()==frozen
if phase=="after":
 assert state==json.loads((a/"protected-before.json").read_text())
 assert (a/"inputs-before.nul").read_bytes()==(a/"inputs-after.nul").read_bytes()
print(json.dumps(dict(phase=phase,exit=r.returncode,seconds=receipt["seconds"],source=hashlib.sha256(frozen).hexdigest(),protected="UNCHANGED",frozen_manifest="BYTE_IDENTICAL")))
