from pathlib import Path
import os,json,re,subprocess,hashlib,datetime,shutil
root=Path.cwd();s=root/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';out=r/'s50-o034-qualified-tools-verification';base=json.loads((out/'inventory.before.json').read_text());scratch=Path(base['scratch']);env=dict(os.environ,GIT_OPTIONAL_LOCKS='0',LC_ALL='C');env.pop('SHELLCHECK_OPTS',None)
h=lambda b:hashlib.sha256(b).hexdigest()
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
records=[]
def run(label,argv,data=None,timeout=60):
 start=now()
 try:
  cp=subprocess.run(argv,cwd=root,env=env,input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout);rc=cp.returncode;stdout=cp.stdout;stderr=cp.stderr
 except subprocess.TimeoutExpired as e:rc='TIMEOUT';stdout=e.stdout or b'';stderr=e.stderr or b''
 (out/(label+'.stdout')).write_bytes(stdout);(out/(label+'.stderr')).write_bytes(stderr)
 rec={'label':label,'argv':list(map(str,argv)),'cwd':str(root),'env_overrides':{'GIT_OPTIONAL_LOCKS':'0','LC_ALL':'C','SHELLCHECK_OPTS':None},'start':start,'end':now(),'exit':rc,'stdin_sha256':h(data) if data is not None else None,'stdout_sha256':h(stdout),'stderr_sha256':h(stderr)};records.append(rec)
 (out/'command-records.json').write_text(json.dumps(records,indent=2)+'\n');return rc,stdout,stderr
for label,argv in [('bash32-version',['/bin/bash','--version']),('bash32-syntax',['/bin/bash','-n','scripts/sdd-analyze.sh','tests/test-sdd-analyze.sh']),('shellcheck',['/opt/homebrew/bin/shellcheck','--norc','-S','warning','-x','scripts/sdd-analyze.sh','tests/test-sdd-analyze.sh'])]:
 rc,_,_=run(label,argv);assert rc==0,label
(out/'static-checks.json').write_text(json.dumps(records,indent=2)+'\n')
current=(root/'tests/test-sdd-analyze.sh').read_text();old=(r/'s49-o034-qualified-tools-fix/before/tests/test-sdd-analyze.sh').read_text()
def extract(text,label):
 begin=text.index('  local weak_redirect_cases=()');end=text.index('  # AC-004/O-034:',begin);builders=text[begin:end]
 loops=[];pos=end
 for group in ['weak','runner']:
  a=text.index('  for fixture in \\\n',pos);b=text.index('; do',a);decl=text[a:b+4];loops.append(decl);pos=b+4
 script='set -eu\nprintf "BASH_VERSION=%s\\n" "$BASH_VERSION" >&2\nif [[ ${1:-default} != default ]]; then shopt -s patsub_replacement; [[ $1 != off ]] || shopt -u patsub_replacement; fi\nshopt -p patsub_replacement >&2 || :\nfixture_probe() {\n'+builders
 script+='for fixture in "${weak_redirect_cases[@]}"; do printf "generated_weak\\0%s\\0" "$fixture"; done\nfor fixture in "${runner_redirect_cases[@]}"; do printf "generated_runner\\0%s\\0" "$fixture"; done\n'
 if 'weak_qualified_cases' in builders:script+='for fixture in "${weak_qualified_cases[@]}"; do printf "qualified_weak\\0%s\\0" "$fixture"; done\nfor fixture in "${runner_qualified_cases[@]}"; do printf "qualified_runner\\0%s\\0" "$fixture"; done\n'
 for group,decl in zip(['weak','runner'],loops):script+=decl+' printf "'+group+'\\0%s\\0" "$fixture"; done\n'
 script+='}\nfixture_probe\n';(out/(label+'-fixture-extracted.sh')).write_text(script)
 return builders,loops,script.encode()
