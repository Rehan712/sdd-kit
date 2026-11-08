from pathlib import Path
import datetime, hashlib, json, os, subprocess, sys, tempfile

ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT and os.environ['GIT_OPTIONAL_LOCKS']=='0'
assert len(sys.argv)==2 and sys.argv[1] in ('red','green')
phase=sys.argv[1]
R=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
D=R/'s69-o034-option-order-fix'/phase;D.mkdir(exist_ok=False)
prior=json.loads((R/'s67-opponent27-max-probes/classifier-results.json').read_text())
options=json.loads((R/'s67-opponent27-max-probes/option-order-results.json').read_text())
BASE=Path(prior['scratch'])/'case-159'
omitted=sorted({c['command'] for c in prior['cases']+options['casesDetail'] if c['expectedWarning'] and not c['observedWarning'] and c['exit']==0})
controls=sorted({c['command'] for c in options['casesDetail'] if c['reorderedControl']})
assert len(omitted)==30 and len(controls)==27
custom=['node scripts/assert-options.js --noEmit tests/unit.ts',
        'node scripts/assert-options.js tsc --project tests/tsconfig.json --noEmit',
        'node scripts/assert-options.js tsc --pretty false --noEmit tests/unit.ts',
        'node scripts/assert-options.js tsc --noEmit']
cases=[(c,True,'reported-omission') for c in omitted]+[(c,True,'reordered-control') for c in controls]+[(c,False,'custom-assertion-operand') for c in custom]
SCRATCH=Path(tempfile.mkdtemp(prefix='sdd003-s69-'+phase+'-',dir='/private/tmp'))
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(SCRATCH))
for k in ('BASH_ENV','ENV','CDPATH'):env.pop(k,None)
results=[]
for i,(command,want,group) in enumerate(cases):
    repo=SCRATCH/f'case-{i:03d}';spec=repo/'.specify/specs/001-feature';spec.mkdir(parents=True);(repo/'agents').mkdir()
    for n in ('opponent.agent.md','reality-check.agent.md'):(repo/'agents'/n).write_bytes((BASE/'agents'/n).read_bytes())
    (repo/'.specify/stack.yml').write_bytes((BASE/'.specify/stack.yml').read_bytes())
    for n in ('spec.md','plan.md','STATUS.md','tasks.md'):
        b=(BASE/'.specify/specs/001-feature'/n).read_text()
        if n=='tasks.md':
            old='`tsc --project tests/tsconfig.json --noEmit`';assert b.count(old)==1
            b=b.replace(old,'`'+command+'`')
        (spec/n).write_text(b)
    argv=['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
    start=datetime.datetime.now(datetime.timezone.utc).isoformat()
    z=subprocess.run(argv,cwd=ROOT,env=env,stdin=subprocess.DEVNULL,capture_output=True)
    own=D/f'case-{i:03d}';own.mkdir()
    for n,b in [('tasks.md',(spec/'tasks.md').read_bytes()),('stdout.txt',z.stdout),('stderr.txt',z.stderr)]: (own/n).write_bytes(b)
    observed=b'task T002 has an untyped AC Verify' in z.stdout
    results.append(dict(command=command,group=group,expectedWarning=want,observedWarning=observed,exit=z.returncode,asExpected=z.returncode==0 and observed==want and not z.stderr,argv=argv,cwd=str(ROOT),started=start,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),envOverrides={k:env[k] for k in ('GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR')},envUnset=['BASH_ENV','ENV','CDPATH'],hashes={n:hashlib.sha256((own/n).read_bytes()).hexdigest() for n in ('tasks.md','stdout.txt','stderr.txt')}))
summary=dict(phase=phase,cases=len(results),reportedOmissionsRetested=len(omitted),reorderedControls=len(controls),customControls=len(custom),allNativeExitsZero=all(c['exit']==0 for c in results),allDesiredBehavior=all(c['asExpected'] for c in results),reportedWarningsMissing=sum(not c['observedWarning'] for c in results if c['group']=='reported-omission'),reorderedControlsAllWarn=all(c['asExpected'] for c in results if c['group']=='reordered-control'),customUnexpectedWarnings=sum(c['observedWarning'] for c in results if c['group']=='custom-assertion-operand'),analyzerSHA256=hashlib.sha256((ROOT/'scripts/sdd-analyze.sh').read_bytes()).hexdigest(),scratch=str(SCRATCH),taskVerifyDataExecuted=False,results=results)
(D/'result.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='results'},indent=2))
assert summary['allNativeExitsZero'] and summary['reorderedControlsAllWarn']
if phase=='red':assert summary['reportedWarningsMissing']==30
else:assert summary['allDesiredBehavior']
