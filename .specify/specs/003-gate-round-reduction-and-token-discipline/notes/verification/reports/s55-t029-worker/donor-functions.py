import os, stat, json, hashlib, subprocess, datetime, re
from pathlib import Path

cwd=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==cwd and os.environ['GIT_OPTIONAL_LOCKS']=='0'
s=Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
own=s/'notes/verification/reports/s55-t029-worker'
approval=s/'notes/verification/reports/s55-approval'
sequence_before=int((own/'sequence-before.txt').read_text())
expected=json.loads((approval/'freshness-result.json').read_text())['actualCurrentSource']

checks={}
result={'task':'T029','status':'failed','checks':checks,'scope':'Single no-tick capture; no acceptance, task/source/STATUS edits, extra suites, CI, floor or gate operations.'}
def sha(b): return hashlib.sha256(b).hexdigest()
def save(n,o): (own/n).write_text(json.dumps(o,indent=2,sort_keys=True)+'\n')
def check(k,v): checks[k]=bool(v)
def git(*args): return subprocess.check_output(['git',*args],cwd=cwd).strip()
def info(p):
 st=p.lstat(); d={'mode':oct(stat.S_IMODE(st.st_mode)),'mtime_ns':st.st_mtime_ns,'size':st.st_size}
 if p.is_symlink(): d.update(type='symlink',target=os.readlink(p),sha256=sha(os.fsencode(os.readlink(p))))
 elif p.is_file():
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''): h.update(b)
  d.update(type='file',sha256=h.hexdigest())
 else: d['type']='other'
 return d
def inventory():
 out={}
 for root,dirs,files in os.walk('.',followlinks=False):
  dirs.sort();files.sort()
  if root=='.' and '.git' in dirs: dirs.remove('.git')
  for n in list(dirs):
   p=Path(root)/n
   if p.is_symlink(): out[str(p)]=info(p);dirs.remove(n)
   elif p in [own,approval]: dirs.remove(n)
  for n in files:
   p=Path(root)/n;out[str(p)]=info(p)
 return out
def statuses(data):
 records=data.split(b'\0');result=[];i=0
 while i<len(records):
  b=records[i];i+=1
  if not b: continue
  record=[b]
  if b[:1] in [b'R',b'C'] or b[1:2] in [b'R',b'C']:
   record.append(records[i]);i+=1
  result.append(tuple(record))
 return result