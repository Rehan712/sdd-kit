from pathlib import Path
import subprocess,json,os,hashlib,datetime
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
scratch=Path(__file__).resolve().parent; kit=scratch/'kit'
out=scratch/'currency'; out.mkdir(exist_ok=False)
sandbox=scratch/'execution'; sandbox.mkdir()
env=dict(os.environ,PATH='/usr/bin:/bin:/usr/sbin:/sbin',NO_COLOR='1')
steps=[]
def run(label,argv,want=0):
 p=subprocess.run(argv,cwd=root,env=env,text=True,capture_output=True,timeout=60)
 (out/(label+'.stdout')).write_text(p.stdout); (out/(label+'.stderr')).write_text(p.stderr)
 steps.append({'label':label,'argv':argv,'cwd':str(root),'exit':p.returncode,'expected':want,'ok':p.returncode==want})
 assert p.returncode==want,(label,p.returncode,p.stdout,p.stderr)
 return p.stdout+p.stderr
setup=run('setup',['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_verification_git_dir op25-currency','_',str(kit/'tests/helpers.sh'),str(sandbox)])
spec=Path(setup.strip()); repo=spec.parents[2]; lib=kit/'scripts/verification-lib.sh'; analyzer=kit/'scripts/sdd-analyze.sh'
assert repo.is_relative_to(scratch)
base_tasks=(spec/'tasks.md').read_bytes()
summary=run('capture',['/bin/bash',str(kit/'scripts/spec-run.sh'),str(spec),'T001','--cwd',str(repo),'--from-task','--no-tick','--summary'])
cap=summary.split('capture=',1)[1].split(' ',1)[0]
log=spec/'notes/captures'/cap/'output.log'; original_log=log.read_bytes()
ret=out/'return.txt'
ret.write_text('Verification-Return: 1\nTask: T001\nCaptures: '+cap+'\nSummary: '+summary.strip()+'\nFailure modes:\nFM-001, tests/check.sh::test_ac_001_shared, '+cap+'\n')
def predicates(label,want):
 for predicate in ('current','reuse'):
  run(label+'-'+predicate,['/bin/bash','-c','. "$1"; vf_snapshot "$2" "$3" "$3" "$4" >/dev/null && vf_capture_check "$2" "$5" "$4" "$6"','_',str(lib),str(spec),str(repo),str(out/'inputs.nul'),cap,predicate],want)
 run(label+'-matrix',['/bin/bash','-c','. "$1"; vf_matrix_evidence "$2" "$3"','_',str(lib),str(spec),cap+'; review: independent owned fixture observation'],want)
predicates('intact',0)
original_analyzer=analyzer.read_bytes()
try:
 analyzer.write_bytes(original_analyzer+b'\n# isolated opponent25 harness identity attack\n')
 predicates('changed-harness',3)
 run('reject-stale',['/bin/bash',str(kit/'scripts/spec-gate.sh'),'accept',str(spec),'T001',str(ret)],3)
 assert (spec/'tasks.md').read_bytes()==base_tasks
 assert log.read_bytes()==original_log
finally:
 analyzer.write_bytes(original_analyzer)
predicates('restored-harness',0)
run('accept-current',['/bin/bash',str(kit/'scripts/spec-gate.sh'),'accept',str(spec),'T001',str(ret)])
accepted=(spec/'tasks.md').read_bytes(); assert b'- [x] **T001**' in accepted
run('current-after-tick',['/bin/bash',str(kit/'scripts/spec-evidence.sh'),str(spec),'--current'])
specfile=spec/'spec.md'; original_spec=specfile.read_bytes()
try:
 specfile.write_bytes(original_spec.replace(b'the shared boundary behavior',b'the changed shared boundary behavior'))
 assert specfile.read_bytes()!=original_spec
 run('current-reject-after-criterion-edit',['/bin/bash',str(kit/'scripts/spec-evidence.sh'),str(spec),'--current'],3)
 hist=run('historical-retry',['/bin/bash',str(kit/'scripts/spec-gate.sh'),'accept',str(spec),'T001',str(ret)])
 assert 'already-accepted' in hist and 'freshness=historical' in hist
 assert (spec/'tasks.md').read_bytes()==accepted
 predicates('criterion-edit',3)
finally:
 specfile.write_bytes(original_spec)
run('current-after-criterion-restore',['/bin/bash',str(kit/'scripts/spec-evidence.sh'),str(spec),'--current'])
assert log.read_bytes()==original_log
assert analyzer.read_bytes()==original_analyzer
(out/'results.json').write_text(json.dumps({'scratchSpec':str(spec),'ownedStub':'tests/check.sh from copied helper; sources owned src/parser.sh only','cap':cap,'steps':steps,'summaryBytes':len(summary.encode()),'summaryLines':len(summary.splitlines()),'tasksUnchangedAfterReject':True,'historicalRetryDidNotClaimCurrency':True,'oldLogUnchanged':True,'allMutationsRestored':True},indent=2)+'\n')
print(json.dumps({'checks':len(steps),'passed':sum(x['ok'] for x in steps),'cap':cap,'summaryBytes':len(summary.encode()),'summaryLines':len(summary.splitlines())}))
