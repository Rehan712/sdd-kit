from pathlib import Path
import json,os,sys,stat,hashlib,subprocess,datetime
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==ROOT and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
OUT=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s67-opponent27-max-probes';REPORT=OUT.parent/'opponent-round27.md'
BASE=json.loads((OUT/'protection-before.json').read_text());dest=OUT/('protection-'+sys.argv[1]+'.json');assert not dest.exists()
def capture(p):
 st=p.lstat();d={'path':str(p),'mode':stat.S_IMODE(st.st_mode),'type':stat.S_IFMT(st.st_mode),'mtimeNs':st.st_mtime_ns,'size':st.st_size}
 if stat.S_ISLNK(st.st_mode):d['target']=os.readlink(p)
 elif stat.S_ISREG(st.st_mode):d['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
 return d
changes=[]
for before in BASE['originals']:
 p=Path(before['path'])
 try:after=capture(p)
 except Exception as exc:after={'readError':str(exc)}
 if before!=after:changes.append({'before':before,'after':after})
old={r['path'] for r in BASE['originals']};add=[]
for base in BASE['roots']:
 for parent,dirs,files in os.walk(base,followlinks=False):
  for name in list(dirs):
   p=Path(parent)/name
   if p.is_symlink():
    if str(p) not in old:add.append(str(p))
    dirs.remove(name)
  for name in files:
   p=Path(parent)/name
   if str(p) not in old:add.append(str(p))
owned=[p for p in add if p.startswith(str(OUT)+'/') or p==str(REPORT)];unexpected=[p for p in add if p not in owned]
r=subprocess.run(['git','show-ref'],cwd=str(ROOT),env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),stdout=subprocess.PIPE,stderr=subprocess.PIPE)
refsBefore=next(c['stdout'] for c in json.loads((OUT/'git-before.json').read_text()) if c['argv']==['git','show-ref'])
refsAfter=r.stdout.decode();oldrefs=set(refsBefore.splitlines());newrefs=set(refsAfter.splitlines())
res={'at':datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),'originals':len(BASE['originals']),'originalWorktreeEntries':sum(p['path'].startswith(str(ROOT)+'/') for p in BASE['originals']),'changedOriginalCount':len(changes),'changedOriginals':changes,'ownedNewFiles':len(owned),'unexpectedAdditions':unexpected,'refsArgv':['git','show-ref'],'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'},'refsExit':r.returncode,'refsStderr':r.stderr.decode(),'refsBeforeSha256':hashlib.sha256(refsBefore.encode()).hexdigest(),'refsAfterSha256':hashlib.sha256(r.stdout).hexdigest(),'removedOrChangedRawRefs':sorted(oldrefs-newrefs),'addedOrChangedRawRefs':sorted(newrefs-oldrefs),'strictPreservation':not changes and not unexpected and r.returncode==0 and refsBefore==refsAfter,'restorationOrAllowlistingPerformed':False,'historicalStrictPreservation':False}
with dest.open('x') as f:f.write(json.dumps(res,indent=2)+'\n')
print(json.dumps({k:v for k,v in res.items() if k!='changedOriginals'},indent=2));print('changedPaths',[x['before']['path'] for x in changes]);sys.exit(0 if res['strictPreservation'] else 1)
