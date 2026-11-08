from pathlib import Path
import os,json,hashlib,subprocess,datetime,re,time
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline'
OWN=S/'notes/verification/reports/s72-quality-r7-probes'
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(data if isinstance(data,bytes) else data.encode())
env=os.environ.copy()
for key in ['BASH_ENV','ENV','CDPATH']:env.pop(key,None)
env.update(GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(OWN/'temporary'))
def run(name,argv):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat()
 t=time.monotonic()
 p=subprocess.run(argv,cwd=str(ROOT),env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=90)
 meta={'argv':argv,'cwd':str(ROOT),'nonsecretEnv':{k:env[k] for k in ['GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR','PATH']},'envUnset':['BASH_ENV','ENV','CDPATH'],'started':start,'elapsedSeconds':time.monotonic()-t,'exit':p.returncode,'stdoutSHA256':sha(p.stdout),'stderrSHA256':sha(p.stderr)}
 save(OWN/name/'stdout.txt',p.stdout);save(OWN/name/'stderr.txt',p.stderr)
 return p,meta
manifest=OWN/'identity/inputs.nul'
argv=['/bin/bash','--norc','-c','. "$1"; vf_snapshot "$2" "$3" "$3" "$4"','quality-r7',str(ROOT/'scripts/verification-lib.sh'),str(S),str(ROOT),str(manifest)]
p,meta=run('identity',argv)
source=sha(manifest.read_bytes()) if manifest.exists() else None
meta.update(source=source,sourceMatchesExpected=source=='62cbf525b0caac98f27729393f6e7203ec6ac1cd34c164b3734b7c10a98be23f',byteIdenticalToAccepted=(manifest.read_bytes()==(S/'notes/captures/CAP-866-eXyQTW/inputs.nul').read_bytes()) if manifest.exists() else False)
meta['passed']=p.returncode==0 and not p.stderr and p.stdout==(source+'\n').encode() and meta['sourceMatchesExpected'] and meta['byteIdenticalToAccepted']
save(OWN/'identity/result.json',json.dumps(meta,indent=2)+'\n')
print(json.dumps({'identity':meta}))
helpers=(ROOT/'tests/helpers.sh').read_text()
body=helpers.split('make_verification_spec_dir() {',1)[1].split('# ',1)[0] if False else helpers.split('make_verification_spec_dir() {',1)[1]
body=body.split('\n# ',1)[0]
templates=dict(re.findall(r'cat > "\$spec_dir/([^"]+)" <<\'EOF\'\n(.*?)\nEOF',body,re.S))
assert set(templates)=={'spec.md','plan.md','STATUS.md','tasks.md'}
project=OWN/'fixtures/four-explicit-kinds'
spec=project/'.specify/specs/003-verification-fixture'
for filename,text in templates.items():save(spec/filename,text+'\n')
save(project/'.specify/stack.yml',(OWN/'fixtures/case-001/.specify/stack.yml').read_bytes())
for name in ['opponent','reality-check']:save(project/('agents/'+name+'.agent.md'),'Reviewer path metadata only; never executed.\n')
argv=['/bin/bash','--norc',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
p,kindmeta=run('four-explicit-kinds',argv)
kindmeta['kinds']=sorted(set(re.findall(r'\*Verify kind:\* ([a-z]+)',templates['tasks.md'])))
kindmeta['passed']=p.returncode==0 and not p.stderr and b'consistent' in p.stdout and b'untyped AC Verify' not in p.stdout and kindmeta['kinds']==['assertion','manual','static','test']
kindmeta['inputFiles']={str(x.relative_to(project)):sha(x.read_bytes()) for x in project.rglob('*') if x.is_file()}
save(OWN/'four-explicit-kinds/result.json',json.dumps(kindmeta,indent=2)+'\n')
print(json.dumps({'explicitKinds':kindmeta}))
raise SystemExit(0 if meta['passed'] and kindmeta['passed'] else 1)
