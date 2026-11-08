from pathlib import Path
import os,sys,json,hashlib,tempfile,re,subprocess,datetime
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
OUT=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s67-opponent27-max-probes'
SCRATCH=Path(tempfile.mkdtemp(prefix='sdd003-op27-independent-',dir='/private/tmp'))
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(SCRATCH))
for name in ('CDPATH','BASH_ENV','ENV'): ENV.pop(name,None)
helper=(ROOT/'tests/helpers.sh').read_text()
legacy=helper.split('make_spec_dir() {',1)[1].split('\n}\n',1)[0]
new=helper.split('make_verification_spec_dir() {',1)[1].split('\n}\n',1)[0]
def docs(body):
 return {n:c for n,c in re.findall(r'cat > "\$spec_dir/([^"]+)" <<\x27EOF\x27\n(.*?)\nEOF',body,re.S)}
LEGACY=docs(legacy);NEW=docs(new)
assert set(LEGACY)=={'spec.md','plan.md','tasks.md','STATUS.md'}
cases=[]
def add(command,warn,group):cases.append({'command':command,'expectedWarning':warn,'group':group})
for prefix in ('','./tests/','test/','tools/tests/','./tests/node_modules/.bin/','/opt/test-tools/','../tools/'):
 for command in ('tsc --noEmit tests/unit.ts','npm run build','pnpm run typecheck','yarn run build','bun build','go build','make build','cargo build','test -f README.md'):
  add(prefix+command,True,'qualified-root-fix')
 for command in ('npm run test -- --grep typecheck','cargo test --test build','bun test tests/build.ts','go test ./build'):
  add(prefix+command,False,'qualified-runner')
for redirect in ('<input.txt','>out.txt','>>out.txt','>|out.txt','<>input.txt','<&0','>&1','&>out.txt'):
 for command in ('./tests/tsc@ --noEmit tests/unit.ts','test/test@ -e README.md','./tests/npm@ run build','/usr/bin/grep@ pytest tests/README.md'):
  add(command.replace('@',redirect),True,'redirect-siblings')
 for command in ('./tests/cargo@ test --test build','./tests/npm@ run test -- --grep typecheck'):
  add(command.replace('@',redirect),False,'redirect-runner')
for command in ('grep AC-001 tests/check.sh','rg bats README.md','diff fixtures/test.txt actual.txt','tsc --noEmit tests/unit.ts','npm run typecheck -- --project tests/tsconfig.json','npm run build -- --outDir tests/build','test -e README.md','test -f README.md','grep pytest README.md','npm 2&>out.txt test typecheck.txt','npm2>out.txt test typecheck.txt'):
 add(command,True,'original-and-numeric')
for command in ('bash -e tests/typecheck.sh','/bin/bash tests/typecheck.sh','./scripts/test-build.sh','node --test test/typecheck.test.js','python3 -m pytest tests/build.py','bats tests/build.bats','node scripts/assert-content.js /usr/bin/grep AC-001 README.md','./tests/check.sh ../tools/diff'):
 add(command,False,'runner-operand-control')
# New assumption: direct type-checker flags may precede --noEmit. No wrappers,
# quoted shell, compounds or backticks are involved in these declarations.
for prefix in ('','./tests/','tools/'):
 for args in ('--pretty false --noEmit tests/unit.ts','--project tests/tsconfig.json --noEmit','--noEmit --project tests/tsconfig.json'):
  add(prefix+'tsc '+args,True,'typecheck-option-order')
# Genuine test-looking names that contain known names are not those tools.
for command in ('./tests/npm-check.sh typecheck','./tests/tsc-test.sh build','./tests/test-runner.sh typecheck','./tests/grep-check.sh typecheck'):
 add(command,False,'basename-boundary')
for command in ('>tests/npm ./tests/tsc --noEmit tests/unit.ts','2>tests/check ./tests/npm run build','<input.txt /usr/bin/grep AC-001 README.md','./tests/npm run 3>out.txt build'):
 add(command,True,'leading-and-multiword-redirect')
