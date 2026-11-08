import os,sys,json,hashlib,stat,subprocess,time,datetime,traceback
from pathlib import Path
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT
os.environ['GIT_OPTIONAL_LOCKS']='0'
S=Path('.specify/specs/003-gate-round-reduction-and-token-discipline');V=S/'notes/verification';R=V/'reports';OUT=R/'s48-op26-sealing'
BASE=json.loads((OUT/'baseline.json').read_text())
REPORT=R/'opponent-round26.md';HISTORY=S/'notes/opponent.md';LEDGER=V/'rounds/opponent/ROUND-26'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(b):return hashlib.sha256(b).hexdigest()
def info(p):
 st=p.lstat();d={'type':stat.S_IFMT(st.st_mode),'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns}
 if p.is_symlink():d['target']=os.readlink(p)
 elif p.is_file():d.update(size=st.st_size,sha256=sha(p.read_bytes()))
 return d
def save(name,data):
 with (OUT/name).open('x') as f:json.dump(data,f,indent=2);f.write('\n')
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')).decode()
RESULT={'started':now(),'runnerPid':os.getpid(),'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':'0','round':26,'gate':'opponent','reportSha256':BASE['reportSha256'],'source':'f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0','floor':'FLOOR-LxJkv3','verdict':'CHALLENGED','steps':[],'automaticRetries':0,'completionInvocations':0,'tallyInvocations':0,'historicalFullPreservationPassed':False,'formalClearance':False}
def run(name,argv):
 step={'name':name,'argv':argv,'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':'0','started':now()};t=time.monotonic()
 print(json.dumps({'starting':name,'argv':argv,'at':step['started']}),flush=True)
 with (OUT/(name+'.stdout')).open('xb') as stdout,(OUT/(name+'.stderr')).open('xb') as stderr:
  proc=subprocess.Popen(argv,cwd=ROOT,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),stdout=stdout,stderr=stderr)
  step['nativePid']=proc.pid;save(name+'-started.json',step)
  rc=proc.wait()
 step.update(exit=rc,ended=now(),elapsedSeconds=time.monotonic()-t)
 with (OUT/(name+'.rc')).open('x') as f:f.write(str(rc)+'\n')
 save(name+'-exit.json',step);RESULT['steps'].append(step)
 print(json.dumps(step),flush=True)
 if rc:raise RuntimeError(name+' native command failed; no retry: '+str(rc))
 return step

def protection(name,after=False):
 changed={};missing=[];dirmtimes={};external={}
 allowed_dirs={str(R),str(OUT)}
 if after:allowed_dirs|={str(S/'notes'),str(V),str(LEDGER)}
 for n,before in BASE['worktree'].items():
  p=ROOT/n
  if not p.exists() and not p.is_symlink():missing.append(n);continue
  current=info(p)
  if current!=before:
   if before['type']==stat.S_IFDIR and {k:v for k,v in before.items() if k!='mtime_ns'}=={k:v for k,v in current.items() if k!='mtime_ns'}:
    dirmtimes[n]={'before':before['mtime_ns'],'after':current['mtime_ns'],'authorizedKernelOrReceiptDirectory':n in allowed_dirs}
   elif after and n==str(HISTORY):pass
   else:changed[n]={'before':before,'after':current}
 for n,before in BASE['external'].items():
  p=Path(n);current=info(p) if p.exists() or p.is_symlink() else None
  if before!=current:external[n]={'before':before,'after':current}
 refs=git('for-each-ref','--format=%(refname) %(objectname)')
 def refmap(raw):return dict(line.split(' ',1) for line in raw.splitlines())
 old,new=refmap(BASE['global_refs']),refmap(refs)
 refdiff={n:{'before':old.get(n),'after':new.get(n)} for n in old.keys()|new.keys() if old.get(n)!=new.get(n)}
 additions=[];unexpected=[]
 allowed_new={str(R/'r23-state-s48-op26-returned.txt'),str(R/'r23-state-s48-op26-returned.entries'),BASE['allowedConcurrentAddition']}
 if after:allowed_new.add(str(LEDGER/'report.sha256'))
 for parent,dirs,files in os.walk(ROOT,followlinks=False):
  for n in dirs+files:
   p=Path(parent)/n;rel=str(p.relative_to(ROOT))
   if rel not in BASE['worktree']:
    additions.append(rel)
    if not (rel.startswith(str(OUT)+'/') or rel in allowed_new):unexpected.append(rel)
 strict=not(changed or missing or external or refdiff or unexpected or any(not d['authorizedKernelOrReceiptDirectory'] for d in dirmtimes.values()))
 data={'at':now(),'originalEntries':len(BASE['worktree']),'changedPreexistingFilesModesMtimes':changed,'missingPreexistingEntries':missing,'directoryMtimeDifferences':dirmtimes,'externalDifferences':external,'globalRefDifferences':refdiff,'globalRefsIdentical':not refdiff,'head':git('rev-parse','HEAD').strip(),'headIdentical':git('rev-parse','HEAD').strip()==BASE['head'],'newPaths':additions,'unexpectedAdditions':unexpected,'passed':strict,'historicalFullPreservationPassed':False,'noRefOrOSRestoration':True}
 save(name,data)
 return data

