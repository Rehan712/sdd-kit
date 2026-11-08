from pathlib import Path
import os, json, re, shlex, hashlib, time, datetime, subprocess, stat, sys
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
REPORTS=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
OWN=REPORTS/'s72-quality-r7-probes'
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
def save(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(data if isinstance(data,bytes) else data.encode())
def jsave(path,data):save(path,json.dumps(data,indent=2,sort_keys=True)+'\n')
def sha(b):return hashlib.sha256(b).hexdigest()
helpers=(ROOT/'tests/helpers.sh').read_text()
body=helpers.split('make_spec_dir() {',1)[1].split('# make_verification_spec_dir',1)[0]
templates=dict(re.findall(r'cat > "\$spec_dir/([^"]+)" <<\'EOF\'\n(.*?)\nEOF',body,re.S))
assert set(templates)=={'spec.md','plan.md','STATUS.md','tasks.md'}
config=helpers.split('make_fixture_gate_config() {',1)[1].split("<<'EOF'\n",1)[1].split('\nEOF',1)[0]+'\n'
def build(name,command=None,tasks=None,missing_acceptance=False):
 project=OWN/'fixtures'/name
 spec=project/'.specify/specs/001-test-feature'
 for filename,text in templates.items():
  if filename=='tasks.md':
   if tasks is not None:text=tasks
   else:
    marker=chr(96)+'node --test test/thing.test.js'+chr(96)
    assert text.count(marker)==1
    text=text.replace(marker,chr(96)+command+chr(96),1)
    if missing_acceptance:text=text.replace('  - *Acceptance:* unit test passes\n','',1)
  save(spec/filename,text+'\n')
 save(project/'.specify/stack.yml',config)
 save(project/'agents/opponent.agent.md','Reviewer path metadata only; never executed.\n')
 save(project/'agents/reality-check.agent.md','Reviewer path metadata only; never executed.\n')
 return spec
env=os.environ.copy()
for k in ['BASH_ENV','ENV','CDPATH']:env.pop(k,None)
tmp=OWN/'temporary'
tmp.mkdir()
env.update(GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(tmp))
nonsecret={k:env[k] for k in ['GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR','PATH','LANG'] if k in env}
cases=[]
def add(group,command,weak=True):cases.append({'id':f'case-{len(cases)+1:03}','group':group,'command':command,'expectedWeak':weak})
for command in [
 'tsc --project tests/tsconfig.json --noEmit',
 'tsc --pretty false --noEmit tests/unit.ts',
 'tsc --strict --target es2020 --module commonjs --noEmit tests/unit.ts',
 'tsc tests/unit.ts --strict --noEmit',
 'tsc --noEmit --pretty false tests/unit.ts',
 'tsc --project=tests/tsconfig.json --pretty=false --noEmit',
 'tsc\t--project\ttests/tsconfig.json\t--pretty\tfalse\t--noEmit\t',
 '  tsc   --pretty   false   --noEmit   tests/unit.ts  ',
 'tsc --noEmit --noEmit tests/unit.ts',
 'tsc --project tests/tsconfig.json --noEmit --pretty false',
 'tsc --pretty false --project tests/tsconfig.json --strict --noEmit',
 'tsc --noEmit tests/unit.ts'
]:add('direct-option-orders',command)
for prefix in ['./tests/','tests/','test/','tools/tests/','./tests/node_modules/.bin/','tools/','/opt/tests/bin/','../tools/']:
 add('qualified-order',prefix+'tsc --strict --pretty false --noEmit tests/unit.ts')
for redirect in ['<tests/input.txt','>tests/output.txt','>>tests/output.txt','>|tests/output.txt','<>tests/input.txt','<&0','>&1','&>tests/output.txt']:
 add('interleaved-redirect-order','tsc --project tests/tsconfig.json'+redirect+' --pretty false --noEmit')
 add('trailing-redirect-order','./tests/tsc --pretty false --noEmit'+redirect+' tests/unit.ts')
for command in [
 '0<tests/input.txt tsc --project tests/tsconfig.json --noEmit',
 'tsc --project tests/tsconfig.json 2>tests/pytest --pretty false --noEmit',
 'tsc --pretty false 1>&2 --noEmit tests/unit.ts',
 'tsc --project tests/tsconfig.json 0<input.txt 1>output.txt 2>&1 --noEmit',
 'tests/tsc --project tests/tsconfig.json > tests/out.log --noEmit',
 'tsc --pretty false --noEmit >tests/test-report.log'
]:add('fd-and-spacing-boundaries',command)
for command in [
 'node scripts/assert-options.js tsc --project tests/tsconfig.json --noEmit',
 'node scripts/assert-options.js tsc --pretty false --noEmit tests/unit.ts',
 'node scripts/assert-options.js tsc --noEmit',
 '/usr/bin/node scripts/assert-options.js tools/tsc --project tests/tsconfig.json --noEmit',
 './scripts/assert-options.js tsc --project tests/tsconfig.json --noEmit',
 'mytsc --pretty false --noEmit tests/unit.ts',
 'tsc-helper --pretty false --noEmit tests/unit.ts',
 'node scripts/assert-options.js --noEmit tests/unit.ts',
 'node scripts/assert-options.js 2>tests/out.log tsc --pretty false --noEmit',
 './tests/assert-options.sh tsc --pretty false --noEmit tests/unit.ts'
]:add('executable-and-operand-boundaries',command,False)
for command in [
 'grep pytest tests/check.sh','./tests/rg bats README.md',
 '/usr/bin/diff fixtures/test.txt actual.txt','grep>tests/check.sh AC-001 README.md',
 './tests/npm run build','tools/tests/cargo build','test/test -f tests/check.sh',
 'npm<tools/pytest run typecheck'
]:add('prior-root-weak-controls',command)
for command in [
 'bash -eux tests/typecheck.sh','node --test test/build.js',
 './tests/npm run test -- --grep typecheck','/opt/tests/bin/cargo test --test build',
 'python3 -m pytest tests/typecheck.py','./tests/check-typecheck.sh /usr/bin/grep',
 'node scripts/assert-options.js /usr/bin/grep README.md',
 'npm>tests/check.txt run test -- --grep typecheck'
]:add('prior-root-runner-controls',command,False)
def invoke(case,spec,expected_ids,exitcode=0,allow_guideline=False):
 argv=['/bin/bash','--norc',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
 start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic()
 run=subprocess.run(argv,cwd=str(ROOT),env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=30)
 duration=time.monotonic()-t
 receipt=OWN/'calls'/case['id']
 save(receipt/'stdout.txt',run.stdout);save(receipt/'stderr.txt',run.stderr)
 got=re.findall(rb'task (T[0-9]{3}[a-z0-9]*) has an untyped AC Verify',run.stdout)
 got=[s.decode() for s in got]
 manifest={}
 for p in sorted(spec.parents[2].rglob('*')):
  if p.is_file():
   s=p.stat();manifest[str(p.relative_to(spec.parents[2]))]={'sha256':sha(p.read_bytes()),'mode':stat.S_IMODE(s.st_mode),'mtimeNs':s.st_mtime_ns}
 result=dict(case,argv=argv,cwd=str(ROOT),nonsecretEnv=nonsecret,envUnset=['BASH_ENV','ENV','CDPATH'],started=start,elapsedSeconds=duration,exit=run.returncode,expectedExit=exitcode,expectedWarningTaskIds=expected_ids,warningTaskIds=got,stdoutSHA256=sha(run.stdout),stderrSHA256=sha(run.stderr),inputFiles=manifest)
 result['passed']=(run.returncode==exitcode and got==expected_ids and not run.stderr and (allow_guideline or (('consistent' in run.stdout.decode()) if not expected_ids and exitcode==0 else True)))
 jsave(receipt/'result.json',result)
 return result
results=[]
for case in cases:
 spec=build(case['id'],case['command'])
 results.append(invoke(case,spec,['T002'] if case['expectedWeak'] else []))
load=['---','tasks_for: 001-test-feature','---','# Tasks','## Backend','']
load_expected=[]
for n in range(1,100):
 weak=n%2==1
 command='./tests/tsc --strict --project tests/tsconfig.json --pretty false --noEmit' if weak else 'node scripts/assert-options.js tsc --project tests/tsconfig.json --noEmit'
 load.extend([f'- [ ] **T{n:03}** — Probe task', '  - *Files:* src/thing.js','  - *Acceptance:* Check the stated behavior.',f'  - *Verify:* '+chr(96)+command+chr(96)+' → observed','  - *Refs:* REQ-001, AC-001, AC-002',''])
 if weak:load_expected.append(f'T{n:03}')
load.extend(['## Reality Check (pre-ship gate)',''])
for n,name,label in [(100,'opponent','Opponent'),(101,'reality-check','Reality-check')]:
 load.extend([f'- [ ] **T{n:03}** — {label} review',f'  - *Agent:* agents/{name}.agent.md','  - *Acceptance:* Independent review passes.','  - *Refs:* AC-001, AC-002',''])
case={'id':'load-101','group':'101-task-local-cli','taskCount':101}
spec=build(case['id'],tasks='\n'.join(load))
out=invoke(case,spec,load_expected,allow_guideline=True)
out['parsed101']=b'101 task(s) parsed' in (OWN/'calls/load-101/stdout.txt').read_bytes()
out['passed']=out['passed'] and out['parsed101'];jsave(OWN/'calls/load-101/assertions.json',{'parsed101':out['parsed101'],'passed':out['passed']})
results.append(out)
case={'id':'error-propagation','group':'warning-with-error','command':'tsc --pretty false --noEmit tests/unit.ts'}
spec=build(case['id'],case['command'],missing_acceptance=True)
results.append(invoke(case,spec,['T002'],exitcode=1))
case={'id':'long-options','group':'regex-length','command':'tsc '+('tests/unit.ts '*4096)+'--noEmit','argumentWords':4097}
spec=build(case['id'],case['command'])
results.append(invoke(case,spec,['T002']))
summary={'cases':len(results),'passed':sum(x['passed'] for x in results),'failed':[x['id'] for x in results if not x['passed']],'singleCommandCases':len(cases),'groups':{},'loadElapsedSeconds':out['elapsedSeconds'],'longOptionsElapsedSeconds':results[-1]['elapsedSeconds'],'allVerifyValuesWereDataOnly':True,'noPATHStubs':True,'newExternalScratch':False,'helpersSHA256':sha((ROOT/'tests/helpers.sh').read_bytes()),'results':results}
for x in results:summary['groups'][x['group']]=summary['groups'].get(x['group'],0)+1
jsave(OWN/'probe-results.json',summary)
print(json.dumps({k:v for k,v in summary.items() if k!='results'}))
sys.exit(0 if not summary['failed'] else 1)
