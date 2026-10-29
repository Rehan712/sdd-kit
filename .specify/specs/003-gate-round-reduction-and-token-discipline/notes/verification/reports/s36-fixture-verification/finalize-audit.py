import os, stat, hashlib, json, subprocess, datetime, re
from pathlib import Path
root=Path.cwd()
s=Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
o=s/'notes/verification/reports/s36-fixture-verification'
h=lambda b:hashlib.sha256(b).hexdigest()
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
inv=json.loads((o/'capture-invocation.json').read_text())
assert inv.get('exit')==0, 'capture did not finish successfully; no retry'
pre=json.loads((o/'capture-preflight.json').read_text())
new=[p for p in (s/'notes/captures').iterdir() if p.name not in pre['capture_names']]
assert len(new)==1 and re.fullmatch(r'CAP-[1-9][0-9]*-[A-Za-z0-9]+',new[0].name),new
capdir=new[0];cap=capdir.name
assert int(cap.split('-')[1])==int(pre['sequence'])+1
assert (s/'notes/verification/sequence').read_text()==str(int(pre['sequence'])+1)+'\n'
argv=['/bin/bash',str(o/'check-capture.sh'),str(s),cap,str(o)]
start=now();p=subprocess.run(argv,cwd=root,env=os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(o/'capture-integrity.stdout').write_bytes(p.stdout);(o/'capture-integrity.stderr').write_bytes(p.stderr)
integrity={'argv':argv,'cwd':str(root),'env_nonsecret':{'GIT_OPTIONAL_LOCKS':os.environ.get('GIT_OPTIONAL_LOCKS')},'start':start,'end':now(),'exit':p.returncode,'stdout_sha256':h(p.stdout),'stderr_sha256':h(p.stderr)}
(o/'capture-integrity.json').write_text(json.dumps(integrity,indent=2)+'\n')
assert p.returncode==0,(p.stdout,p.stderr)
def nul(path,arity):
 b=path.read_bytes();assert b.endswith(b'\0');f=b[:-1].split(b'\0');assert len(f)%arity==0
 return [[x.decode() for x in f[i:i+arity]] for i in range(0,len(f),arity)]
meta=dict(nul(capdir/'meta.nul',2));assert meta['id']==cap and meta['exit']=='0' and meta['no_tick']=='1'
assert meta['input_before']==meta['input_after']==h((capdir/'inputs.nul').read_bytes())==h((capdir/'inputs-after.nul').read_bytes())
assert meta['output_digest']==h((capdir/'output.log').read_bytes())
assert int(meta['output_bytes'])==(capdir/'output.log').stat().st_size
assert meta['repo']==meta['cwd']==str(root) and meta['shell']=='/bin/bash'
assert nul(capdir/'argv.nul',1)==[['/bin/bash'],['-o'],['pipefail'],['-c'],['bash tests/test-sdd-analyze.sh']]
assert (capdir/'bindings.nul').read_bytes()==(o/'current-bindings.nul').read_bytes()
rows=nul(o/'current-bindings.nul',12)
bindings=sorted(set((r[1],r[7]) for r in rows if r[0]=='binding' and r[2]=='T031a5o1'))
assert bindings==[('FM-001','tests/test-sdd-analyze.sh::test_verification_bindings'),('INV-005','tests/test-sdd-analyze.sh::test_verification_bindings')],bindings
tasks=[r for r in rows if r[0]=='task' and r[2]=='T031a5o1'];assert len(tasks)==1 and tasks[0][5]=='test'
inputs=nul(capdir/'inputs.nul',6)
source_rows=[r for r in inputs if r[0]=='path' and r[1] in ['tests/test-sdd-analyze.sh','scripts/sdd-analyze.sh']]
assert ['path','tests/test-sdd-analyze.sh','file','100644','e5b5cde870b2da8c086a41f3a3824b401262343225108c7f3bab716324150c9a',''] in source_rows
assert ['path','scripts/sdd-analyze.sh','file','100755','c43de9e92df5657a3a94091a73bccb9abe37f9e1c3c3f6ccf6cb1cfa64f3a3f2',''] in source_rows
summary=(capdir/'summary.txt').read_bytes();assert summary.endswith(b'\n') and summary.count(b'\n')==1
assert (o/'capture.stdout').read_bytes()==summary
log=(capdir/'output.log').read_text();assert re.search(r'^  -- 19/19 passed$',log,re.M)
assert len(re.findall(r'^  ok   ',log,re.M))==19 and 'not ok' not in log
assert '  ok   test_verification_bindings\n' in log
seal=(capdir/'COMPLETE').read_bytes();assert seal==(s/'notes/verification/captures'/cap).read_bytes()
sealed=[]
for line in seal.decode().splitlines()[1:]:
 digest,name=line.split(' ',1);assert h((capdir/name).read_bytes())==digest;sealed.append({'file':name,'sha256':digest,'bytes':(capdir/name).stat().st_size})
base=json.loads((o/'protected.before.json').read_text());gd=Path(base['gitdir']);after={};changes=[]
for rel,old in base['files'].items():
 path=gd/rel[8:] if rel.startswith('@gitdir/') else root/rel
 if not path.exists() and not path.is_symlink():
  after[rel]={'missing':True};changes.append({'path':rel,'before':old,'after':after[rel]});continue
 st=path.lstat();value={'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns,'size':st.st_size}
 if path.is_symlink():value['link']=os.readlink(path)
 elif path.is_file():value['sha256']=h(path.read_bytes())
 after[rel]=value
 if old!=value:changes.append({'path':rel,'before':old,'after':value})
allowed={str(s/'notes/evidence.md'),str(s/'notes/verification/sequence')}
unexpected=[v for v in changes if v['path'] not in allowed]
(o/'protected.after.json').write_text(json.dumps({'at':now(),'files':after,'changes':changes,'unexpected_changes':unexpected},indent=2)+'\n')
assert not unexpected,unexpected
assert {v['path'] for v in changes}==allowed
prior=(o/'protected-raw/evidence').read_bytes();evidence=(s/'notes/evidence.md').read_bytes();assert evidence.startswith(prior)
append=evidence[len(prior):];assert append.count(b'\n## ')==1 and ('## '+cap+' ').encode() in append and summary in append
(o/'evidence-append.raw').write_bytes(append)
for name,path in [('test',root/'tests/test-sdd-analyze.sh'),('analyzer',root/'scripts/sdd-analyze.sh'),('tasks',s/'tasks.md'),('STATUS',s/'STATUS.md'),('index',gd/'index'),('HEAD',gd/'HEAD')]:
 b=path.read_bytes();assert b==(o/'protected-raw'/name).read_bytes();(o/'protected-raw'/(name+'.after')).write_bytes(b)
def git(args):
 p=subprocess.run(['git',*args],cwd=root,env=os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True);return p.stdout
assert git(['rev-parse','HEAD']).decode().strip()==base['head']
assert git(['symbolic-ref','--short','HEAD']).decode().strip()==base['branch']
status=git(['status','--porcelain=v1','-z','--untracked-files=all']);(o/'git-status.after.nul').write_bytes(status)
newfiles=[]
for directory,dirs,files in os.walk(root):
 dirs[:]=[n for n in dirs if n!='.git']
 for name in files:
  path=Path(directory)/name;rel=str(path.relative_to(root))
  if rel not in base['files']:newfiles.append(rel)
def new_allowed(rel):
 return rel.startswith(str(o)+'/') or rel.startswith(str(capdir)+'/') or rel==str(s/'notes/verification/captures'/cap)
assert not [f for f in newfiles if not new_allowed(f)],[f for f in newfiles if not new_allowed(f)]
def status_filter(b):
 return [x for x in b.split(b'\0') if x and not new_allowed(x[3:].decode(errors='surrogateescape')) and x[3:].decode(errors='surrogateescape') not in allowed]
status_before=status_filter((o/'git-status.before.nul').read_bytes())
status_after=status_filter(status)
timing=json.loads((o/'status-baseline-timing.json').read_text())
timing_path=timing['path']
assert timing['already_present_in_before_file_inventory'] and timing['unchanged'] and after[timing_path]==base['files'][timing_path]
assert status_after.count(('?? '+timing_path).encode())==1 and ('?? '+timing_path).encode() not in status_before
assert [r for r in status_after if r!=('?? '+timing_path).encode()]==status_before,'preexisting Git status changed beyond documented baseline timing receipt'
assert not (s/'notes/verification/lock').exists() and not list((s/'notes/captures').glob('.capture.*')) and not list((s/'notes/verification').glob('bindings.*'))
protection={'preexisting_files_checked':len(base['files']),'all_preexisting_raw_hashes_modes_mtimes_unchanged_except_automatic_sequence_and_evidence':True,'allowed_changes':changes,'evidence_prior_bytes_preserved':True,'evidence_append_sha256':h(append),'evidence_append_bytes':len(append),'preexisting_history_preserved':True,'head':base['head'],'branch':base['branch'],'index':after['@gitdir/index'],'git_status_preserved_except_owned_additions_and_automatic_capture_bookkeeping':True,'new_files':newfiles,'no_unexpected_new_files':True,'no_lock_or_pending_capture_after':True,'initial_status_to_file_inventory_timing_receipt':timing,'initial_finalizer_stop':'Conservative status assertion detected parent invocation receipt added between initial status read and inventory; receipt was already protected by before inventory and remains byte/mode/mtime identical; initial checker and diagnostic retained; no capture rerun.'}
(o/'protection-check.json').write_text(json.dumps(protection,indent=2)+'\n')
static=json.loads((o/'static-checks.json').read_text());assert all(r['exit']==0 for r in static)
fixture=json.loads((o/'fixture-selfcheck.json').read_text());assert fixture['status']=='PASS'
block='Verification-Return: 1\nTask: T031a5o1\nCaptures: '+cap+'\nSummary: '+summary.decode()+'Failure modes:\n'+''.join(f'{fm}, {locator}, {cap}\n' for fm,locator in bindings)
assert block.endswith('\n') and not block.endswith('\n\n')
(o/'worker-return.txt').write_bytes(block.encode())
result={'status':'PASS','completed_at':now(),'scope':json.loads((o/'audit-scope.json').read_text()),'fixture_selfcheck':fixture,'explicit_kind_controls':json.loads((o/'explicit-kind-controls.json').read_text()),'runtime_discovery':json.loads((o/'runtime-discovery.json').read_text()),'docker_discovery':json.loads((o/'docker-discovery.json').read_text()),'static_checks':static,'capture_invocation':inv,'capture':{'id':cap,'directory':str(root/capdir),'meta':meta,'argv':nul(capdir/'argv.nul',1),'input_record_count':len(inputs),'actual_worktree_source_records':source_rows,'summary_exact':summary.decode(),'seal':seal.decode(),'sealed_files':sealed,'required_failure_mode_bindings':bindings,'task_binding_record':tasks[0],'current_binding_rows':[r for r in rows if r[0]=='binding' and r[2]=='T031a5o1'],'integrity_and_current_task_binding_check':integrity,'suite_passed':'19/19','command_attempts':1,'accepted':False,'current_identity_derivation':'actual sealed inputs.nul and inputs-after.nul; working-tree source rows match the fixed test and unchanged analyzer; protected-file audit proves no source changed through verification','not_historical_snapshot':'No historical identity was relabeled; this fresh capture derives its own input identity.'},'protection':protection,'worker_return':{'path':str(root/o/'worker-return.txt'),'sha256':h(block.encode()),'terminal_lf_count':1,'canonical_return_untouched':True,'parent_acceptance_required':True},'risks_and_skipped_checks':json.loads((o/'audit-scope.json').read_text())['limits']}
(o/'result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'status':'PASS','capture':cap,'input_identity':meta['input_before'],'output_hash':meta['output_digest'],'protected_preexisting_count':len(base['files']),'worker_return_sha256':h(block.encode()),'result':str(root/o/'result.json')}))
print(block,end='')
