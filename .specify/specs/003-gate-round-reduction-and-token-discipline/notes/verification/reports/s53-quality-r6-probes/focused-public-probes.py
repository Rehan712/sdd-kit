from pathlib import Path
import hashlib,json,os,re,subprocess,tempfile,time
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
R=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
P=R/'s53-quality-r6-probes'
SCRATCH=Path(tempfile.mkdtemp(prefix='sdd-o034-quality-r6-',dir='/tmp')).resolve()
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0',NO_COLOR='1',LC_ALL='C',TMPDIR=str(SCRATCH))
for name in ['BASH_ENV','ENV','CDPATH']:ENV.pop(name,None)
def sha(b):return hashlib.sha256(b).hexdigest()
def save(path,b):
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('xb') as f:f.write(b)
def emit(path,obj):save(path,(json.dumps(obj,indent=2)+'\n').encode())
records=[]
def invoke(label,argv):
    start=time.time();p=subprocess.run(argv,cwd=ROOT,env=ENV,capture_output=True)
    out=P/'public'/label
    save(out.with_suffix('.stdout'),p.stdout);save(out.with_suffix('.stderr'),p.stderr)
    d={'label':label,'argv':argv,'cwd':str(ROOT),'environment_overrides':{'GIT_OPTIONAL_LOCKS':'0','NO_COLOR':'1','LC_ALL':'C','TMPDIR':str(SCRATCH),'BASH_ENV':None,'ENV':None,'CDPATH':None},'seconds':time.time()-start,'exit':p.returncode,'stdout_sha256':sha(p.stdout),'stderr_sha256':sha(p.stderr),'stdout':str(out.with_suffix('.stdout').relative_to(ROOT)),'stderr':str(out.with_suffix('.stderr').relative_to(ROOT))}
    records.append(d);return p,d
proj=SCRATCH/'project';spec=proj/'.specify/specs/001-fixture';spec.mkdir(parents=True)
(proj/'agents').mkdir();(proj/'agents/opponent.agent.md').write_text('Reviewer declaration\n');(proj/'agents/reality-check.agent.md').write_text('Reviewer declaration\n')
config="stacks: []\ngate_checks:\n  - 'bash checks.sh'\nreuse_checks: []\nverification_tools:\n  - 'bash'\nverification_inputs: []\n"
(proj/'.specify/stack.yml').write_text(config)
(spec/'spec.md').write_text('---\nspec: 001-fixture\n---\n# Spec\n- REQ-001: Check the behavior\n- AC-001: Return the correct result\n')
(spec/'plan.md').write_text('---\nplan_for: 001-fixture\n---\n# Plan\nCovers REQ-001 and AC-001.\n')
(spec/'STATUS.md').write_text('---\nphase: tasks\n---\n# Status\n')
def task(i,command,refs=True):
    return f'- [ ] **T{i:03}** — Check behavior\n  - *Files:* `tests/check.sh`\n  - *Acceptance:* Return the expected result.\n  - *Verify:* `{command}` → expected tests passed, build complete\n'+('  - *Refs:* REQ-001, AC-001\n' if refs else '')+'\n'
gates='''## Reality Check (pre-ship gate)
- [ ] **T990** — Opponent review
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* CLEARED
  - *Refs:* AC-001
- [ ] **T991** — Reality-check
  - *Agent:* agents/reality-check.agent.md
  - *Acceptance:* READY
  - *Refs:* AC-001
'''
for name in ['spec.md','plan.md','STATUS.md']:save(P/'public/base'/name,(spec/name).read_bytes())
save(P/'public/base/stack.yml',config.encode());save(P/'public/base/gates.md',gates.encode())
cases=[]
def add(group,command,warning):cases.append({'group':group,'command':command,'expected_warning':warning})
old=json.loads((R/'s47-opponent26-max-probes/public-classifier/results.json').read_text())
for row in old['results']:
    if row['group']=='original-op24':add('original-op24',row['command'],True)
for command in json.loads((R/'s47-opponent26-max-probes/attack-summary.json').read_text())['unique_omission_commands']:add('op26-exact',command,True)
for prefix in ['tools/tests/deep/','./tests/node_modules/.bin/','/opt/tests/toolchain/','../test/../tests/']:
    for cmd in ['tsc --noEmit tests/unit.ts','npm run build','pnpm run build','yarn typecheck','bun build','go build','make build','cargo build','test -f tests/check.sh']:
        add('directory-siblings',prefix+cmd,True)
