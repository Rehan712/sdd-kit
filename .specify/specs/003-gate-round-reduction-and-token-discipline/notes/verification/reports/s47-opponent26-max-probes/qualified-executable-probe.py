from pathlib import Path
import os,json,hashlib,tempfile,shutil,subprocess,datetime
root=Path.cwd();out=root/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s47-opponent26-max-probes/qualified-executable';out.mkdir();scratch=Path(tempfile.mkdtemp(prefix='sdd-opponent26-qualified-'));kit=scratch/'kit';kit.mkdir();shutil.copytree(root/'scripts',kit/'scripts');(kit/'tests').mkdir();shutil.copy2(root/'tests/helpers.sh',kit/'tests/helpers.sh');env=dict(os.environ,GIT_OPTIONAL_LOCKS='0',NO_COLOR='1',LC_ALL='C')
setup=['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_spec_dir','_',str(kit/'tests/helpers.sh'),str(scratch/'fixture')];cp=subprocess.run(setup,cwd=root,env=env,capture_output=True,text=True);assert cp.returncode==0;spec=Path(cp.stdout.strip());repo=spec.parents[2];base=(spec/'tasks.md').read_text();needle='`node --test test/thing.test.js`'
(repo/'README.md').write_text('Presence alone proves no application behavior.\n')
for d in ['tests','tools']:
 (repo/d).mkdir(exist_ok=True);(repo/d/'test').symlink_to('/bin/test')
real=[]
for present in [True,False]:
 if not present:(repo/'README.md').unlink()
 for d in ['tests','tools']:
  argv=[str(repo/d/'test'),'-f',str(repo/'README.md')];cp=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True);assert cp.returncode==(0 if present else 1)
  real.append({'present':present,'argv':argv,'cwd':str(root),'GIT_OPTIONAL_LOCKS':'0','exit':cp.returncode,'stdout':cp.stdout,'stderr':cp.stderr,'resolved_executable':str((repo/d/'test').resolve()),'binary_sha256':hashlib.sha256((repo/d/'test').read_bytes()).hexdigest()})
cases=[]
for prefix in ['./tests/','./test/','./tests/node_modules/.bin/','./tools/']:
 for tail in ['tsc --noEmit tests/unit.ts','npm run build','npm run typecheck','test -f README.md']:
  cases.append((prefix+tail,True,'qualified-weak'))
for redir in ['<input.txt','>out.txt','>>out.txt','>|out.txt','<>input.txt','<&0','>&1','&>out.txt']:
 cases.append(('./tests/npm'+redir+' run typecheck',True,'redirected-qualified-weak'))
for c,w in [('./tests/grep AC-001 README.md',True),('./tests/npm run test -- --grep typecheck',False),('bash tests/typecheck.sh',False),('./tests/check-build.sh',False),('./tools/test -f README.md',True)]:cases.append((c,w,'sibling-control'))
results=[]
for i,(command,expected,group) in enumerate(cases,1):
 (spec/'tasks.md').write_text(base.replace(needle,'`'+command+'`'));argv=[str(kit/'scripts/sdd-analyze.sh'),str(spec)];cp=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True);observed='untyped AC Verify' in cp.stdout
 for ext,text in [('tasks.md',(spec/'tasks.md').read_text()),('stdout',cp.stdout),('stderr',cp.stderr)]: (out/f'case-{i:02d}.{ext}').write_text(text)
 results.append({'id':i,'group':group,'command':command,'expected_warning':expected,'observed_warning':observed,'exit':cp.returncode,'argv':argv,'cwd':str(root),'GIT_OPTIONAL_LOCKS':'0','matches':cp.returncode==0 and observed==expected})
cp=subprocess.run(['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_verification_spec_dir explicit-controls','_',str(kit/'tests/helpers.sh'),str(scratch/'typed')],cwd=root,env=env,capture_output=True,text=True);assert cp.returncode==0;typed=Path(cp.stdout.strip());cp=subprocess.run([str(kit/'scripts/sdd-analyze.sh'),str(typed)],cwd=root,env=env,capture_output=True,text=True);(out/'explicit-controls.stdout').write_text(cp.stdout);(out/'explicit-controls.stderr').write_text(cp.stderr)
assert cp.returncode==0 and 'consistent' in cp.stdout
record={'at':datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),'scratch':str(scratch),'real_file_presence':real,'public_results':results,'public_count':len(results),'omissions':sum(x['exit']==0 and x['expected_warning'] and not x['observed_warning'] for x in results),'explicit_test_assertion_static_manual_controls':{'exit':cp.returncode,'consistent':True},'copied_files_match':all(hashlib.sha256(p.read_bytes()).digest()==hashlib.sha256((root/p.relative_to(kit)).read_bytes()).digest() for p in kit.rglob('*') if p.is_file()),'untrusted_verify_data_executed':False,'shell_commands_cwd':str(root),'env':{'GIT_OPTIONAL_LOCKS':'0'}}
with (out/'results.json').open('x') as f:json.dump(record,f,indent=2);f.write('\n')
print(json.dumps({'scratch':str(scratch),'public_count':len(results),'omissions':record['omissions'],'real_file_presence':real,'explicit_controls':record['explicit_test_assertion_static_manual_controls'],'copied_files_match':record['copied_files_match']},indent=2))