def fields(p):return p.read_text().splitlines()[1:]
try:
 assert not (OUT/'returned-started.json').exists(), 'operation already started'
 save('native-launch.json',{'at':now(),'runnerPid':os.getpid(),'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':'0'})
 run('returned',['bash',str(ROOT/R/'r23-worktree-state.sh'),'s48-op26-returned'])
 returned=(R/'r23-state-s48-op26-returned.entries').read_bytes();reserved=(R/'r23-state-s46-op26-reserved.entries').read_bytes()
 raw={'at':now(),'entriesByteIdentical':returned==reserved,'entriesSha256':sha(returned),'entryCount':len(returned.splitlines()),'stateFieldsMatch':fields(R/'r23-state-s48-op26-returned.txt')==fields(R/'r23-state-s46-op26-reserved.txt'),'returnedStateFields':fields(R/'r23-state-s48-op26-returned.txt'),'reservedStateFields':fields(R/'r23-state-s46-op26-reserved.txt')}
 save('returned-raw-proof.json',raw);RESULT['returnedRawProof']=raw
 assert raw['entriesByteIdentical'] and raw['stateFieldsMatch'] and raw['entriesSha256']=='3ca12e69830dd1f06b6b985847aafd6b54614c068e22167598b00ee835825731'
 pre=protection('protection-pre-completion.json');assert pre['passed'],'strict pre-completion protection failed'
 assert sha(REPORT.read_bytes())==BASE['reportSha256']
 assert not (LEDGER/'report.sha256').exists(),'already sealed; no duplicate completion'
 assert HISTORY.read_bytes()==(OUT/'opponent-before.md').read_bytes()
 RESULT['completionInvocations']=1
 run('complete',['bash','scripts/spec-gate.sh','round',str(S),'opponent','--complete',str(REPORT)])
 RESULT['completed']=True
 RESULT['tallyInvocations']=1
 run('tally',['bash','scripts/spec-gate.sh','tally',str(S)])
 RESULT['tallied']=True
 report=REPORT.read_bytes();before=(OUT/'opponent-before.md').read_bytes();history=HISTORY.read_bytes()
 seals={}
 for n,b in BASE['worktree'].items():
  if n.startswith(str(V/'rounds')+'/') and b['type']==stat.S_IFREG:
   p=ROOT/n;seals[n]=p.exists() and info(p)==b
 metadata=LEDGER.joinpath('meta.nul').read_bytes().split(b'\0');metadata=dict(zip((x.decode() for x in metadata[0:-1:2]),(x.decode() for x in metadata[1:-1:2])))
 latest={'round':26,'verdict':'CHALLENGED','blocking':1,'minor':1,'blockingFinding':'O-034','minorFinding':'O-032','previouslyRecordedUnassessedMinors':['O-026','O-027','O-028']}
 tally=(OUT/'tally.stdout').read_text()
 checks={'canonicalReportUnchanged':sha(report)==BASE['reportSha256'],'sealMatchesCanonicalReport':(LEDGER/'report.sha256').read_text()==BASE['reportSha256']+'\n','priorHistoryPrefixUnchanged':history.startswith(before),'onlyNewlineAndExactReportAppended':history==before+b'\n'+report,'reportBodyIdenticalNewHistoryBlock':history[len(before)+1:]==report,'priorRoundFilesUnchanged':all(seals.values()),'sourceMatches':metadata['source']==RESULT['source'],'floorMatches':metadata['floor']==RESULT['floor'],'roundMatches':metadata['round']=='26','nativeCompletionExitZero':RESULT['steps'][1]['exit']==0,'nativeTallyExitZero':RESULT['steps'][2]['exit']==0,'tallyOpponent26':'opponent rounds=26\n' in tally,'latestChallengedCounts':'**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 1\n' in report.decode()}
 verify={'at':now(),'checks':checks,'passed':all(checks.values()),'canonicalHistorySha256':sha(history),'canonicalHistoryBytes':len(history),'canonicalHistoryBeforeSha256':sha(before),'metadata':metadata,'priorRoundFiles':seals,'latestRoundFindings':latest,'tallyIsCumulativeHistory':True,'tallyStdoutSha256':sha(tally.encode())}
 save('sealing-verification.json',verify);RESULT['sealingVerification']=verify
 post=protection('protection-after.json',after=True);RESULT['protectedState']=post
 assert verify['passed'],'post-seal verification failed'
 assert post['passed'],'strict preservation failed; kernel exits remain unchanged'
 RESULT.update(exit=0,phase='challenged-report-sealed-and-tallied')
except BaseException as exc:
 RESULT.update(exit=1,error=str(exc),traceback=traceback.format_exc(),phase='stopped-without-retry')
 if not (OUT/'protection-after.json').exists():
  try:RESULT['protectedState']=protection('protection-after.json',after=RESULT.get('completed',False))
  except BaseException as obs:RESULT['protectionObserverError']=str(obs)
finally:
 RESULT['ended']=now();save('result.json',RESULT)
 print(json.dumps({'phase':RESULT['phase'],'exit':RESULT['exit'],'completed':RESULT.get('completed',False),'tallied':RESULT.get('tallied',False),'error':RESULT.get('error')}),flush=True)
 sys.exit(RESULT['exit'])
