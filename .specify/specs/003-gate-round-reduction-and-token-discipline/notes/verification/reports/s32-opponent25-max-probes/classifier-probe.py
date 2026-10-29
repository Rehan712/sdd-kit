from pathlib import Path
import subprocess, json, os, hashlib, datetime
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
scratch=Path(__file__).resolve().parent
kit=scratch/'kit'
out=scratch/'classifier'; out.mkdir(exist_ok=False)
sandbox=scratch/'authoring'; sandbox.mkdir()
setup=subprocess.run(['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_spec_dir','_',str(kit/'tests/helpers.sh'),str(sandbox)],cwd=root,text=True,capture_output=True)
assert setup.returncode==0,setup.stderr
spec=Path(setup.stdout.strip()); original=(spec/'tasks.md').read_text()
weak=[
 'tsc --noEmit tests/unit.ts', 'npm run typecheck -- --project tests/tsconfig.json',
 'grep AC-001 tests/check.sh', 'npm run build -- --outDir tests/build',
 'test -e README.md', 'test -f README.md', 'grep pytest README.md',
 'rg bats README.md', 'diff fixtures/test.txt actual.txt',
 'npm<tests/test-typecheck.txt run typecheck', 'grep<tools/npm test typecheck.txt',
 '/usr/bin/grep<input.txt AC-001 tests/check.sh', './tools/diff>output.txt fixtures/test.txt actual.txt',
 '>tests/node 3<input.txt /usr/bin/grep AC-001 README.md',
 '20<input.txt 2>tests/pytest ./tools/rg AC-001 README.md',
 './tests/diff 7>tests/check.sh old.txt new.txt',
 '/opt/test-tools/grep>>tests/bats.out AC-001 README.md',
 '/opt/test-tools/rg<>tests/check.sh AC-001 README.md',
 '\t/opt/test-tools/diff\told.txt\tnew.txt',
 'npm 10<tests/check.txt 20>tools/pytest run typecheck',
 '/opt/tools/tsc 123>tests/node --noEmit',
 'test 3<input.txt -f README.md 4>tests/check.sh',
 'test 3<input.txt -e README.md 4>tests/check.sh',
 'npm 2>tests/out 3<tests/in run build',
 'grep AC-001 tests/check.sh 2>>tests/typecheck.log',
 'npm3>tests/node test typecheck.txt'
]
clean=[
 'bash -e -x tests/typecheck.sh', '/bin/sh -eu tests/typecheck.sh',
 'zsh -v tests/typecheck.sh', '/usr/local/bin/cargo test --test build',
 '/usr/bin/python -m pytest tests/typecheck.py',
 '/usr/bin/python2 -m pytest tests/typecheck.py',
 '/usr/bin/node --test typecheck.test.js', '/usr/local/bin/bats tests/build.bats',
 '/opt/tools/pnpm run test --filter typecheck', '/opt/tools/yarn test --grep build',
 'bun test --filter typecheck', 'make test TARGET=build',
 '20<input.txt 2>output.txt bash -e tests/typecheck.sh',
 'bash -e 0<input.txt -x 2>output.txt tests/typecheck.sh',
 './tests/check.sh 13<input.txt 20>output.txt typecheck',
 'cargo 20<input.txt 2>output.txt test --test build',
 '/usr/bin/python3 3<input.txt -m 4>output.txt pytest typecheck.py',
 'npm 10<input.txt run 20>output.txt test -- --grep typecheck',
 'node 3<input.txt --test 20>output.txt typecheck.test.js',
 'node scripts/assert-content.js tests/grep AC-001 README.md',
 'node scripts/assert-content.js ./test-tools/rg AC-001 README.md',
 'bash scripts/assert-content.sh /usr/bin/diff old.txt new.txt'
]
results=[]
for kind,commands in [('weak',weak),('clean',clean)]:
 for command in commands:
  task=original.replace('`node --test test/thing.test.js`','`'+command+'`')
  assert task!=original
  (spec/'tasks.md').write_text(task)
  p=subprocess.run(['/bin/bash',str(kit/'scripts/sdd-analyze.sh'),str(spec)],cwd=root,text=True,capture_output=True,timeout=20)
  output=p.stdout+p.stderr; n=len(results)+1
  (out/(str(n).zfill(3)+'.tasks.md')).write_text(task)
  (out/(str(n).zfill(3)+'.output.txt')).write_text(output)
  warned='untyped AC Verify' in output
  correct=p.returncode==0 and warned==(kind=='weak') and (('warning(s), 0 errors' in output) if kind=='weak' else ('consistent' in output))
  results.append({'number':n,'kind':kind,'command':command,'argv':p.args,'cwd':str(root),'exit':p.returncode,'warned':warned,'ok':correct})
(out/'results.json').write_text(json.dumps({'results':results,'counts':{'weak':len(weak),'clean':len(clean),'passed':sum(x['ok'] for x in results)}},indent=2)+'\n')
print(json.dumps({'checks':len(results),'passed':sum(x['ok'] for x in results),'failures':[x for x in results if not x['ok']]}))
assert all(x['ok'] for x in results)
