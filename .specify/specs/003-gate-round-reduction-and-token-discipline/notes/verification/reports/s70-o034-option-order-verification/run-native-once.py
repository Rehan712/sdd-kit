import os,json,subprocess,datetime,hashlib,stat,shutil
from pathlib import Path
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==root
s=root/'.specify/specs/003-gate-round-reduction-and-token-discipline';o=s/'notes/verification/reports/s70-o034-option-order-verification'
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
assert json.load(open(o/'kernel-before-result.json'))['exit']==0
assert (o/'task-command-before.txt').read_bytes()==b'bash tests/test-sdd-analyze.sh\n'
assert (s/'notes/verification/sequence').read_bytes()==b'865\n'
assert not (s/'notes/verification/lock').exists()
for rel,b in json.load(open(o/'protected-core-before.json')).items():
 p=root/rel;st=p.stat();assert hashlib.sha256(p.read_bytes()).hexdigest()==b['sha256'] and stat.S_IMODE(st.st_mode)==b['mode'] and st.st_mtime_ns==b['mtimeNs'],rel
ps=subprocess.run(['ps','-axo','pid,ppid,state,command'],cwd=root,env=env,capture_output=True,text=True)
assert ps.returncode==0
active=[line for line in ps.stdout.splitlines() if any(x in line for x in ['bash scripts/spec-run.sh','bash scripts/spec-gate.sh','bash scripts/spec-floor.sh'])]
assert not active,active
argv=['bash','scripts/spec-run.sh','.specify/specs/003-gate-round-reduction-and-token-discipline','T031a5o1','--from-task','--no-tick','--summary']
record={'argv':argv,'cwd':str(root),'started':datetime.datetime.now(datetime.timezone.utc).isoformat(),'env':{k:env[k] for k in ['GIT_OPTIONAL_LOCKS','PATH','LANG','LC_ALL','LC_CTYPE','TZ'] if k in env},'bashResolved':shutil.which('bash',path=env.get('PATH')),'attempt':1,'automaticRetries':0}
# Exclusive durable invocation marker is created before launching exactly once.
with (o/'native-invocation.json').open('x') as f: json.dump(record,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
with (o/'native.stdout').open('xb') as out,(o/'native.stderr').open('xb') as err:
 p=subprocess.Popen(argv,cwd=root,env=env,stdout=out,stderr=err)
 record['pid']=p.pid
 with (o/'native-started.json').open('x') as f: json.dump(record,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
 print(json.dumps({'nativePID':p.pid,'started':record['started'],'argv':argv}),flush=True)
 rc=p.wait()
 record.update(ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),nativeExit=rc,stdoutSHA256=hashlib.sha256((o/'native.stdout').read_bytes()).hexdigest(),stderrSHA256=hashlib.sha256((o/'native.stderr').read_bytes()).hexdigest(),stdoutBytes=(o/'native.stdout').stat().st_size,stderrBytes=(o/'native.stderr').stat().st_size)
 with (o/'native-result.json').open('x') as f: json.dump(record,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
 print(json.dumps(record),flush=True)
 print((o/'native.stdout').read_text(),end='',flush=True)
 print((o/'native.stderr').read_text(),end='',flush=True)