results=[]
for i,case in enumerate(cases):
 d=SCRATCH/f'case-{i:03d}';spec=d/'.specify/specs/001-feature';spec.mkdir(parents=True)
 (d/'agents').mkdir();(d/'agents/opponent.agent.md').write_text('declared persona\n');(d/'agents/reality-check.agent.md').write_text('declared persona\n')
 (d/'.specify/stack.yml').write_text("stacks: []\ngate_checks:\n  - 'bash tests/check.sh'\nreuse_checks: []\nverification_tools:\n  - 'bash'\nverification_inputs: []\n")
 ds=dict(LEGACY);ds['tasks.md']=ds['tasks.md'].replace('`node --test test/thing.test.js`','`'+case['command']+'`')
 for name,body in ds.items():(spec/name).write_text(body+'\n')
 argv=['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
 r=subprocess.run(argv,cwd=str(ROOT),env=ENV,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 cap=OUT/f'case-{i:03d}';cap.mkdir()
 (cap/'tasks.md').write_bytes((spec/'tasks.md').read_bytes());(cap/'stdout.txt').write_bytes(r.stdout);(cap/'stderr.txt').write_bytes(r.stderr)
 warning=b'task T002 has an untyped AC Verify' in r.stdout
 good=r.returncode==0 and warning==case['expectedWarning'] and ((b'warning(s), 0 errors' in r.stdout) if warning else (b'consistent' in r.stdout))
 row=dict(case,index=i,argv=argv,cwd=str(ROOT),envOverrides={n:ENV[n] for n in ('GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR')},envUnset=['CDPATH','BASH_ENV','ENV'],exit=r.returncode,observedWarning=warning,asExpected=good)
 row['hashes']={n:hashlib.sha256((cap/n).read_bytes()).hexdigest() for n in ('tasks.md','stdout.txt','stderr.txt')}
 results.append(row)
 if (i+1)%40==0:print('completed',i+1,flush=True)
# All four explicit kinds in the documented new-contract fixture, one public call.
d=SCRATCH/'explicit-kinds';spec=d/'.specify/specs/003-verification-fixture';spec.mkdir(parents=True);(d/'agents').mkdir()
for n in ('opponent.agent.md','reality-check.agent.md'):(d/'agents'/n).write_text('declared persona\n')
(d/'.specify/stack.yml').write_text("stacks: []\ngate_checks:\n  - 'bash tests/check.sh'\nreuse_checks: []\nverification_tools:\n  - 'bash'\nverification_inputs: []\n")
for name,body in NEW.items():(spec/name).write_text(body+'\n')
argv=['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
r=subprocess.run(argv,cwd=str(ROOT),env=ENV,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
cap=OUT/'explicit-kinds';cap.mkdir()
for name in NEW:(cap/name).write_bytes((spec/name).read_bytes())
(cap/'stdout.txt').write_bytes(r.stdout);(cap/'stderr.txt').write_bytes(r.stderr)
control={'argv':argv,'cwd':str(ROOT),'envOverrides':{n:ENV[n] for n in ('GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR')},'exit':r.returncode,'asExpected':r.returncode==0 and b'consistent' in r.stdout and b'untyped AC Verify' not in r.stdout}
(OUT/'classifier-results.json').write_text(json.dumps({'scratch':str(SCRATCH),'helperSha256':hashlib.sha256((ROOT/'tests/helpers.sh').read_bytes()).hexdigest(),'analyzerSha256':hashlib.sha256((ROOT/'scripts/sdd-analyze.sh').read_bytes()).hexdigest(),'cases':results,'explicitKindsControl':control},indent=2)+'\n')
fails=[x for x in results if not x['asExpected']]
summary={'cases':len(results),'publicInvocations':len(results)+1,'mismatches':len(fails),'explicitKindsControl':control,'failures':[{k:x[k] for k in ('index','command','group','exit','observedWarning')} for x in fails]}
(OUT/'classifier-summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
