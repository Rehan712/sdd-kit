from pathlib import Path
import subprocess,json,os,hashlib
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
scratch=Path(__file__).resolve().parent; kit=scratch/'kit'
out=scratch/'noclobber-corrected'; out.mkdir(exist_ok=False)
spec=scratch/'authoring/proj/.specify/specs/001-test-feature'
original=(scratch/'classifier/001.tasks.md').read_text().replace('`tsc --noEmit tests/unit.ts`','`node --test test/thing.test.js`')
assert '`node --test test/thing.test.js`' in original
shell=scratch/'shell-semantics-corrected'; shell.mkdir(); (shell/'bin').mkdir(); (shell/'tools').mkdir(); (shell/'tests').mkdir()
stub='#!/bin/bash\nprintf "%s\\0" "$0" "$@" > "$OP25_ARGV"\nprintf "owned stub executed\\n"\n'
for tool in ('grep','rg','diff'):
 for d in ('bin','tools','tests'):
  p=shell/d/tool; p.write_text(stub); p.chmod(0o755)
(shell/'README.md').write_text('AC-001\n'); (shell/'old').write_text('same\n'); (shell/'new').write_text('same\n')
env=dict(os.environ,PATH=str(shell/'bin')+':/usr/bin:/bin:/usr/sbin:/sbin',NO_COLOR='1')
results=[]
for tool in ('grep','rg','diff'):
 for prefix in ('','/usr/bin/','./tools/','tests/'):
  exe=prefix+tool; args='old new' if tool=='diff' else 'AC-001 README.md'
  for redirect in ('>out.txt','>|out.txt',' >|out.txt','>| out.txt'):
   command=exe+redirect+' '+args
   task=original.replace('`node --test test/thing.test.js`','`'+command+'`'); (spec/'tasks.md').write_text(task)
   p=subprocess.run(['/bin/bash',str(kit/'scripts/sdd-analyze.sh'),str(spec)],cwd=root,env=dict(env,PATH='/usr/bin:/bin:/usr/sbin:/sbin'),text=True,capture_output=True,timeout=20)
   n=len(results)+1; label=str(n).zfill(3)
   (out/(label+'.tasks.md')).write_text(task); (out/(label+'.output.txt')).write_text(p.stdout+p.stderr)
   # All shell execution uses OWN stubs. The absolute syntax gets an absolute owned tool.
   shell_exe=str(shell/'bin'/tool) if prefix=='/usr/bin/' else exe
   shell_command=shell_exe+redirect+' '+args
   capture=out/(label+'.argv.nul'); senv=dict(env,OP25_ARGV=str(capture))
   (shell/'out.txt').write_text('pre-existing output\n')
   s=subprocess.run(['/bin/bash','-c',shell_command],cwd=shell,env=senv,text=True,capture_output=True,timeout=10)
   assert s.returncode==0,(shell_command,s.returncode,s.stderr)
   argv=capture.read_bytes().split(b'\0')[:-1]
   assert [v.decode() for v in argv[1:]]==args.split(),(shell_command,argv)
   assert (shell/'out.txt').read_text()=='owned stub executed\n'
   warned='untyped AC Verify' in p.stdout
   rows={'number':n,'command':command,'analyzerArgv':p.args,'analyzerCwd':str(root),'exit':p.returncode,'warned':warned,'consistent':'consistent' in p.stdout,'shellArgv':s.args,'shellCwd':str(shell),'shellCommand':shell_command,'shellExit':s.returncode,'executedArgv':[v.decode() for v in argv],'ownedStub':True}
   results.append(rows)
expected_missing=[x for x in results if '>|' in x['command'] and ' >|' not in x['command']]
assert len(expected_missing)==24
assert all(x['exit']==0 and not x['warned'] and x['consistent'] for x in expected_missing)
assert all(x['exit']==0 and x['warned'] for x in results if x not in expected_missing)
(out/'results.json').write_text(json.dumps({'total':len(results),'missingWarnings':len(expected_missing),'controls':len(results)-len(expected_missing),'results':results,'interpretation':'Each attached >| or >| space form is a direct known text-tool command with output redirection; all tested shell commands use owned stubs.'},indent=2)+'\n')
print(json.dumps({'total':len(results),'missingWarnings':len(expected_missing),'warningControls':len(results)-len(expected_missing),'shellSemanticsPassed':len(results)}))