oldbuild,oldloops,oldscript=extract(old,'before');newbuild,newloops,newscript=extract(current,'current')
assert newbuild.startswith(oldbuild)
for i,group in enumerate(['weak','runner']):assert newloops[i].replace(' "${'+group+'_qualified_cases[@]}"','')==oldloops[i]
def arrays(raw):
 a=raw.split(b'\0');assert a.pop()==b'' and len(a)%2==0;d={}
 for key,value in zip(a[::2],a[1::2]):d.setdefault(key.decode(),[]).append(value.decode())
 return d
for label,script in [('before',oldscript),('current',newscript)]:
 rc,raw,_=run(label+'-bash32-fixture',['/bin/bash','-s','--','default'],script);assert rc==0;d=arrays(raw);(out/(label+'-arrays.json')).write_text(json.dumps(d,indent=2)+'\n')
a=json.loads((out/'before-arrays.json').read_text());b=json.loads((out/'current-arrays.json').read_text())
for group in ['generated_weak','generated_runner']:assert a[group]==b[group]
for group in ['weak','runner']:assert b[group][:len(a[group])]==a[group]
assert not any('REDIRECT' in v for values in b.values() for v in values)
assert './tests/npm&>out.txt run typecheck' in b['qualified_weak'];assert './tests/cargo&>out.txt test --test build' in b['qualified_runner']
fixture={'source_sha256':h(current.encode()),'before_source_sha256':h(old.encode()),'counts':{k:len(v) for k,v in b.items()},'prior_counts':{k:len(v) for k,v in a.items()},'old_builders_byte_identical_prefix':True,'old_declarations_byte_identical_after_removing_only_new_array_expansion':True,'all_prior_array_entries_identical':True,'unexpanded_REDIRECT_absent':True,'literal_ampersand_examples_passed':True,'modern_runtime':'NOT CHECKED'}
# Existing frozen local image only; no pull, network, writable filesystem or mounted project.
image='sha256:a81de950abb8b5d961ed8c1dcd345450fab8cda00ea3c11e7ec24a4ed4bb82ce';docker='/usr/local/bin/docker'
if Path(docker).is_file():
 rc,_,_=run('docker-info',[docker,'info','--format','{{json .ServerVersion}}'],timeout=15)
 if rc==0:
  rc,_,_=run('docker-image-inspect',[docker,'image','inspect',image,'--format','{{.Id}}'],timeout=15)
  if rc==0:
   results=[]
   for option in ['on','off']:
    argv=[docker,'run','--pull=never','--rm','-i','--network=none','--read-only','--cap-drop=ALL','--security-opt=no-new-privileges','--entrypoint=/bin/bash',image,'-s','--',option]
    rc,raw,_=run('current-bash52-'+option,argv,newscript,timeout=30);assert rc==0;assert arrays(raw)==b;results.append({'patsub_replacement':option,'arrays_identical_to_bash32':True})
   fixture['modern_runtime']={'image':image,'results':results}
(out/'fixture-selfcheck.json').write_text(json.dumps(fixture,indent=2)+'\n')
# Retain the genuine old-source RED; do not execute its source or full matrix.
paths=['s47-opponent26-max-probes/public-classifier/results.json','s47-opponent26-max-probes/qualified-executable/results.json']
reds=[];proof=[]
for rel in paths:
 p=r/rel;d=json.loads(p.read_text());cases=d.get('results',d.get('public_results'));fail=[x for x in cases if x['exit']==0 and x['expected_warning'] and not x['observed_warning']];reds+=fail;proof.append({'path':str(p.relative_to(root)),'sha256':h(p.read_bytes()),'omissions':len(fail)})
