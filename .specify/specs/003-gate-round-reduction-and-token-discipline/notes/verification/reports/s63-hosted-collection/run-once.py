import datetime, hashlib, json, os, pathlib, subprocess
P=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert pathlib.Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=P/'.specify/specs/003-gate-round-reduction-and-token-discipline'
D=S/'notes/verification/reports/s63-hosted-collection'
A=S/'notes/verification/platforms/ci-20261029-s60/hosted-s62-keyring-audit'
assert not (D/'started.json').exists() and not (A/'network-execution.json').exists()
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0',GH_CONFIG_DIR=str(S/'notes/verification/reports/s61-publication/gh-config'))
for k in ['GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN']:env.pop(k,None)
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
argv=['python3',str(A/'collect-hosted.py'),'40966033511','1']
rec=dict(argv=argv,cwd=str(P),started=now(),envOverrides={'GIT_OPTIONAL_LOCKS':'0','GH_CONFIG_DIR':env['GH_CONFIG_DIR']},attempt=1,retry=False)
with (D/'stdout.log').open('xb') as out,(D/'stderr.log').open('xb') as err:
    child=subprocess.Popen(argv,cwd=P,env=env,stdin=subprocess.DEVNULL,stdout=out,stderr=err)
    rec['nativePid']=child.pid;(D/'started.json').write_text(json.dumps(rec,indent=2)+'\n')
    code=child.wait()
rec.update(ended=now(),exit=code)
for n in ['stdout','stderr']:rec[n+'SHA256']=hashlib.sha256((D/(n+'.log')).read_bytes()).hexdigest()
(D/'completed.json').write_text(json.dumps(rec,indent=2)+'\n')
print(json.dumps(rec,indent=2),flush=True)
if code==0:
    r=json.loads((A/'result.json').read_text());assert r['status']=='PASS' and r['run_id']==40966033511 and r['attempt']==1
    print(json.dumps({k:r[k] for k in ['status','run_id','attempt','head','tree','source','merge_sha','merge_tree','binding_before','binding_after','frozen_manifest']},indent=2),flush=True)
raise SystemExit(code)
