import os,sys,json,hashlib,stat,subprocess,time,datetime,traceback
from pathlib import Path
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT
os.environ['GIT_OPTIONAL_LOCKS']='0'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
S=Path('.specify/specs/003-gate-round-reduction-and-token-discipline');V=S/'notes/verification';R=V/'reports';O=R/'s68-op27-sealing'
BASE=json.loads((O/'baseline.json').read_text());REPORT=R/'opponent-round27.md';HISTORY=S/'notes/opponent.md';LEDGER=V/'rounds/opponent/ROUND-27'
SOURCE='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff';FLOOR='FLOOR-DJZyNl'
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(b):return hashlib.sha256(b).hexdigest()
def info(p):
 st=p.lstat();d={'type':stat.S_IFMT(st.st_mode),'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns}
 if p.is_symlink():d['target']=os.readlink(p)
 elif p.is_file():
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''):h.update(b)
  d.update(size=st.st_size,sha256=h.hexdigest())
 return d
def save(name,data):
 with (O/name).open('x') as f:json.dump(data,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,env=ENV).decode()
def fields(p):return p.read_text().splitlines()[1:]
def rawproof(returned,reserved,returnedfields,reservedfields):
 return {'entriesByteIdentical':returned==reserved,'entriesSha256':sha(returned),'entryCount':len(returned.splitlines()),'stateFieldsMatch':returnedfields==reservedfields,'returnedStateFields':returnedfields,'reservedStateFields':reservedfields}
RESULT={'startedAt':now(),'runnerPid':os.getpid(),'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'},'round':27,'gate':'opponent','reportSha256':BASE['reportSha256'],'source':SOURCE,'floor':FLOOR,'verdict':'CHALLENGED','steps':[],'automaticRetries':0,'completionInvocations':0,'tallyInvocations':0,'historicalStrictPreservation':False,'reviewStrictPreservation':False,'reviewPreservationException':BASE['reviewException'],'formalClearance':False,'sourceRepairStarted':False,'OP28Authorized':False,'RC4Blocked':True,'rc4Started':False}
def run(name,argv):
 step={'name':name,'argv':argv,'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'},'startedAt':now(),'runnerPid':os.getpid(),'stdin':'DEVNULL','startNewSession':True,'stdout':str(ROOT/O/(name+'.stdout')),'stderr':str(ROOT/O/(name+'.stderr'))};t=time.monotonic()
 print(json.dumps({'starting':name,'at':step['startedAt']}),flush=True)
 with (O/(name+'.stdout')).open('xb') as stdout,(O/(name+'.stderr')).open('xb') as stderr:
  proc=subprocess.Popen(argv,cwd=ROOT,env=ENV,stdin=subprocess.DEVNULL,stdout=stdout,stderr=stderr,start_new_session=True)
  step['nativePid']=proc.pid;save(name+'-started.json',step)
  rc=proc.wait()
 step.update(exit=rc,endedAt=now(),elapsedMonotonicSeconds=time.monotonic()-t)
 with (O/(name+'.rc')).open('x') as f:f.write(str(rc)+'\n');f.flush();os.fsync(f.fileno())
 save(name+'-exit.json',step);RESULT['steps'].append(step)
 print(json.dumps(step),flush=True)
 if rc:raise RuntimeError(name+' native command failed; no retry: '+str(rc))
 return step