commands=list(dict.fromkeys(x['command'] for x in reds));summary=json.loads((r/'s47-opponent26-max-probes/attack-summary.json').read_text());assert sorted(commands)==summary['unique_omission_commands']
(out/'retained-red-baseline.json').write_text(json.dumps({'proofs':proof,'observation_count':len(reds),'distinct_command_count':len(commands),'commands':commands,'historical_source':'f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0','old_source_not_rerun':True,'original_scripts_sha256':{name:h((r/'s47-opponent26-max-probes'/name).read_bytes()) for name in ['focused-classifier-probes.py','qualified-executable-probe.py']}},indent=2)+'\n')
kit=scratch/'green-kit';kit.mkdir();shutil.copytree(root/'scripts',kit/'scripts');(kit/'tests').mkdir();shutil.copy2(root/'tests/helpers.sh',kit/'tests/helpers.sh')
setup=['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_spec_dir','_',str(kit/'tests/helpers.sh'),str(scratch/'green-fixture')]
rc,stdout,_=run('focused-fixture-setup',setup);assert rc==0;spec=Path(stdout.decode().strip());original=(spec/'tasks.md').read_text();needle='`node --test test/thing.test.js`';assert original.count(needle)==1
cases=[{'command':c,'expected_warning':True,'group':'retained-op26-red'} for c in commands]
for command,warn in [('tsc --noEmit tests/unit.ts',True),('./tools/npm run build',True),('./tests/grep AC-001 README.md',True),('npm 2&>out.txt test typecheck.txt',True),('./tests/npm run test -- --grep typecheck',False),('./tests/cargo test --test build',False),('./tests/bun test tests/typecheck.ts',False),('./tests/go test ./build',False),('bash tests/typecheck.sh',False),('./tests/check-build.sh',False),('node scripts/assert-content.js /usr/bin/grep AC-001 README.md',False),('./tests/npm&>out.txt run test -- --grep typecheck',False),('./tests/cargo>|out.txt test --test build',False)]:cases.append({'command':command,'expected_warning':warn,'group':'representative-controls'})
results=[]
for i,case in enumerate(cases,1):
 text=original.replace(needle,'`'+case['command']+'`');(spec/'tasks.md').write_text(text);(out/f'focused-{i:02d}.tasks.md').write_text(text)
 argv=[str(kit/'scripts/sdd-analyze.sh'),str(spec)];rc,stdout,stderr=run(f'focused-{i:02d}',argv);observed=b'untyped AC Verify' in stdout;results.append(dict(case,argv=argv,exit=rc,observed_warning=observed,passed=rc==0 and observed==case['expected_warning']))
setup=['/bin/bash','-c','. "$1"; SANDBOX="$2"; make_verification_spec_dir explicit-controls','_',str(kit/'tests/helpers.sh'),str(scratch/'green-typed')]
rc,stdout,_=run('explicit-controls-setup',setup);assert rc==0;typed=Path(stdout.decode().strip());(out/'explicit-controls.tasks.md').write_bytes((typed/'tasks.md').read_bytes());kinds=re.findall(r'\*Verify kind:\* ([^\n]+)',(typed/'tasks.md').read_text());assert kinds==['test','assertion','static','manual'],kinds
rc,stdout,_=run('explicit-controls',[str(kit/'scripts/sdd-analyze.sh'),str(typed)]);explicit=rc==0 and b'consistent' in stdout
result={'results':results,'count':len(results),'passing':sum(x['passed'] for x in results),'explicit_kinds':kinds,'explicit_kinds_passed':explicit,'task_verify_strings_executed':False,'fake_PATH_stubs':False,'copied_analyzer_sha256':h((kit/'scripts/sdd-analyze.sh').read_bytes()),'copied_scripts_all_match_current':all(p.read_bytes()==(root/p.relative_to(kit)).read_bytes() for p in kit.rglob('*') if p.is_file())}
(out/'focused-green-results.json').write_text(json.dumps(result,indent=2)+'\n');assert all(x['passed'] for x in results) and explicit
print(json.dumps({'static_checks':'PASS','fixture':fixture,'focused_count':result['count'],'focused_passing':result['passing'],'explicit_kinds':kinds,'explicit_kinds_passed':explicit},indent=2))
