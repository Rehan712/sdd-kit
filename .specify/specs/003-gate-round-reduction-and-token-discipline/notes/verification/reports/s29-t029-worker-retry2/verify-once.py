import datetime,hashlib,json,os,pathlib,stat,subprocess,time,re,sys
ROOT=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert pathlib.Path.cwd()==ROOT
SPEC=pathlib.Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
OWN=ROOT/SPEC/'notes/verification/reports/s29-t029-worker-retry2'
ARGV=['bash','scripts/spec-run.sh',str(SPEC),'T029','--from-task','--no-tick','--summary']
def stamp(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def digest(b): return hashlib.sha256(b).hexdigest()
def git(*a): return subprocess.check_output(['git','--no-optional-locks',*a],cwd=ROOT)
def record(path):
 p=pathlib.Path(path);s=p.lstat();b=os.fsencode(os.readlink(p)) if p.is_symlink() else p.read_bytes()
 return {'path':str(p),'sha256':digest(b),'mode':format(stat.S_IMODE(s.st_mode),'04o'),'mtime_ns':s.st_mtime_ns,'size':s.st_size,'symlink':p.is_symlink()}
def save(name,data):
 p=OWN/name
 with p.open('x') as f: json.dump(data,f,indent=2,sort_keys=True);f.write('\n')
 os.chmod(p,0o600)
def excluded(p):
 base=str(SPEC)
 return p.startswith(base+'/notes/captures/') or p.startswith(base+'/notes/verification/') or p in [base+'/notes/evidence.md',base+'/notes/opponent.md',base+'/notes/reality-check.md'] or p.startswith(base+'/.tasks.accept.')
def snapshot():
 paths=sorted(set(os.fsdecode(x) for x in git('ls-files','-z','--cached','--others','--exclude-standard').split(b'\0') if x))
 records={}
 for p in paths:
  if excluded(p):continue
  f=ROOT/p
  records[p]=record(f) if f.exists() or f.is_symlink() else {'path':str(f),'missing':True}
 return {'time':stamp(),'head':git('rev-parse','HEAD').decode().strip(),'protected':{p:record(f) for p,f in PROTECTED.items()},'source_records':records}
index=pathlib.Path(git('rev-parse','--git-path','index').decode().strip())
headfile=pathlib.Path(git('rev-parse','--git-path','HEAD').decode().strip())
ref=git('symbolic-ref','HEAD').decode().strip()
reffile=pathlib.Path(git('rev-parse','--git-path',ref).decode().strip())
PROTECTED={'tasks.md':ROOT/SPEC/'tasks.md','STATUS.md':ROOT/SPEC/'STATUS.md','git-index':index,'git-HEAD':headfile}
if reffile.exists():PROTECTED['git-branch-ref']=reffile
expected={
 'scripts/sdd-analyze.sh':('0c26c101666aa8559814f40c7376da6b07290d8e2830b230a54b8eb01b4afdf7','0755'),
 'tests/test-sdd-analyze.sh':('513308051dc409e42fe72c3c20d5a0fe4a1e7607e5373dcff404fd6993cf4516','0644'),
 'tests/test-gate-contracts.sh':('7bc13dde14004bf4ba967c0f64ec120b19bdde641643a6a7436d154c222f893c','0644'),
 str(SPEC/'tasks.md'):('82fe00d7ef49b4d1b66ff65ef8ca1ed672d7c51dfbb8d94a63db4892a3a93894','0600'),
 str(SPEC/'STATUS.md'):('2519b0a153bd7a8548b1b5d6abf3cefaddd6da93d8c5670efba4322dd4c8be1b','0600')}
model={'source':'live orchestrator_capabilities observed during this worker turn','parentThreadId':'thread:delegated-task:command%3Amcp%3Ae6315556-7380-4d31-903f-24b14ad55a20%3Adelegate-task%3Asdd003-s29-t029-fresh-worker-high-retry2','providerInstanceId':'codex_codex_gym','model':'gpt-6.1-sol','options':[{'id':'reasoningEffort','value':'high'},{'id':'serviceTier','value':'default'}],'runtimeMode':'full-access','interactionMode':'default'}
save('model-selection.json',model)
before=snapshot();save('before-state.json',before)
for name,p in PROTECTED.items():(OWN/(name+'.before')).write_bytes(p.read_bytes())
status=git('status','--porcelain=v1','-z');(OWN/'git-status-before.nul').write_bytes(status)
errors=[]
for p,(sha,mode) in expected.items():
 r=before['source_records'].get(p,{})
 if r.get('sha256')!=sha or r.get('mode')!=mode:errors.append({'path':p,'expected_sha256':sha,'expected_mode':mode,'actual':r})
if before['head']!='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9':errors.append({'HEAD':before['head']})
if before['protected']['git-index']['sha256']!='c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700':errors.append({'index':before['protected']['git-index']})
if os.path.lexists(ROOT/SPEC/'notes/verification/lock'):errors.append({'lock':'exists'})
result={'run_count':0,'argv':ARGV,'cwd':str(ROOT),'model_selection':model,'expected_paths':expected,'preflight_errors':errors,'started_at':None,'finished_at':None}
save('preflight.json',result)
if errors:
 save('result.json',result);print(json.dumps({'preflight_errors':errors,'run_count':0}));sys.exit(1)
env=dict(os.environ)
save('environment.json',env)
(OWN/'argv.nul').write_bytes(b'\0'.join(os.fsencode(a) for a in ARGV)+b'\0')
result['started_at']=stamp();start=time.monotonic()
save('invocation.json',{'argv':ARGV,'cwd':str(ROOT),'environment':'environment.json','started_at':result['started_at'],'run_count':1,'environment_overrides':{}})
print(json.dumps({'phase':'running','argv':ARGV,'cwd':str(ROOT),'started_at':result['started_at']}),flush=True)
with (OWN/'stdout.log').open('xb') as out,(OWN/'stderr.log').open('xb') as err:
 proc=subprocess.Popen(ARGV,cwd=ROOT,env=env,stdout=out,stderr=err)
 result['run_count']=1;result['pid']=proc.pid;result['exit']=proc.wait()
result['finished_at']=stamp();result['elapsed_seconds']=time.monotonic()-start
after=snapshot();save('after-state.json',after)
for name,p in PROTECTED.items():(OWN/(name+'.after')).write_bytes(p.read_bytes())
(OWN/'git-status-after.nul').write_bytes(git('status','--porcelain=v1','-z'))
result['stdout']=record(OWN/'stdout.log');result['stderr']=record(OWN/'stderr.log')
result['protected_unchanged']=before['protected']==after['protected'];result['head_unchanged']=before['head']==after['head']
result['source_changes']=[{'path':p,'before':before['source_records'].get(p),'after':after['source_records'].get(p)} for p in sorted(set(before['source_records'])|set(after['source_records'])) if before['source_records'].get(p)!=after['source_records'].get(p)]
out=(OWN/'stdout.log').read_bytes();match=re.search(rb'^capture=(CAP-[A-Za-z0-9-]+) ',out,re.M)
result['capture']=match.group(1).decode() if match else None
if result['capture']:
 capdir=ROOT/SPEC/'notes/captures'/result['capture']
 result['capture_directory']=str(capdir)
 fields=(capdir/'meta.nul').read_bytes().split(b'\0');assert fields[-1]==b'';fields.pop();assert len(fields)%2==0
 meta={fields[i].decode():fields[i+1].decode() for i in range(0,len(fields),2)}
 result['metadata']=meta
 checks={'unique_metadata':len(meta)*2==len(fields),'command_exit_zero':meta.get('exit')=='0','script_exit_zero':result['exit']==0,'no_tick':meta.get('no_tick')=='1','input_before_equals_after':meta.get('input_before')==meta.get('input_after'),'inputs_digest_matches':digest((capdir/'inputs.nul').read_bytes())==meta.get('input_before'),'inputs_after_digest_matches':digest((capdir/'inputs-after.nul').read_bytes())==meta.get('input_after'),'output_digest_matches':digest((capdir/'output.log').read_bytes())==meta.get('output_digest'),'output_bytes_matches':str((capdir/'output.log').stat().st_size)==meta.get('output_bytes'),'summary_matches_stdout':(capdir/'summary.txt').read_bytes()==out,'new_source_not_e77d':meta.get('input_before')!='e77d4b2969f45f3dfa95cedc18148e1abf0dabffd786946f59ff6a5b7fd07df6','protected_unchanged':result['protected_unchanged'],'head_unchanged':result['head_unchanged'],'source_unchanged':not result['source_changes']}
 result['capture_records']={p.name:record(p) for p in capdir.iterdir() if p.is_file()}
 for p in capdir.iterdir():
  if p.is_file():(OWN/('capture-'+p.name)).write_bytes(p.read_bytes())
 seal=(capdir/'COMPLETE').read_text().splitlines();checks['complete_seal_matches']=all(len(line.split())==2 and digest((capdir/line.split()[1]).read_bytes())==line.split()[0] for line in seal)
 ledger=ROOT/SPEC/'notes/verification/captures'/result['capture'];checks['ledger_matches_complete']=ledger.read_bytes()==(capdir/'COMPLETE').read_bytes()
 # Binding records have twelve NUL fields, the same registry read by the existing handoff helper.
 bs=(capdir/'bindings.nul').read_bytes().split(b'\0');assert bs.pop()==b'';assert len(bs)%12==0
 rows=[[v.decode() for v in bs[i:i+12]] for i in range(0,len(bs),12)]
 task_rows=[r for r in rows if r[0]=='task' and r[2]=='T029'];bindings=[r for r in rows if r[0]=='binding' and r[2]=='T029']
 wanted={('FM-001','tests/test-gate-contracts.sh::test_instruction_contracts'),('INV-005','tests/test-gate-contracts.sh::test_instruction_contracts')}
 checks['exact_binding_set']={(r[1],r[7]) for r in bindings}==wanted
 result['captured_task_rows']=task_rows;result['captured_binding_rows']=bindings
 result['checks']=checks;result['success']=all(checks.values())
 if result['success']:
  block=('Verification-Return: 1\nTask: T029\nCaptures: '+result['capture']+'\nSummary: '+out.decode().rstrip('\n')+'\nFailure modes:\nFM-001, tests/test-gate-contracts.sh::test_instruction_contracts, '+result['capture']+'\nINV-005, tests/test-gate-contracts.sh::test_instruction_contracts, '+result['capture']+'\n')
  (OWN/'worker-return.txt').write_bytes(block.encode());result['worker_return']=record(OWN/'worker-return.txt')
else:result['success']=False
save('result.json',result)
print(json.dumps({'phase':'completed','run_count':result['run_count'],'exit':result['exit'],'capture':result['capture'],'success':result['success'],'checks':result.get('checks'),'source_changes':result['source_changes'],'elapsed_seconds':result['elapsed_seconds']}),flush=True)
if result['success']:print((OWN/'worker-return.txt').read_text(),end='')
sys.exit(0 if result['success'] else 1)
