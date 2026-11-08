from pathlib import Path
import os,stat,hashlib,json,datetime,collections
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
R=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
OWN=R/'s72-quality-r7-probes'
REPORT=R/'s72-o034-quality-review-r7.md'
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
assert not os.path.lexists(REPORT), 'Refusing to overwrite report'
before=json.loads((OWN/'protection-before.json').read_text())
def entry(p):
 s=p.lstat();q={'mode':stat.S_IMODE(s.st_mode),'mtimeNs':s.st_mtime_ns}
 if stat.S_ISLNK(s.st_mode):q.update(kind='symlink',target=os.readlink(p))
 elif stat.S_ISREG(s.st_mode):
  h=hashlib.sha256()
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
  q.update(kind='file',bytes=s.st_size,sha256=h.hexdigest())
 elif stat.S_ISDIR(s.st_mode):q['kind']='dir'
 else:q.update(kind='other',type=stat.S_IFMT(s.st_mode))
 return q
def tree(base,skip=None):
 out={'.':entry(base)}
 def rec(d):
  for p in sorted(d.iterdir()):
   if skip is not None and p==skip:continue
   rel=p.relative_to(base).as_posix();v=entry(p);out[rel]=v
   if v['kind']=='dir':rec(p)
 rec(base);return out
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
after={'at':started,'cwd':str(ROOT),'nonsecretEnv':{'GIT_OPTIONAL_LOCKS':os.environ.get('GIT_OPTIONAL_LOCKS')},'worktree':tree(ROOT,OWN),'gitCommon':tree(Path(before['gitCommonRoot']))}
def compare(b,a):
 return {'changed':{k:{'before':b[k],'after':a.get(k)} for k in b if a.get(k)!=b[k]},'added':{k:a[k] for k in a if k not in b}}
wd=compare(before['worktree'],after['worktree']);gd=compare(before['gitCommon'],after['gitCommon'])
reports_rel=R.relative_to(ROOT).as_posix()
expected_dir={}
unknown_work={}
for path,v in wd['changed'].items():
 b=v['before'];a=v['after']
 if path==reports_rel and a and b['kind']==a['kind']=='dir' and b['mode']==a['mode'] and set(b)==set(a):
  expected_dir[path]=v
 else:unknown_work[path]=v
result={'started':started,'ended':datetime.datetime.now(datetime.timezone.utc).isoformat(),'originalWorktreeEntries':len(before['worktree']),'originalWorktreeKinds':dict(collections.Counter(v['kind'] for v in before['worktree'].values())),'originalGitEntries':len(before['gitCommon']),'originalFilesAndSymlinksPreserved':not any(v['before']['kind'] in ['file','symlink'] for v in wd['changed'].values()),'unknownOriginalWorktreeChanges':unknown_work,'unknownNewWorktreePaths':wd['added'],'authorizedReportsDirectoryMtimeChange':expected_dir,'gitChanges':gd,'strictCurrentOriginalProtection':not unknown_work and not wd['added'] and not gd['changed'] and not gd['added'],'historicalStrictPreservation':False,'newAllowedPaths':[str(OWN.relative_to(ROOT))+'/',str(REPORT.relative_to(ROOT))],'reportPresentAtScan':os.path.lexists(REPORT),'snapshotQualification':'Original bytes, modes and nanosecond mtimes are checked. The reports directory mtime changes necessarily when the owned directory/report are added; it is recorded, not restored. No other directory or Git difference is exempted.'}
for name,obj in [('protection-after.json',after),('preservation-result.json',result)]:
 with (OWN/name).open('x') as f:json.dump(obj,f,indent=2,sort_keys=True);f.write('\n')
print(json.dumps(result))
