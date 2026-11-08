from pathlib import Path
import os,json,hashlib,subprocess,re,time,datetime
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
OWN=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s72-quality-r7-probes'
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(data if isinstance(data,bytes) else data.encode())
helpers=(ROOT/'tests/helpers.sh').read_text()
body=helpers.split('make_verification_spec_dir() {',1)[1].split('\n}\n',1)[0]
templates=dict(re.findall(r'cat > "\$spec_dir/([^"]+)" <<\'EOF\'\n(.*?)\nEOF',body,re.S))
assert set(templates)=={'spec.md','plan.md','STATUS.md','tasks.md'}
project=OWN/'fixtures/four-explicit-kinds'
spec=project/'.specify/specs/003-verification-fixture'
for filename,text in templates.items():save(spec/filename,text+'\n')
save(project/'.specify/stack.yml',(OWN/'fixtures/case-001/.specify/stack.yml').read_bytes())
for name in ['opponent','reality-check']:save(project/('agents/'+name+'.agent.md'),'Reviewer path metadata only; never executed.\n')
env=os.environ.copy()
for key in ['BASH_ENV','ENV','CDPATH']:env.pop(key,None)
env.update(GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(OWN/'temporary'))
argv=['/bin/bash','--norc',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic()
p=subprocess.run(argv,cwd=str(ROOT),env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=30)
meta={'argv':argv,'cwd':str(ROOT),'nonsecretEnv':{k:env[k] for k in ['GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR','PATH']},'envUnset':['BASH_ENV','ENV','CDPATH'],'started':start,'elapsedSeconds':time.monotonic()-t,'exit':p.returncode,'stdoutSHA256':sha(p.stdout),'stderrSHA256':sha(p.stderr)}
save(OWN/'four-explicit-kinds/stdout.txt',p.stdout);save(OWN/'four-explicit-kinds/stderr.txt',p.stderr)
meta['kinds']=sorted(set(re.findall(r'\*Verify kind:\* ([a-z]+)',templates['tasks.md'])))
meta['passed']=p.returncode==0 and not p.stderr and b'consistent' in p.stdout and b'untyped AC Verify' not in p.stdout and meta['kinds']==['assertion','manual','static','test']
meta['inputFiles']={str(x.relative_to(project)):sha(x.read_bytes()) for x in project.rglob('*') if x.is_file()}
meta['priorHelperFailure']='identity-and-kinds.py exited 1 after its successful vf_snapshot because a Markdown heading truncated the fixture extraction before any four-kind input or analyzer call; original script and exact driver output retained.'
save(OWN/'four-explicit-kinds/result.json',json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta))
raise SystemExit(0 if meta['passed'] else 1)
