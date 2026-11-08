import ast,datetime,hashlib,json,os,stat,subprocess,time
from pathlib import Path
w=Path.cwd();s=w/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';o=s/'notes/verification/platforms/ci-20261028-s34';p=r/'s34-evidence-preparation';floor=r/'s34-final-floor.sh'
started=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
assert str(w)=='/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline'
def put(path,v):
 with path.open('x') as f:json.dump(v,f,indent=2);f.write('\n')
def info(x):
 st=x.lstat();data=os.fsencode(os.readlink(x)) if x.is_symlink() else x.read_bytes()
 return dict(path=str(x),sha256=hashlib.sha256(data).hexdigest(),mtime_ns=st.st_mtime_ns,size=st.st_size,mode=oct(stat.S_IMODE(st.st_mode)))
def run(name,argv):
 v=dict(argv=argv,cwd=str(w),started=datetime.datetime.now(datetime.timezone.utc).isoformat(),gitOptionalLocks='0');ts=time.monotonic();put(p/(name+'.invocation.json'),v)
 x=subprocess.run(argv,cwd=w,env=env,capture_output=True);(p/(name+'.stdout')).write_bytes(x.stdout);(p/(name+'.stderr')).write_bytes(x.stderr)
 put(p/(name+'.execution.json'),dict(**v,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-ts,3),exit=x.returncode))
 assert x.returncode==0,(name,x.returncode)
 return x.stdout
put(p/'finalization.invocation.json',dict(argv=['python3',str(p/'finalize.py')],cwd=str(w),started=started))
summary=json.loads((o/'summary.json').read_text());snap=Path(summary['snapshot']);proof=json.loads((o/'verification-final.json').read_text())
assert (o/'inputs-after.nul').read_bytes()==(snap/'inputs.nul').read_bytes()
assert proof['mapping']=='PASS' and proof['head_index']=='UNCHANGED' and not proof['global_refs_changed_since_baseline']
assert summary['source']==hashlib.sha256((snap/'inputs.nul').read_bytes()).hexdigest()
# The tenth offline guard control rejects a run with both id and attempt mismatched.
code=(o/'hosted-s34-audit/collect-hosted.py').read_text();nodes=[n for n in ast.walk(ast.parse(code)) if isinstance(n,ast.Assert) and ast.get_source_segment(code,n.test).startswith('discovered["id"]==wanted_run')];assert len(nodes)==1
assert eval(compile(ast.Expression(nodes[0].test),'offline-combined-run-guard','eval'),{},dict(discovered=dict(id=124,run_attempt=3),wanted_run=123,wanted_attempt=2)) is False
put(p/'additional-guard-self-check.json',dict(kind='OFFLINE_SYNTHETIC_CONTROL_ONLY',combinedWrongRunAndAttemptRejected=True,controlsInValidationScript=9,additionalControls=1,total=10,noCollectorExecution=True))
# Confirm exact finalized task bytes, current waiver and accepted-control artifacts in the frozen tree.
entries={}
for rec in (snap/'tree.nul').read_bytes().split(b'\0')[:-1]:
 h,path=rec.split(b'\t',1);entries[os.fsdecode(path)]=h.decode().split()
relative=str(s.relative_to(w));prefixes=[relative+'/notes/verification/'+suffix for suffix in ['accepted/T029/ACC-tUQ8JI/','accept-events/ACCEPT-4YDDpg/','accept-events/ACCEPT-egjJ7T/','reports/s34-approval/','reports/s34-t029-control/']]
selected=[relative+'/tasks.md',relative+'/STATUS.md']
for prefix in prefixes:
 paths=[x for x in entries if x.startswith(prefix)];assert paths,prefix;selected+=paths
bound=[]
for path in selected:
 mode,kind,oid=entries[path];x=w/path;data=x.read_bytes();actual_oid=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 assert kind=='blob' and oid==actual_oid and mode==('100755' if os.access(x,os.X_OK) else '100644'),path
 bound.append(dict(path=path,git_blob=oid,raw_sha256=hashlib.sha256(data).hexdigest()))
