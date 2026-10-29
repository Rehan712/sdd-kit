from pathlib import Path
import os,stat,hashlib,json,subprocess,datetime,re,difflib
root=Path.cwd();s=root/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';o=r/'s50-o034-qualified-tools-verification';base=json.loads((o/'inventory.before.json').read_text());env=dict(os.environ,GIT_OPTIONAL_LOCKS='0');h=lambda b:hashlib.sha256(b).hexdigest();now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
def info(p):
 if not p.exists() and not p.is_symlink():return {'missing':True}
 st=p.lstat();v={'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns,'size':st.st_size,'kind':'symlink' if p.is_symlink() else 'file'}
 if p.is_symlink():v['target']=os.readlink(p)
 else:v['sha256']=h(p.read_bytes())
 return v
def run(argv):return subprocess.check_output(argv,cwd=root,env=env)
changes={k:{'before':v,'after':info(root/k)} for k,v in base['files'].items() if info(root/k)!=v};external={k:{'before':v,'after':info(Path(k))} for k,v in base['external'].items() if info(Path(k))!=v};new=[]
for directory,ds,fs in os.walk(root):
 ds[:]=[x for x in ds if x!='.git']
 for n in ds[:]:
  if (Path(directory)/n).is_symlink():fs.append(n);ds.remove(n)
 for n in fs:
  rel=str((Path(directory)/n).relative_to(root))
  if rel not in base['files']:new.append(rel)
owned=str(o.relative_to(root))+'/';parent=str((r/'s50-o034-verification-invocation.json').relative_to(root));unexpected=[x for x in new if not x.startswith(owned) and x!=parent]
(o/'protection-pre-capture.json').write_text(json.dumps({'at':now(),'changed_preexisting':changes,'changed_external':external,'new_paths':new,'unexpected_new_paths':unexpected},indent=2)+'\n');assert not changes and not external and not unexpected
# Confirm the saved exact three-file repair, including the unchecked task and cleared old Evidence.
app=json.loads((r/'s49-o034-qualified-tools-fix/application.json').read_text());diff='';proof={}
for rel,d in app['ownedChanges'].items():
 old=(r/'s49-o034-qualified-tools-fix/before'/rel).read_bytes();current=(root/rel).read_bytes();assert h(current)==d['sha256'];proof[rel]={'before_sha256':h(old),'current_sha256':h(current)};diff+=''.join(difflib.unified_diff(old.decode().splitlines(True),current.decode().splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
assert diff==(r/'s49-o034-qualified-tools-fix/repair.diff').read_text()
tasks=(s/'tasks.md').read_text();task=tasks[tasks.index('- [ ] **T031a5o1**'):];task=task[:task.index('\n- [x] **T031a6**')];assert '*Evidence:*' not in task
(o/'repair-observation.json').write_text(json.dumps({'exact_three_file_diff_matches':True,'sources':proof,'task_unchecked':True,'live_task_evidence_absent':True,'OP26_report_sha256':h((r/'opponent-round26.md').read_bytes()),'formal_verdict':'CHALLENGED','no_next_round_authorized':True},indent=2)+'\n')
ps=run(['ps','-axo','pid=,ppid=,args=']);(o/'processes.pre-capture.txt').write_bytes(ps);processes={}
for line in ps.decode(errors='replace').splitlines():
 a=line.strip().split(None,2)
 if len(a)==3:processes[int(a[0])]=(int(a[1]),a[2])
ancestors={os.getpid()};pid=os.getpid()
while pid in processes and processes[pid][0] not in ancestors:
 pid=processes[pid][0];ancestors.add(pid)
matches=[{'pid':pid,'ppid':ppid,'args':args} for pid,(ppid,args) in processes.items() if pid not in ancestors and re.search(r'(?:^|[\s/])(spec-run\.sh|spec-gate\.sh|spec-floor\.sh|test-sdd-analyze\.sh)(?:\s|$)',args)]
locks=[str(x.relative_to(root)) for x in (s/'notes/verification').rglob('*') if x.name in ['lock','index.lock'] or x.name.endswith('.lock')]
pending=[str(x.relative_to(root)) for x in (s/'notes/captures').glob('.capture.*')]+[str(x.relative_to(root)) for x in (s/'notes/verification').glob('bindings.*')]
pre={'at':now(),'cwd':str(root),'git_optional_locks':'0','process_argv':['ps','-axo','pid=,ppid=,args='],'matching_capture_test_floor_gate_processes':matches,'excluded_current_invocation_ancestors':sorted(ancestors),'locks':locks,'pending_capture_or_binding_paths':pending,'sequence':(s/'notes/verification/sequence').read_text(),'capture_names':sorted(x.name for x in (s/'notes/captures').iterdir()),'historical_incomplete_captures':[x.name for x in (s/'notes/captures').glob('CAP-*') if x.is_dir() and not (x/'COMPLETE').exists()]}
(o/'capture-preflight.json').write_text(json.dumps(pre,indent=2)+'\n');assert not matches and not locks and not pending
# Actual vf_snapshot under owned receipt; no manual capture allocation.
script='set -euo pipefail\n. scripts/lib.sh\n. scripts/verification-lib.sh\nvf_snapshot "$1" "$PWD" "$PWD" "$2"\n';(o/'snapshot.sh').write_text(script)
argv=['/bin/bash',str(o/'snapshot.sh'),str(s),str(o/'source-before.nul')];start=now();cp=subprocess.run(argv,cwd=root,env=env,capture_output=True);(o/'source-before.stdout').write_bytes(cp.stdout);(o/'source-before.stderr').write_bytes(cp.stderr);(o/'source-snapshot-invocation.json').write_text(json.dumps({'argv':argv,'cwd':str(root),'GIT_OPTIONAL_LOCKS':'0','start':start,'end':now(),'exit':cp.returncode,'stdout_sha256':h(cp.stdout),'stderr_sha256':h(cp.stderr)},indent=2)+'\n');assert cp.returncode==0;source=cp.stdout.decode().strip();assert source==h((o/'source-before.nul').read_bytes()) and source!='f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0'
# Recheck no freeze violation before the sole canonical native invocation.
violations={k:{'before':v,'after':info(root/k)} for k,v in base['files'].items() if info(root/k)!=v};(o/'freeze-before-invocation.json').write_text(json.dumps({'at':now(),'source':source,'violations':violations},indent=2)+'\n');assert not violations
argv=['bash','scripts/spec-run.sh','.specify/specs/003-gate-round-reduction-and-token-discipline','T031a5o1','--from-task','--no-tick','--summary'];assert argv==json.loads((r/'s36-fixture-verification/capture-invocation.json').read_text())['argv']
inv={'argv':argv,'cwd':str(root),'env_nonsecret':{k:env[k] for k in ['GIT_OPTIONAL_LOCKS','PATH','SHELL','LANG','LC_ALL','LC_CTYPE','TMPDIR'] if k in env},'start':now(),'attempt_count':1,'source':source}
assert not (o/'capture-invocation.json').exists();(o/'capture-invocation.json').write_text(json.dumps(inv,indent=2)+'\n')
with (o/'capture.stdout').open('xb') as stdout,(o/'capture.stderr').open('xb') as stderr:
 cp=subprocess.run(argv,cwd=root,env=env,stdout=stdout,stderr=stderr)
inv.update(exit=cp.returncode,end=now(),stdout_sha256=h((o/'capture.stdout').read_bytes()),stderr_sha256=h((o/'capture.stderr').read_bytes()));(o/'capture-invocation.json').write_text(json.dumps(inv,indent=2)+'\n');print(json.dumps(inv,indent=2));print((o/'capture.stdout').read_text());print((o/'capture.stderr').read_text())
