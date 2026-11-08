from pathlib import Path
import os,json,tempfile,shutil,subprocess,hashlib,datetime
root=Path.cwd();reports=root/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports';out=reports/'s47-opponent26-max-probes/public-classifier';out.mkdir()
scratch=Path(tempfile.mkdtemp(prefix='sdd-opponent26-classifier-'));kit=scratch/'kit';kit.mkdir();shutil.copytree(root/'scripts',kit/'scripts');(kit/'tests').mkdir();shutil.copy2(root/'tests/helpers.sh',kit/'tests/helpers.sh')
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0',NO_COLOR='1',LC_ALL='C')
cp=subprocess.run(['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_spec_dir','_',str(kit/'tests/helpers.sh'),str(scratch/'fixture')],cwd=root,env=env,capture_output=True,text=True);assert cp.returncode==0,cp.stderr
spec=Path(cp.stdout.strip().splitlines()[-1]);baseline=(spec/'tasks.md').read_text();needle='`node --test test/thing.test.js`';assert baseline.count(needle)==1
cases=[]
def add(group,command,warning):
 if not any(x['command']==command for x in cases):cases.append({'group':group,'command':command,'expected_warning':warning})
for c in ['tsc --noEmit tests/unit.ts','npm run typecheck -- --project tests/tsconfig.json','grep AC-001 tests/check.sh','npm run build -- --outDir tests/build','test -e README.md','test -f README.md','grep pytest README.md','rg bats README.md','diff fixtures/test.txt actual.txt']:add('original-op24',c,True)
for tool in ['grep','rg','diff']:
 for prefix in ['','/usr/bin/','./tools/','tests/']:
  for boundary in ['>|out.txt','>| out.txt',' >|out.txt',' >| out.txt']:add('op25-noclobber',prefix+tool+boundary+' old new',True)
for op in ['<input.txt','>out.txt','>>out.txt','>|out.txt','<>input.txt','<&0','>&1','&>out.txt']:
 for space in ['',' ']:
  for command in ['npm runREDIRECT typecheck','tscREDIRECT --noEmit','test -fREDIRECT README.md']:
   add('weak-redirect',command.replace('REDIRECT',space+op),True)
  for command in ['npm runREDIRECT test -- --grep typecheck','nodeREDIRECT --test test/build.js','bashREDIRECT tests/typecheck.sh']:
   add('runner-redirect',command.replace('REDIRECT',space+op),False)
for prefix in ['tests/','./tests/','./test/','./tools/tests/']:
 for command in ['tsc --noEmit tests/unit.ts','npm run build','npm run typecheck','test -f README.md']:
  add('qualified-weak-executable',prefix+command,True)
for command in ['tsc --noEmit tests/unit.ts','npm run build','npm run typecheck','test -f README.md']:
 add('qualified-weak-control','./tools/'+command,True)
for command in ['npm 2&>out.txt test typecheck.txt','npm2>out.txt test typecheck.txt','npm 2>out.txt test -- --grep typecheck','bash 0<input.txt -e tests/typecheck.sh','node scripts/assert-content.js /usr/bin/grep AC-001 README.md','./tests/check.sh ./tools/diff','./tests/check-build.sh','/bin/bash tests/check.sh /usr/bin/grep']:
 add('numeric-and-operands',command,command.startswith('npm 2&>') or command.startswith('npm2>'))
results=[]
for i,case in enumerate(cases,1):
 text=baseline.replace(needle,'`'+case['command']+'`');(spec/'tasks.md').write_text(text)
 argv=[str(kit/'scripts/sdd-analyze.sh'),str(spec)];cp=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True)
 stem=f'case-{i:03d}';(out/(stem+'.tasks.md')).write_text(text);(out/(stem+'.stdout')).write_text(cp.stdout);(out/(stem+'.stderr')).write_text(cp.stderr)
 observed='untyped AC Verify' in cp.stdout
 result=dict(case,id=i,argv=argv,cwd=str(root),GIT_OPTIONAL_LOCKS='0',exit=cp.returncode,observed_warning=observed,passed=cp.returncode==0 and observed==case['expected_warning'],stdout_sha256=hashlib.sha256(cp.stdout.encode()).hexdigest());results.append(result)
record={'at':datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),'scratch':str(scratch),'interpreter':subprocess.check_output(['/bin/bash','--version'],cwd=root,env=env,text=True).splitlines()[0],'count':len(results),'passing':sum(r['passed'] for r in results),'failing':[r for r in results if not r['passed']],'results':results,'copied_scripts':{str(p.relative_to(kit)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(kit.rglob('*')) if p.is_file()},'task_verify_strings_executed':False,'path_stubs':False}
with (out/'results.json').open('x') as f:json.dump(record,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in record.items() if k in ['at','scratch','interpreter','count','passing','failing']},indent=2))
