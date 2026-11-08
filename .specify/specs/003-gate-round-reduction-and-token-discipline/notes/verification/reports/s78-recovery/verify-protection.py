import pathlib,os,subprocess,hashlib,stat,json,datetime
P=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert pathlib.Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=P/'.specify/specs/003-gate-round-reduction-and-token-discipline';R=S/'notes/verification/reports';D=R/'s78-recovery';ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def save(n,v):
 with (D/n).open('x') as f:json.dump(v,f,indent=2);f.write('\n')
def inv(base):
 r={}
 for root,dirs,files in os.walk(base,followlinks=False):
  for n in dirs+files:
   p=pathlib.Path(root)/n;s=p.lstat();v=dict(mode=stat.S_IMODE(s.st_mode),mtimeNs=s.st_mtime_ns,size=s.st_size,type='symlink' if p.is_symlink() else 'dir' if p.is_dir() else 'file')
   if v['type']!='dir':v['sha256']=hashlib.sha256(os.fsencode(os.readlink(p)) if p.is_symlink() else p.read_bytes()).hexdigest()
   r[str(p.relative_to(base))]=v
 return r
def git(*a):return subprocess.check_output(['git',*a],cwd=P,env=ENV)
assert json.loads((R/'s77-analyzer-refresh/result.json').read_text())['verified'] is True
old=json.loads((D/'baseline-worktree.json').read_text());oldgit=json.loads((D/'baseline-git.json').read_text());scope=json.loads((D/'scope.json').read_text());now=inv(P);g=inv(pathlib.Path(scope['gitCommon']))
changes={p:dict(before=b,after=now.get(p)) for p,b in old.items() if now.get(p)!=b};gc={p:dict(before=b,after=g.get(p)) for p,b in oldgit.items() if g.get(p)!=b}
allowedfiles={str((S/p).relative_to(P)) for p in ['tasks.md','notes/evidence.md','notes/verification/sequence']}
unknownfiles={p:c for p,c in changes.items() if c['before']['type']!='dir' and p not in allowedfiles}
rawrefs=git('for-each-ref','--format=%(refname) %(objectname)');(D/'refs-after.raw').write_bytes(rawrefs)
head=git('rev-parse','HEAD');branch=git('branch','--show-current')
checks=dict(rawRefsUnchanged=rawrefs==(D/'refs-before.raw').read_bytes(),HEADUnchanged=head==(D/'HEAD-before.raw').read_bytes(),branchUnchanged=branch==(D/'branch-before.raw').read_bytes(),originalS76S77FilesPreserved=not [p for p in changes if p.startswith(str((R/'s76-t029-control').relative_to(P))+'/') or p.startswith(str((R/'s77-analyzer-refresh').relative_to(P))+'/')],originalFilesOutsideNativeMutationsPreserved=not unknownfiles,tasksMatchExactT029AcceptedSnapshot=(S/'tasks.md').read_bytes()==(R/'s76-t029-control/tasks.after').read_bytes(),noVerificationLock=not (S/'notes/verification/lock').exists(),noCaptureStage=not list((S/'notes/captures').glob('.capture.*')),noOP28Reservation=not (S/'notes/verification/rounds/opponent/ROUND-28').exists())
result=dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),checks=checks,changedOriginalWorktreeEntries=changes,unknownOriginalFiles=unknownfiles,newWorktreePaths=sorted(set(now)-set(old)),gitChangesUnknownActor=gc,gitNewPathsUnknownActor=sorted(set(g)-set(oldgit)),historicalStrictPreservation=False,strictCurrentAllEntriesPreserved=not changes and not gc and set(g)==set(oldgit),noUnknownChangesRestored=True,noUnknownChangesAttributed=True,T029AcceptedOnce=True,analyzerAccepted=False,noFormalClearance=True,controlInventoryNote='Its unexpected control-wrapper.stdout difference is the owned new s78 native log growing during execution; kept literal result false, did not rewrite it.')
save('protection-after.json',result)
print(json.dumps(dict(checks=checks,originalWorktreeChanged=len(changes),originalFilesUnknown=len(unknownfiles),gitChanged=len(gc),gitNew=len(set(g)-set(oldgit))),indent=2))
assert all(checks.values()),checks