for op in ['<in.txt','>out.txt','>>out.txt','>|out.txt','<>in.txt','<&0','>&1','&>out.txt']:
    add('redirect-siblings','./tools/tests/deep/npm'+op+' run build',True)
    add('redirect-siblings','./tests/node_modules/.bin/tsc '+op+' --noEmit tests/unit.ts',True)
    add('redirect-siblings','./tests/test -f'+op+' README.md',True)
    add('redirect-runner','./tools/tests/deep/npm'+op+' run test -- --grep typecheck',False)
    add('redirect-text','./tests/grep'+op+' pytest tests/check.sh',True)
for command in ['<tests/typecheck.txt ./tests/npm run build','0<tests/check.txt ./tests/test -e README.md','./tests/npm 2>tests/check.log run build','./tests/npm 2&>out.txt test typecheck.txt','npm2>out.txt test typecheck.txt','./tests/npm >&- run build','/usr/bin/grep >| out.txt tests README.md','./tests/rg AC-001 ./tests/npm','./tests/diff tests/a.txt tests/b.txt']:
    add('boundaries',command,True)
for command in ['./tests/npm test -- --grep typecheck','tools/tests/pnpm run test tests/build.ts','/opt/tests/yarn test typecheck','./tests/bun test tests/typecheck.ts','./tests/go test ./build','./tests/make test TARGET=typecheck','./tests/cargo test --test build','/opt/tests/node --test tests/typecheck.js','./tests/python3 -m pytest tests/build.py','./tests/pytest tests/typecheck.py','./tests/bats tests/build.bats','bash -ex ./tests/typecheck.sh','./tests/check-build.sh /usr/bin/grep','node scripts/assert-content.js ./tests/grep AC-001 README.md','node scripts/assert-content.js ./tools/rg AC-001 README.md','./tests/npmish --grep text','./tests/test-helper.sh tests/unit.ts','./tools/contest.py README.md']:
    add('runner-and-operands',command,False)
emit(P/'public/cases.json',cases)
results=[]
for i,case in enumerate(cases,1):
    label=f'case-{i:03}'
    text='# Tasks\n## Backend\n'+task(1,case['command'])+gates
    (spec/'tasks.md').write_text(text);save(P/'public'/f'{label}.tasks.md',text.encode())
    p,rec=invoke(label,['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)])
    out=p.stdout.decode(errors='replace');found='task T001 has an untyped AC Verify' in out
    passed=(p.returncode==0 and not p.stderr and found==case['expected_warning'] and ('warning(s), 0 errors' in out if found else 'consistent' in out))
    results.append(dict(case,id=i,passed=passed,observed_warning=found,exit=p.returncode,seconds=rec['seconds']))
text='# Tasks\n## Backend\n'+''.join(task(i,('./tests/npm run build' if i%2 else './tests/npm test -- --grep typecheck')) for i in range(1,100))+gates
(spec/'tasks.md').write_text(text);save(P/'public/load-101.tasks.md',text.encode())
p,rec=invoke('load-101',['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)])
load={'tasks':101,'warnings':p.stdout.count(b'untyped AC Verify'),'expected_warnings':50,'seconds':rec['seconds'],'exit':p.returncode,'passed':p.returncode==0 and b'101 task(s) parsed' in p.stdout and p.stdout.count(b'untyped AC Verify')==50 and b'0 errors' in p.stdout and not p.stderr}
helper=(ROOT/'tests/helpers.sh').read_text();body=helper.split('make_verification_spec_dir() {',1)[1].split('\n# tag_task',1)[0]
for name,data in re.findall(r'cat > "\$spec_dir/(spec.md|plan.md|tasks.md|STATUS.md)" <<\'EOF\'\n(.*?)\nEOF',body,re.S):
    (spec/name).write_text(data+'\n');save(P/'public/kinds'/name,(data+'\n').encode())
assert all((P/'public/kinds'/name).exists() for name in ['spec.md','plan.md','tasks.md','STATUS.md'])
p,rec=invoke('four-explicit-kinds',['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)])
kinds={'exit':p.returncode,'consistent':b'consistent' in p.stdout,'passed':p.returncode==0 and b'consistent' in p.stdout and not p.stderr,'helper_sha256':sha((ROOT/'tests/helpers.sh').read_bytes())}
emit(P/'public/command-records.json',records)
summary={'scratch':str(SCRATCH),'script_sha256':sha(Path(__file__).read_bytes()),'public_analyzer_sha256':sha((ROOT/'scripts/sdd-analyze.sh').read_bytes()),'count':len(results),'passing':sum(x['passed'] for x in results),'failures':[x for x in results if not x['passed']],'results':results,'load_101':load,'explicit_kinds':kinds,'path_stubs':False,'verify_data_executed':False,'full_suite_capture_floor_gate_static_rerun':False}
emit(P/'public/results.json',summary)
print(json.dumps({k:v for k,v in summary.items() if k!='results'},indent=2))
raise SystemExit(0 if not summary['failures'] and load['passed'] and kinds['passed'] else 1)