assert (s/'tasks.md').read_bytes()==(s/'notes/verification/accepted/T029/ACC-tUQ8JI/tasks.after').read_bytes()
put(p/'finalized-control-tree-proof.json',dict(result='PASS',paths=bound))
commit=run('commit-object-proof',['git','cat-file','commit',summary['commit']]).decode();assert commit.startswith('tree '+summary['tree']+'\nparent '+summary['parent']+'\n')
refs=run('refs-final',['git','show-ref']);before=json.loads((o/'state-before.json').read_text());assert hashlib.sha256(refs).hexdigest()==before['refs_sha256']
assert run('head-final',['git','rev-parse','HEAD']).decode().strip()==summary['parent']
protected=json.loads((o/'protected-before.json').read_text())
for key in ['index','head_file','status','tasks']:assert info(Path(protected[key]['path']))==protected[key],key
existing=json.loads((p/'preexisting-files.json').read_text());changed=[]
for name,expected in existing.items():
 x=w/name
 if not (x.exists() or x.is_symlink()) or info(x)!=expected:changed.append(name)
assert not changed,repr(changed)
new=[];unexpected=[]
for base,dirs,files in os.walk(w,followlinks=False):
 for name in files+list(dirs):
  x=Path(base)/name
  if not (x.is_file() or x.is_symlink()):continue
  rel=str(x.relative_to(w))
  if rel not in existing:
   new.append(rel)
   if not (x.is_relative_to(o) or x.is_relative_to(p) or x==floor):unexpected.append(rel)
