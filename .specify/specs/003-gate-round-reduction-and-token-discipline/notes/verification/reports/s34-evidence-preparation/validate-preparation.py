import ast,collections,datetime,hashlib,json,os,shutil,stat,subprocess,time
from pathlib import Path
w=Path.cwd();s=w/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';o=s/'notes/verification/platforms/ci-20261028-s34';p=r/'s34-evidence-preparation';d=o.parent/'ci-20261026-s29'
assert str(w)=='/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline'
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0');env.pop('SHELLCHECK_OPTS',None)
def put(x,v):
 with x.open('x') as f:json.dump(v,f,indent=2);f.write('\n')
def run(name,argv):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();v=dict(argv=argv,cwd=str(w),started=start,gitOptionalLocks='0',shellcheckOptsUnset=True)
 put(p/(name+'.invocation.json'),v)
 with (p/(name+'.stdout')).open('xb') as out,(p/(name+'.stderr')).open('xb') as err:result=subprocess.run(argv,cwd=w,env=env,stdout=out,stderr=err)
 put(p/(name+'.execution.json'),dict(**v,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-t,3),exit=result.returncode))
 assert result.returncode==0,(name,result.returncode)
 return (p/(name+'.stdout')).read_text()
summary=json.loads((o/'summary.json').read_text());origins=json.loads((o/'origins.json').read_text());subs=json.loads((p/'substitutions.json').read_text())
for k,x in origins.items():
 path=Path(x['path']);st=path.stat();assert hashlib.sha256(path.read_bytes()).hexdigest()==x['sha256'] and st.st_mtime_ns==x['mtime_ns'] and st.st_size==x['size'] and oct(stat.S_IMODE(st.st_mode))==x['mode'],k
for name in ['build-snapshot.sh','test-collector.py']:assert (o/name).read_bytes()==(d/name).read_bytes() and stat.S_IMODE((o/name).stat().st_mode)==stat.S_IMODE((d/name).stat().st_mode)
for name,x in subs.items():
 expected=Path(x['donor']).read_text()
 for change in x['substitutions']:
  assert expected.count(change['old'])==change['count'],name
  expected=expected.replace(change['old'],change['new'])
 assert Path(x['target']).read_text()==expected,name
 assert stat.S_IMODE(Path(x['target']).stat().st_mode)==stat.S_IMODE(Path(x['donor']).stat().st_mode),name
assert summary['manifest_record_types']==dict(version=1,index=177,path=177,tool=4,harness=8,document=4)
assert (s/'tasks.md').read_bytes()==(s/'notes/verification/accepted/T029/ACC-tUQ8JI/tasks.after').read_bytes()
floor=(r/'s34-final-floor.sh').read_text();verifier=(o/'verify-prepublish.sh').read_text();launch=json.loads((o/'parent-floor-launch.argv.json').read_text());pub=json.loads((o/'publication.json').read_text())
assert 's29-final' not in floor and 'ci-20261026-s29' not in floor and '16ffcec3' not in floor
assert floor.index('if free < 8589934592')<floor.index('bash "$out/verify-prepublish.sh"')<floor.index('caffeinate -i -m -s')
assert floor.count('bash "$out/verify-prepublish.sh"')==2 and '"$after_floor" != "$before_floor"' in floor
assert '[[ ! -e "$s/notes/verification/lock" ]]' in floor and 'pending round' in floor and 'staged reservation' in floor
assert launch['helper_argv']==['/bin/bash',str(r/'s34-final-floor.sh'),'1']
assert launch['timed_argv']==['/usr/bin/time','-p','-o',str(r/'s34-final-floorrun.time'),*launch['helper_argv']]
assert launch['no_ac_wait'] and launch['no_shell_text'] and 'shell_text' not in launch
assert pub['push_argv_template']==['git','push','--force-with-lease=refs/heads/ci-snapshot/spec-003-20261025-s26:<VERIFIED_REMOTE_HEAD>','origin',summary['commit']+':refs/heads/ci-snapshot/spec-003-20261025-s26']
assert not list(r.glob('s34-final-floorrun.*'))
hosted=o/'hosted-s34-audit/collect-hosted.py';code=hosted.read_text();tree=ast.parse(code)
assert 'auth","token' not in code and 'gh","auth' not in code and 'actions/runs?head_sha=' not in code
assert 'verify-before' in code and 'verify-after' in code and 'artifact-hashes.json' in code
assert not (hosted.parent/'network-execution.json').exists() and not (hosted.parent/'hosted').exists()
# Evaluate the actual new guard expressions offline, including wrong run/attempt/head.
assertions=[n for n in ast.walk(tree) if isinstance(n,ast.Assert)]
def guard(prefix):
 matches=[n.test for n in assertions if ast.get_source_segment(code,n.test).startswith(prefix)]
 assert len(matches)==1,prefix
 return compile(ast.Expression(matches[0]),str(hosted),'eval')
run_guard=guard('discovered["id"]==wanted_run')
job_guard=guard('j["status"]=="completed"')
base=dict(wanted_run=123,wanted_attempt=2,runid=123,head=summary['commit'])
for changed in [None,'id','run_attempt']:
 discovered=dict(id=123,run_attempt=2)
 if changed:discovered[changed]+=1
 assert eval(run_guard,{},dict(base,discovered=discovered))==(changed is None)
for changed in [None,'status','conclusion','run_id','run_attempt','head_sha']:
 j=dict(status='completed',conclusion='success',run_id=123,run_attempt=2,head_sha=summary['commit'])
 if changed:j[changed]='mismatch'
 assert eval(job_guard,{},dict(base,j=j))==(changed is None)
version=run('bash32-version',['/bin/bash','--version']);assert 'version 3.2.' in version
shellcheck=shutil.which('shellcheck');assert shellcheck
for path in [o/'build-snapshot.sh',o/'verify-prepublish.sh',o/'collect.sh',r/'s34-final-floor.sh']:
 run(path.name+'-syntax',['/bin/bash','-n',str(path)])
 argv=[shellcheck,'--norc','--shell=bash','--severity=warning','--external-sources']
 if path.name in ['build-snapshot.sh','verify-prepublish.sh']:argv+=['--exclude=SC2034']
 run(path.name+'-shellcheck',argv+[str(path)])
# Parse/compile only: no collector queries, suites, captures or floor execution.
compile(code,str(hosted),'exec');ast.parse((o/'test-collector.py').read_text())
run('verify-prepublish',['/bin/bash',str(o/'verify-prepublish.sh')])
result=dict(result='PASS',donor_bytes_modes_mtimes_unchanged=True,exact_substitutions=True,builder_run_count=1,after_accept_tasks_exact=True,strict_manifest_counts=True,offline_guard_controls=10,bash32_syntax='PASS',scoped_shellcheck='PASS',strict_prepublish='PASS',native_floor_argv=True,publication_lease_requires_fresh_query=True,floor_executed=False,hosted_collection_executed=False,publication_executed=False,suites_or_captures_executed=False)
put(p/'preparation-self-check.json',result)
print(json.dumps(result,indent=2))
