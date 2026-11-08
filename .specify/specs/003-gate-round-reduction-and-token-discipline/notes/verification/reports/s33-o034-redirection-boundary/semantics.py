from pathlib import Path
import json, os, subprocess
scratch=Path(__file__).resolve().parent
r=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s33-o034-redirection-boundary')
shell=scratch/'semantics'; shell.mkdir(); out=r/'semantics'; out.mkdir()
for d in ('bin','tools','tests'): (shell/d).mkdir()
stub='#!/bin/bash\nprintf "%s\\0" "$0" "$@" > "$O034_ARGV"\nprintf "owned stub executed\\n"\n'
for name in ('grep','rg','diff','tsc','npm','bash','node','cargo','python3','pytest','bats','pnpm','yarn','bun','go','make'):
 for d in ('bin','tools','tests'):
  p=shell/d/name; p.write_text(stub); p.chmod(0o755)
p=shell/'tests/check-typecheck.sh'; p.write_text(stub); p.chmod(0o755)
for name in ('README.md','input.txt','out.txt','old','new','tests/typecheck.log','tests/check.log','tests/build.log','tests/build.txt'):
 (shell/name).write_text('neutral\n')
rows=[]
def check(command, exe, args, builtin=False):
 n=f'{len(rows)+1:03d}'; capture=out/(n+'.argv.nul'); env=dict(os.environ,PATH=str(shell/'bin')+':/usr/bin:/bin:/usr/sbin:/sbin',O034_ARGV=str(capture)); env.pop('BASH_ENV',None); env.pop('ENV',None)
 actual=command
 if exe.startswith('/usr/bin/'):
  actual=str(shell/'bin'/Path(exe).name)+command[len(exe):]; expected_exe=str(shell/'bin'/Path(exe).name)
 elif '/' not in exe and not builtin: expected_exe=str(shell/'bin'/exe)
 else: expected_exe=exe
 prefix='test() { printf "%s\\0" test "$@" > "$O034_ARGV"; builtin test "$@"; }; ' if builtin else ''
 argv=['/bin/bash','-c',prefix+actual]
 p=subprocess.run(argv,cwd=shell,env=env,capture_output=True,timeout=10)
 got=capture.read_bytes().split(b'\0')[:-1] if capture.exists() else []; got=[x.decode() for x in got]
 passed=p.returncode==0 and got==[expected_exe]+args
 (out/(n+'.stdout')).write_bytes(p.stdout); (out/(n+'.stderr')).write_bytes(p.stderr)
 row=dict(command=command,argv=argv,cwd=str(shell),PATH=env['PATH'],exit=p.returncode,expectedArgv=[expected_exe]+args,actualArgv=got,builtin=builtin,passed=passed); rows.append(row)
 assert passed,row
for tool in ('grep','rg','diff'):
 for prefix in ('','/usr/bin/','./tools/','tests/'):
  for redirect in ('>|out.txt',' >|out.txt','>| out.txt',' >| out.txt'):
   exe=prefix+tool; check(exe+redirect+' old new',exe,['old','new'])
weak=[('grepREDIRECT AC-001 README.md','grep',['AC-001','README.md']),('rg AC-001REDIRECT README.md','rg',['AC-001','README.md']),('diff oldREDIRECT new','diff',['old','new']),('tscREDIRECT --noEmit','tsc',['--noEmit']),('npm runREDIRECT typecheck','npm',['run','typecheck']),('npmREDIRECT run build','npm',['run','build']),('testREDIRECT -e README.md','test',['-e','README.md']),('test -fREDIRECT README.md','test',['-f','README.md'])]
clean=[('bashREDIRECT tests/typecheck.sh','bash',['tests/typecheck.sh']),('nodeREDIRECT --test test/build.js','node',['--test','test/build.js']),('cargo testREDIRECT --test typecheck','cargo',['test','--test','typecheck']),('python3 -mREDIRECT pytest tests/build.py','python3',['-m','pytest','tests/build.py']),('npm runREDIRECT test -- --grep typecheck','npm',['run','test','--','--grep','typecheck']),('./tests/check-typecheck.shREDIRECT /usr/bin/grep','./tests/check-typecheck.sh',['/usr/bin/grep'])]
for redir in ('<input.txt','>out.txt','>>out.txt','>|out.txt','<>input.txt','<&0','>&1','&>out.txt'):
 for space in ('',' '):
  for template,exe,args in weak+clean: check(template.replace('REDIRECT',space+redir),exe,args,exe=='test')
extra=[('npm&>tests/typecheck.log run build','npm',['run','build']),('tsc>&tests/check.log --noEmit','tsc',['--noEmit']),('bash&>tests/build.log tests/typecheck.sh','bash',['tests/typecheck.sh']),('npm>&tests/typecheck.log run test','npm',['run','test']),('node>|tests/build.log --test test/typecheck.js','node',['--test','test/typecheck.js']),('pytest<>tests/build.txt tests/typecheck.py','pytest',['tests/typecheck.py']),('bats&>out.txt tests/build.bats','bats',['tests/build.bats']),('pnpm>|out.txt test --filter typecheck','pnpm',['test','--filter','typecheck']),('yarn run>|out.txt test --grep typecheck','yarn',['run','test','--grep','typecheck']),('bun>|out.txt test tests/build.ts','bun',['test','tests/build.ts']),('go test>|out.txt ./typecheck','go',['test','./typecheck']),('make>|out.txt test TARGET=typecheck','make',['test','TARGET=typecheck'])]
for cmd,exe,args in extra: check(cmd,exe,args)
(out/'results.json').write_text(json.dumps(dict(total=len(rows),passed=sum(x['passed'] for x in rows),results=rows,limit='Absolute tool syntax uses absolute owned stubs; test() records argv then invokes builtin test. No task command executes on the host.'),indent=2)+'\n')
print(json.dumps(dict(total=len(rows),passed=sum(x['passed'] for x in rows))))
