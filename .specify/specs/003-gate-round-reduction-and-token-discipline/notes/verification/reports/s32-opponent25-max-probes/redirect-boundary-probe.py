from pathlib import Path
import subprocess,json,os
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
scratch=Path(__file__).resolve().parent; kit=scratch/'kit'
out=scratch/'redirect-boundary'; out.mkdir(exist_ok=False)
spec=scratch/'authoring/proj/.specify/specs/001-test-feature'
original=(scratch/'classifier/001.tasks.md').read_text().replace('`tsc --noEmit tests/unit.ts`','`node --test test/thing.test.js`')
assert '`node --test test/thing.test.js`' in original
commands=['grep>out.txt AC-001 README.md','grep>|out.txt AC-001 README.md','grep >|out.txt AC-001 README.md','/usr/bin/grep>|out.txt AC-001 README.md','./tools/rg>|out.txt AC-001 README.md','tests/diff>|out.txt actual expected','test -e README.md','[ -e README.md ]','[ -f README.md ]','[[ -e README.md ]]']
results=[]
for n,command in enumerate(commands,1):
 task=original.replace('`node --test test/thing.test.js`','`'+command+'`'); (spec/'tasks.md').write_text(task)
 p=subprocess.run(['/bin/bash',str(kit/'scripts/sdd-analyze.sh'),str(spec)],cwd=root,text=True,capture_output=True,timeout=20)
 (out/(str(n).zfill(2)+'.tasks.md')).write_text(task); (out/(str(n).zfill(2)+'.output.txt')).write_text(p.stdout+p.stderr)
 results.append({'command':command,'argv':p.args,'cwd':str(root),'exit':p.returncode,'warned':'untyped AC Verify' in p.stdout,'consistent':'consistent' in p.stdout})
(out/'results.json').write_text(json.dumps(results,indent=2)+'\n'); print(json.dumps(results,indent=2))