assert not unexpected,repr(unexpected)
assert not list(r.glob('s34-final-floorrun.*'))
assert not (o/'hosted-s34-audit/network-execution.json').exists()
put(p/'preservation.json',dict(result='PASS',preexistingFilesChecked=len(existing),changedPreexistingFiles=changed,allPreexistingBytesModesMtimesUnchanged=True,protectedStateUnchanged=True,donorsUnchanged=True,refsUnchanged=True,newPathsOutsideOwnership=unexpected,newPathsObserved=new,note='File and symlink modes/mtimes are preserved; directory mtimes change only from creating authorized child paths.'))
# Scratch is evidence, not disposable temporary state.
put(p/'scratch-artifact-hashes.json',{str(x.relative_to(snap)):info(x) for x in snap.rglob('*') if x.is_file()})
result=dict(result='PREPARED_AND_LOCALLY_VALIDATED',completedAt=datetime.datetime.now(datetime.timezone.utc).isoformat(),cwd=str(w),source=summary['source'],tree=summary['tree'],commit=summary['commit'],parent=summary['parent'],snapshotBuildCount=1,treeEntries=summary['tree_entries'],mapping=dict(path=177,index=177,harness=8,document=4,tool=4,bookkeepingExtras=summary['bookkeeping_extras'],raw='PASS',semantic='PASS',beforeAfter='BYTE_IDENTICAL'),tasksAfterAcceptSha256=summary['tasks_after_accept_sha256'],acceptedT029='ACC-tUQ8JI',capture='CAP-817-8hIfCR',protectedState='UNCHANGED_BYTES_MODES_MTIMES',preexistingFilesChecked=len(existing),donors='UNCHANGED_BYTES_MODES_MTIMES',checks=dict(bash32Syntax='PASS',scopedShellcheck='PASS',exactSubstitutions='PASS',offlineGuardControls=10,strictPrepublish='PASS',finalizedControlTree='PASS',wholePreexistingPreservation='PASS'),paths=dict(platform=str(o),preparation=str(p),summary=str(o/'summary.json'),prepublish=str(o/'verify-prepublish.sh'),floor=str(floor),floorArgv=str(o/'parent-floor-launch.argv.json'),hostedArgv=str(o/'parent-hosted-collection.argv.json'),publication=str(o/'publication.json'),scratch=summary['scratch'],snapshot=summary['snapshot'],handoff=str(p/'handoff.md')),parentHelperArgv=json.loads((o/'parent-floor-launch.argv.json').read_text())['helper_argv'],parentTimedArgv=json.loads((o/'parent-floor-launch.argv.json').read_text())['timed_argv'],publishExecuted=False,networkQueriesExecuted=False,credentialsAccessed=False,floorStartedOrQueued=False,gatesReservedCompletedOrTallied=False,suitesOrCapturesExecuted=False,formalReadiness='NOT_ASSESSED',unknowns=['Current remote/PR head must be re-queried immediately before exact-lease publication','New hosted run/attempt and four-job proof do not exist in this preparation','Actual AC and >=8GiB free disk must be rechecked before parent launch','Fresh floor and OP26/conditional RC4 remain parent-owned future work','Snapshot commit is dangling by authorization; preserve scratch and object until publication'],identity=dict(requestedProvider='codex_codex_gym',requestedModel='gpt-6.1-sol',requestedReasoningEffort='high',requestedServiceTier='default',observedModelEffort='gpt-6.1-sol/high from developer runtime statement',providerTierProvenance='Parent-owned invocation; not independently exposed by local execution tool'))
put(p/'result.json',result)
(p/'handoff.md').write_text('Prepared and locally validated; no publication, network queries, credential access, floor, gate or suites/captures. No readiness verdict.\n\n'+
 'Frozen commit `'+summary['commit']+'`, tree `'+summary['tree']+'`, parent `'+summary['parent']+'`, normalized source `'+summary['source']+'`. Single unchanged donor build. Full 177 raw/mode mappings, 177 index + 177 path + 8 harness + 4 document + 4 tool records; '+str(summary['bookkeeping_extras'])+' extras classified by vf_bookkeeping_path. Builder/strict verifier manifests are byte-identical.\n\n'+
 'Completed genuine T029 control was verified first; finalized tasks `'+summary['tasks_after_accept_sha256']+'` match ACC-tUQ8JI/tasks.after byte-for-byte and are included in the tree with current STATUS waiver, acceptance/rejection and approval/control receipts. All '+str(len(existing))+' pre-existing files/symlinks retain bytes, modes and mtimes; actual index, HEAD, STATUS, tasks and donor helpers unchanged. Directory mtimes necessarily reflect authorized child creation.\n\n'+
 'Bash 3.2 syntax, scoped ShellCheck, exact donor substitutions, ten offline guard controls, commit parent/tree proof and strict prepublish passed. No collector test suite or repository suite was run. Subprocess argv/stdout/stderr/exit/time receipts are in this preparation directory; earlier read-only discovery commands are in the tool transcript and initial-verification.json.\n\n'+
 'Parent next steps are prepared only:\n\n'+
 '1. Re-run native argv `'+json.dumps(['/bin/bash',str(o/'verify-prepublish.sh')])+'`. Read publication.json, query actual remote ref and PR21 immediately before push, require same full head/open/draft/base main, and substitute that verified head into its exact full-ref force-with-lease template. The historical 616dd2d head is never a fresh lease. Keep PR21 draft; do not merge or touch PR20.\n'+
 '2. After actual CI completes, use parent-hosted-collection.argv.json with actual numeric run/attempt and parent-supplied scoped secret. The prepared robust collector checks exact four-job run/attempt/head/full tested merge/tree/parent/raw logs, source before/after, open/draft PR, and seals artifacts. It has not been executed. Existing donor collector remains unchanged.\n'+
 '3. Parent owns a separate small native launcher receipt. Recheck actual AC and >=8589934592 free bytes, no process/lock/pending round and every listed output collision, then launch the timed argv below directly with native subprocess APIs; redirect to wrapper.log, retain wrapper PID and write wrapper.rc. No shell quoting or AC wait is prepared. Helper independently rechecks guards and strict source before/after. Require floor.rc and wrapper.rc both zero, identical manifests and a new floor ID. Do not run the naked floor command.\n\n'+
 'Native helper argv:\n\n```json\n'+json.dumps(result['parentHelperArgv'],indent=2)+'\n```\n\nNative timed argv:\n\n```json\n'+json.dumps(result['parentTimedArgv'],indent=2)+'\n```\n\n'+
 'External scratch retained at `'+summary['scratch']+'`; snapshot/index is temporary and the commit is dangling. Keep both until parent publication. Newly written preparation receipts/helpers after tree creation are excluded verification bookkeeping and do not change source identity; no snapshot rebuild is needed.\n\n'+
 'Unknown: actual current remote lease, new hosted CI, launch resources, fresh floor and later formal gate results. O-032/minor follow-ups were not repaired or assessed.\n')
put(p/'finalization.execution.json',dict(argv=['python3',str(p/'finalize.py')],cwd=str(w),started=started,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-t,3),exit=0))
owned=[x for base in [o,p] for x in base.rglob('*') if x.is_file()]+[floor]
seal={str(x.relative_to(w)):info(x) for x in owned};put(p/'artifact-hashes.json',seal)
assert all(info(w/name)==expected for name,expected in seal.items())
print(json.dumps(dict(result=result['result'],commit=summary['commit'],tree=summary['tree'],source=summary['source'],preservedFiles=len(existing),sealedArtifacts=len(seal),resultPath=str(p/'result.json')),indent=2))
