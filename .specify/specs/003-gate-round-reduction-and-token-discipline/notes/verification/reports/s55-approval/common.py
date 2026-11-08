import os, pathlib, hashlib, stat, subprocess, json, datetime, re, time
P=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert pathlib.Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=pathlib.Path('.specify/specs/003-gate-round-reduction-and-token-discipline'); V=S/'notes/verification'; R=V/'reports'; A=R/'s55-approval'; W=R/'s55-t029-worker'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(b): return hashlib.sha256(b).hexdigest()
def save(p,v):
 with pathlib.Path(p).open('x') as f: json.dump(v,f,indent=2,sort_keys=True);f.write('\n')
def run(argv,**kwargs): return subprocess.run(argv,cwd=P,env=ENV,**kwargs)
def git(*args): return run(['git',*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout
def info(p):
 p=pathlib.Path(p);st=p.lstat();v={'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns,'size':st.st_size}
 if p.is_symlink(): v.update(type='symlink',target=os.readlink(p),sha256=sha(os.fsencode(os.readlink(p))))
 elif p.is_file():
  h=hashlib.sha256()
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(1048576),b''):h.update(chunk)
  v.update(type='file',sha256=h.hexdigest())
 else:v['type']='other'
 return v
def inventory():
 out={}
 for root,dirs,files in os.walk('.',followlinks=False):
  dirs.sort();files.sort()
  for n in list(dirs):
   f=pathlib.Path(root)/n
   if f==pathlib.Path('.git') or f in [A,W]:dirs.remove(n)
   elif f.is_symlink():out[str(f)]=info(f);dirs.remove(n)
  for n in files:
   f=pathlib.Path(root)/n;out[str(f)]=info(f)
 return out
def external():
 gd=pathlib.Path(git('rev-parse','--absolute-git-dir').decode().strip());cd=pathlib.Path(git('rev-parse','--git-common-dir').decode().strip());cd=cd if cd.is_absolute() else P/cd
 branch=git('symbolic-ref','HEAD').decode().strip()
 files=[gd/'HEAD',gd/'index',gd/'logs/HEAD',cd/branch,cd/'logs'/branch,cd/'packed-refs']
 return {'HEAD':git('rev-parse','HEAD').decode().strip(),'branch':branch,'files':{str(f):info(f) if f.exists() else None for f in files},'refs':git('for-each-ref','--format=%(refname) %(objectname)').decode()}
def pending():
 found=[]
 for base in [V,S/'notes/captures']:
  for f in base.iterdir():
   if f.name=='lock' or f.name=='sequence.tmp' or f.name.startswith(('.capture.','bindings.','return.','.accept.','.floor.','.round.')):found.append(str(f))
 for gate in ['opponent','reality-check']:
  for f in (V/'rounds'/gate).glob('ROUND-*'):
   if f.is_dir() and not (f/'COMPLETE').exists():found.append(str(f))
 return found
def processes():
 raw=run(['ps','-axo','pid=,ppid=,stat=,comm='],stdout=subprocess.PIPE,check=True).stdout
 rows=[]
 for line in raw.decode().splitlines():
  q=line.strip().split(None,3)
  if len(q)==4: rows.append((int(q[0]),int(q[1]),q[2],q[3]))
 ancestors={os.getpid()};parent=os.getppid();parents={a:b for a,b,_,_ in rows}
 while parent and parent not in ancestors:ancestors.add(parent);parent=parents.get(parent,0)
 found=[]
 for pid,ppid,state,comm in rows:
  if pid in ancestors or pathlib.Path(comm).name not in ['bash','zsh','sh','python','python3']:continue
  out=run(['ps','-p',str(pid),'-o','args='],stdout=subprocess.PIPE,stderr=subprocess.PIPE).stdout.decode().strip()
  if re.search(r'(?:spec-(?:run|gate|task|ci)\.sh|tests/(?:run|test-[^ ]+|shellcheck)\.sh|s(?:48|50|52|55)[^ ]*\.py)',out):found.append({'pid':pid,'ppid':ppid,'state':state,'argv':out})
 return {'observedAt':now(),'processCount':len(rows),'processListingSha256':sha(raw),'survivingOperations':found,'rawListingPolicy':'PID, parent, state and executable only; full argv retained only for matching operations, excluding this command and ancestors.'}
def nulmeta(p):
 q=p.read_bytes().split(b'\0');assert q[-1]==b'' and len(q)%2==1;q=q[:-1];assert len(q[::2])==len(set(q[::2]));return {k.decode():v.decode() for k,v in zip(q[::2],q[1::2])}
def checked(argv,stem,input=None):
 start=now();t=time.monotonic();r=run(argv,input=input,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 (stem.with_suffix('.stdout')).write_bytes(r.stdout);(stem.with_suffix('.stderr')).write_bytes(r.stderr)
 rec={'argv':argv,'cwd':str(P),'GIT_OPTIONAL_LOCKS':'0','started':start,'ended':now(),'seconds':time.monotonic()-t,'exit':r.returncode,'stdoutSha256':sha(r.stdout),'stderrSha256':sha(r.stderr)};save(stem.with_suffix('.json'),rec);return r
