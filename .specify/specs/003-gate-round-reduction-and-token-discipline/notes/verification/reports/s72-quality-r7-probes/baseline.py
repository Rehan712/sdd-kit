from pathlib import Path
import os, stat, hashlib, json, time, datetime
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
r=root/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
owned=r/'s72-quality-r7-probes'
report=r/'s72-o034-quality-review-r7.md'
if os.path.lexists(owned) or os.path.lexists(report):
 raise SystemExit('Refusing to overwrite owned path')
def entry(p):
 s=p.lstat()
 q={'mode':stat.S_IMODE(s.st_mode),'mtimeNs':s.st_mtime_ns}
 if stat.S_ISLNK(s.st_mode):
  q.update(kind='symlink',target=os.readlink(p))
 elif stat.S_ISREG(s.st_mode):
  h=hashlib.sha256()
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
  q.update(kind='file',bytes=s.st_size,sha256=h.hexdigest())
 elif stat.S_ISDIR(s.st_mode):q['kind']='dir'
 else:q.update(kind='other',type=stat.S_IFMT(s.st_mode))
 return q
gitfile=(root/'.git').read_text().strip()
gitdir=(root/gitfile.split(': ',1)[1]).resolve()
common=(gitdir/(gitdir/'commondir').read_text().strip()).resolve() if (gitdir/'commondir').exists() else gitdir
def tree(base):
 out={'.':entry(base)}
 def rec(d):
  for c in sorted(d.iterdir()):
   rel=c.relative_to(base).as_posix()
   v=entry(c);out[rel]=v
   if v['kind']=='dir':rec(c)
 rec(base)
 return out
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
snapshot={'at':started,'cwd':str(root),'nonsecretEnv':{'GIT_OPTIONAL_LOCKS':os.environ.get('GIT_OPTIONAL_LOCKS')},'worktreeRoot':str(root),'gitCommonRoot':str(common),'gitWorktreeRoot':str(gitdir),'worktree':tree(root),'gitCommon':tree(common)}
owned.mkdir(mode=0o700)
with (owned/'protection-before.json').open('x') as f:json.dump(snapshot,f,sort_keys=True,indent=2);f.write('\n')
print(json.dumps({'at':started,'worktreeEntries':len(snapshot['worktree']),'gitEntries':len(snapshot['gitCommon']),'gitdir':str(gitdir),'gitCommon':str(common),'snapshotSHA256':hashlib.sha256((owned/'protection-before.json').read_bytes()).hexdigest(),'owned':str(owned)}))