def protection(name,after=False):
 changed={};missing=[];directory={};external={}
 authorizeddirs={str(R),str(O)}
 if after:authorizeddirs|={str(S/'notes'),str(V),str(LEDGER)}
 for n,b in BASE['worktree'].items():
  p=ROOT/n;cur=info(p) if p.exists() or p.is_symlink() else None
  if cur is None:missing.append(n)
  elif cur!=b:
   if b['type']==stat.S_IFDIR and {k:v for k,v in b.items() if k!='mtime_ns'}=={k:v for k,v in cur.items() if k!='mtime_ns'}:directory[n]={'before':b,'after':cur,'authorizedKernelOrReceiptDirectory':n in authorizeddirs}
   elif after and n==str(HISTORY):pass
   else:changed[n]={'before':b,'after':cur}
 for n,b in BASE['external'].items():
  p=Path(n);cur=info(p) if p.exists() or p.is_symlink() else None
  if cur!=b:external[n]={'before':b,'after':cur}
 refs=git('for-each-ref','--format=%(refname) %(objectname)')
 def refmap(raw):return dict(line.split(' ',1) for line in raw.splitlines())
 old,new=refmap(BASE['global_refs']),refmap(refs);refdiff={n:{'before':old.get(n),'after':new.get(n)} for n in old.keys()|new.keys() if old.get(n)!=new.get(n)}
 additions=[];unexpected=[]
 allowednew={str(R/'r23-state-s68-op27-returned.txt'),str(R/'r23-state-s68-op27-returned.entries')}
 if after:allowednew.add(str(LEDGER/'report.sha256'))
 for parent,dirs,files in os.walk(ROOT,followlinks=False):
  for n in dirs+files:
   rel=str((Path(parent)/n).relative_to(ROOT))
   if rel not in BASE['worktree']:
    additions.append(rel)
    if not (rel.startswith(str(O)+'/') or rel in allowednew):unexpected.append(rel)
 externaladd=[]
 G=Path('/Users/babar/projects/sdd-kit-public/.git')
 for parent,dirs,files in os.walk(G,followlinks=False):
  if Path(parent)==G:dirs[:]=[d for d in dirs if d!='objects']
  for n in dirs+files:
   p=Path(parent)/n
   if str(p) not in BASE['external']:externaladd.append({'path':str(p),'state':info(p)})
 head=git('rev-parse','HEAD').strip()
 worktreeok=not(changed or missing or unexpected or any(not d['authorizedKernelOrReceiptDirectory'] for d in directory.values()))
 strict=worktreeok and not(external or externaladd or refdiff) and head==BASE['head']
 data={'at':now(),'originalEntries':len(BASE['worktree']),'changedPreexistingFilesModesMtimes':changed,'missingPreexistingEntries':missing,'directoryMtimeDifferences':directory,'externalDifferences':external,'externalAdditions':externaladd,'globalRefDifferences':refdiff,'globalRefsByteIdentical':refs==BASE['global_refs'],'head':head,'headIdentical':head==BASE['head'],'newPaths':additions,'unexpectedAdditions':unexpected,'worktreeOriginalsPreservedExceptAuthorizedHistory':worktreeok,'sealingWindowStrictPreservationPassed':strict,'historicalStrictPreservation':False,'reviewStrictPreservation':False,'differenceAttribution':'Unknown actor for any external/ref/OS difference; no restoration or allowlisting','authorizedHistoryChange':{'before':BASE['worktree'][str(HISTORY)],'after':info(HISTORY)} if after else None}
 save(name,data)
 with (O/(name+'.refs.txt')).open('x') as f:f.write(refs)
 return data

def selfcheck():
 assert rawproof(b'a\n',b'a\n',['x'],['x'])['entriesByteIdentical']
 assert not rawproof(b'a\n',b'b\n',['x'],['x'])['entriesByteIdentical']
 assert not rawproof(b'a\n',b'a\n',['x'],['y'])['stateFieldsMatch']
 assert b'h\n'+b'\n'+b'r\n'==b'h\n\nr\n'
 return {'passed':True,'checks':['raw identity accepts identical','raw identity refuses changed bytes','state fields refuse mismatch','append formula retains exact report bytes']}
if '--selfcheck' in sys.argv:
 print(json.dumps(selfcheck()));sys.exit(0)
