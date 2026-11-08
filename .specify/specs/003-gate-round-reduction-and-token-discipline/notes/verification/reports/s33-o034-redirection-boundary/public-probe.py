from pathlib import Path
import json,os,subprocess,shutil
scratch=Path(__file__).resolve().parent
r=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s33-o034-redirection-boundary'); b=json.loads((r/'baseline.json').read_text()); c=Path(b['candidate']); root=Path(b['root'])
env=dict(os.environ,PATH='/usr/bin:/bin:/usr/sbin:/sbin',GIT_OPTIONAL_LOCKS='0',NO_COLOR='1'); env.pop('BASH_ENV',None); env.pop('ENV',None)
sandbox=scratch/'public-fixture'; sandbox.mkdir(); env['SANDBOX']=str(sandbox)
cmd=['/bin/bash','-c','. "$1/tests/helpers.sh"; make_spec_dir','_',str(c)]
p=subprocess.run(cmd,cwd=c,env=env,capture_output=True,check=True); spec=Path(p.stdout.decode().strip()); original=(spec/'tasks.md').read_text(); assert '`node --test test/thing.test.js`' in original
prior=r.parent/'s32-opponent25-max-probes/noclobber-corrected/results.json'; cases=[dict(command=x['command'],kind='weak') for x in json.loads(prior.read_text())['results']]
extra=[('tsc>&tests/check.log --noEmit','weak'),('npm&>tests/typecheck.log run build','weak'),('npm run>&1 typecheck','weak'),('test -f<&0 README.md','weak'),('tsc 2>&- --noEmit','weak'),('npm 0<&- run build','weak'),('grep 2>&1 AC-001 README.md','weak'),('rg<>input.txt AC-001 README.md','weak'),('diff>>out.txt old new','weak'),('npm2>&1 test typecheck.txt','weak'),('bash&>tests/build.log tests/typecheck.sh','clean'),('npm>&tests/typecheck.log run test','clean'),('node>|tests/build.log --test test/typecheck.js','clean'),('pytest<>tests/build.txt tests/typecheck.py','clean'),('cargo test&>out.txt --test typecheck','clean'),('python3 -m<&0 pytest tests/build.py','clean'),('npm run>&1 test -- --grep typecheck','clean'),('bash 2>&- tests/typecheck.sh','clean'),('node scripts/assert-content.js /usr/bin/grep','clean'),('node scripts/assert-content.js ./tools/rg','clean'),('node scripts/assert-content.js tests/diff','clean')]
cases += [dict(command=cmd,kind=kind) for cmd,kind in extra]
red=scratch/'red-kit'; (red/'scripts').mkdir(parents=True)
for p in (c/'scripts').iterdir():
 if p.is_file(): shutil.copy2(p,red/'scripts'/p.name)
shutil.copy2(r/'before/scripts/sdd-analyze.sh',red/'scripts/sdd-analyze.sh')
allrows=[]
for phase,kit in [('red',red),('green',c)]:
 out=r/(phase+'-public-probe'); out.mkdir(); rows=[]
 for n,case in enumerate(cases,1):
  label=f'{n:03d}'; task=original.replace('`node --test test/thing.test.js`','`'+case['command']+'`'); (spec/'tasks.md').write_text(task); (out/(label+'.tasks.md')).write_text(task)
  args=['/bin/bash',str(kit/'scripts/sdd-analyze.sh'),str(spec)]; p=subprocess.run(args,cwd=c,env=env,capture_output=True,timeout=30); (out/(label+'.stdout')).write_bytes(p.stdout); (out/(label+'.stderr')).write_bytes(p.stderr); text=p.stdout.decode(); warned='untyped AC Verify' in text
  row=dict(**case,argv=args,cwd=str(c),PATH=env['PATH'],exit=p.returncode,warned=warned,consistent='consistent' in text,passed=p.returncode==0 and warned==(case['kind']=='weak')); rows.append(row)
 result=dict(phase=phase,total=len(rows),passed=sum(x['passed'] for x in rows),missingWeakWarnings=sum(x['kind']=='weak' and not x['warned'] for x in rows),wrongRunnerWarnings=sum(x['kind']=='clean' and x['warned'] for x in rows),results=rows); (out/'results.json').write_text(json.dumps(result,indent=2)+'\n'); allrows.append(result); print(json.dumps({k:v for k,v in result.items() if k!='results'}),flush=True)
 if phase=='green': assert all(x['passed'] for x in rows)
assert all(x['exit']==0 for y in allrows for x in y['results'])