try:
 assert not (O/'returned-started.json').exists(),'operation already started'
 save('native-launch.json',{'at':now(),'runnerPid':os.getpid(),'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'}})
 run('returned',['bash',str(ROOT/R/'r23-worktree-state.sh'),'s68-op27-returned'])
 raw=rawproof((R/'r23-state-s68-op27-returned.entries').read_bytes(),(R/'r23-state-s66-op27-reserved.entries').read_bytes(),fields(R/'r23-state-s68-op27-returned.txt'),fields(R/'r23-state-s66-op27-reserved.txt'))
 raw['at']=now();save('returned-raw-proof.json',raw);RESULT['returnedRawProof']=raw
 assert raw['entriesByteIdentical'] and raw['stateFieldsMatch'] and raw['entryCount']==7044 and raw['entriesSha256']=='db0cd28a189def025a4aafae6b1552a4cb654accef6c1f2f397eb2b2d971fa0a','returned tripwire mismatch; stop without completion'
 pre=protection('protection-pre-completion.json');RESULT['preCompletionProtection']=pre
 assert pre['worktreeOriginalsPreservedExceptAuthorizedHistory'] and pre['headIdentical'],'preexisting worktree original changed before completion'
 assert REPORT.read_bytes()==(O/'canonical-op27-report.md').read_bytes()==(O/'actual-worker-return.txt').read_bytes()
 assert sha(REPORT.read_bytes())==BASE['reportSha256']
 assert not (LEDGER/'report.sha256').exists(),'already sealed; no duplicate completion'
 assert HISTORY.read_bytes()==(O/'opponent-before.md').read_bytes()
 assert not (V/'lock').exists() and not list(V.glob('round-check.*'))
 RESULT['completionInvocations']=1
 run('complete',['bash','scripts/spec-gate.sh','round',str(S),'opponent','--complete',str(REPORT)])
 RESULT['sealed']=True;RESULT['tallyInvocations']=1
 run('tally',['bash','scripts/spec-gate.sh','tally',str(S)])
 RESULT['tallied']=True
 report=REPORT.read_bytes();before=(O/'opponent-before.md').read_bytes();history=HISTORY.read_bytes()
 prior={n:(ROOT/n).exists() and info(ROOT/n)==b for n,b in BASE['worktree'].items() if n.startswith(str(V/'rounds')+'/') and b['type']!=stat.S_IFDIR}
 m=(LEDGER/'meta.nul').read_bytes().split(b'\0');metadata=dict(zip((x.decode() for x in m[0:-1:2]),(x.decode() for x in m[1:-1:2])))
 tally=(O/'tally.stdout').read_text()
 checks={'canonicalReportUnchanged':sha(report)==BASE['reportSha256'] and report==(O/'canonical-op27-report.md').read_bytes() and len(report)==13284,'sealMatchesCanonicalReport':(LEDGER/'report.sha256').read_bytes()==BASE['reportSha256'].encode()+b'\n','priorHistoryPrefixUnchanged':history.startswith(before),'onlyOneLFAndExactReportAppended':history==before+b'\n'+report,'priorRoundFilesUnchanged':all(prior.values()),'reservationMetaUnchanged':sha((LEDGER/'meta.nul').read_bytes())==BASE['metaSha256'],'sourceMatches':metadata['source']==SOURCE,'floorMatches':metadata['floor']==FLOOR,'roundMatches':metadata['round']=='27','completionExitZero':RESULT['steps'][1]['exit']==0,'tallyExitZero':RESULT['steps'][2]['exit']==0,'tallyOpponent27':'opponent rounds=27\n' in tally,'currentChallengedCounts':'**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 1\n' in report.decode(),'lockAbsent':not (V/'lock').exists(),'roundStagingAbsent':not list(V.glob('round-check.*'))}
 verify={'at':now(),'checks':checks,'passed':all(checks.values()),'canonicalHistorySha256':sha(history),'canonicalHistoryBytes':len(history),'canonicalHistoryBeforeSha256':sha(before),'metadata':metadata,'priorRoundFiles':prior,'latestRound':{'round':27,'verdict':'CHALLENGED','blocking':1,'blockingFinding':'O-034','minor':1,'minorFinding':'O-032'},'tallyIsCumulativeHistory':True,'cumulativeTallyLine':next((l for l in tally.splitlines() if l.startswith('blocking=')),None),'tallyStdoutSha256':sha(tally.encode())}
 save('sealing-verification.json',verify);RESULT['sealingVerification']=verify
 post=protection('protection-after.json',after=True);RESULT['protection']=post
 assert verify['passed'],'post-seal verification failed'
 RESULT.update(kernelStatus='sealed-and-tallied',sealingWindowStrictPreservationPassed=post['sealingWindowStrictPreservationPassed'],exit=0 if post['sealingWindowStrictPreservationPassed'] else 1,phase='challenged-report-sealed-and-tallied')
except BaseException as exc:
 RESULT.update(exit=1,error=str(exc),traceback=traceback.format_exc(),phase='stopped-without-retry')
 if not (O/'protection-after.json').exists():
  try:RESULT['protection']=protection('protection-after.json',after=RESULT.get('sealed',False))
  except BaseException as obs:RESULT['protectionObserverError']=str(obs)
finally:
 RESULT['endedAt']=now();save('result.json',RESULT)
 save('final-observation.json',{'at':RESULT['endedAt'],'actualNativeRunnerExit':RESULT['exit'],'actualKernelCompletionExit':next((s['exit'] for s in RESULT['steps'] if s['name']=='complete'),None),'actualTallyExit':next((s['exit'] for s in RESULT['steps'] if s['name']=='tally'),None),'completionInvocations':RESULT['completionInvocations'],'tallyInvocations':RESULT['tallyInvocations'],'automaticRetries':0,'sealed':RESULT.get('sealed',False),'tallied':RESULT.get('tallied',False),'canonicalReportSha256':BASE['reportSha256'],'source':SOURCE,'floor':FLOOR,'verdict':'CHALLENGED','latestRoundBlocking':1,'latestRoundBlockingFinding':'O-034','latestRoundMinor':1,'latestRoundMinorFinding':'O-032','cumulativeTally':RESULT.get('sealingVerification',{}).get('cumulativeTallyLine'),'sealingVerification':RESULT.get('sealingVerification'),'rawReturnedTripwire':RESULT.get('returnedRawProof'),'sealingWindowStrictPreservationPassed':RESULT.get('protection',{}).get('sealingWindowStrictPreservationPassed'),'reviewStrictPreservation':False,'reviewPreservationException':BASE['reviewException'],'historicalStrictPreservation':False,'protectionReceipt':str(ROOT/O/'protection-after.json'),'sourceRepairStarted':False,'formalClearance':False,'rc4Started':False,'op28Started':False,'error':RESULT.get('error')})
 print(json.dumps({'phase':RESULT['phase'],'exit':RESULT['exit'],'sealed':RESULT.get('sealed',False),'tallied':RESULT.get('tallied',False),'error':RESULT.get('error')}),flush=True)
 sys.exit(RESULT['exit'])
