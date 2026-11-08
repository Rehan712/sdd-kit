import os, stat, json, hashlib, subprocess, datetime, time, re, traceback
from pathlib import Path
P=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
S=Path('.specify/specs/003-gate-round-reduction-and-token-discipline'); V=S/'notes/verification'; R=V/'reports'; W=R/'s58-analyzer-refresh'
EXPECTED='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff'
TASK='T031a5o1'; LOCATOR='tests/test-sdd-analyze.sh::test_verification_bindings'
checks={}; result={'task':TASK,'status':'failed','historicalStrictPreservationPassed':False,'captureExecutions':0,'checks':checks}
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(b): return hashlib.sha256(b).hexdigest()
def save(name,value):
 with (W/name).open('x') as f:
  json.dump(value,f,indent=2,sort_keys=True);f.write('\n');f.flush();os.fsync(f.fileno())
def raw(name,value):
 with (W/name).open('xb') as f:f.write(value);f.flush();os.fsync(f.fileno())
def run(argv,**kwargs): return subprocess.run(argv,cwd=P,env=ENV,**kwargs)
def git(*args): return run(['git',*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout
def info(p):
 p=Path(p); st=p.lstat(); d={'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns,'size':st.st_size}
 if p.is_symlink(): d.update(type='symlink',target=os.readlink(p),sha256=sha(os.fsencode(os.readlink(p))))
 elif p.is_file():
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''):h.update(b)
  d.update(type='file',sha256=h.hexdigest())
 else:d['type']='other'
 return d
def inventory():
 out={}
 for root,dirs,files in os.walk('.',followlinks=False):
  dirs.sort();files.sort()
  for n in list(dirs):
   p=Path(root)/n
   if p==Path('.git') or p==W:dirs.remove(n)
   elif p.is_symlink():out[str(p)]=info(p);dirs.remove(n)
  for n in files:
   p=Path(root)/n;out[str(p)]=info(p)
 return out
def external():
 gd=Path(git('rev-parse','--absolute-git-dir').decode().strip()); cd=Path(git('rev-parse','--git-common-dir').decode().strip());cd=cd if cd.is_absolute() else P/cd
 branch=git('symbolic-ref','HEAD').decode().strip()
 paths=[gd/'HEAD',gd/'index',gd/'logs/HEAD',cd/branch,cd/'logs'/branch,cd/'packed-refs']
 return {'HEAD':git('rev-parse','HEAD').decode().strip(),'branch':branch,'files':{str(p):info(p) if p.exists() else None for p in paths},'refs':git('for-each-ref','--format=%(refname) %(objectname)').decode()}
def operations():
 out=run(['ps','-axo','pid=,ppid=,stat=,comm='],stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout
 rows=[]
 for line in out.decode().splitlines():
  q=line.strip().split(None,3)
  if len(q)==4:rows.append((int(q[0]),int(q[1]),q[2],q[3]))
 ancestors={os.getpid()};parent=os.getppid();parents={a:b for a,b,_,_ in rows}
 while parent and parent not in ancestors:ancestors.add(parent);parent=parents.get(parent,0)
 live=[]
 for pid,ppid,state,comm in rows:
  if pid in ancestors or Path(comm).name not in ['bash','zsh','sh','python','python3','Python']:continue
  args=run(['ps','-p',str(pid),'-o','args='],stdout=subprocess.PIPE,stderr=subprocess.PIPE).stdout.decode().strip()
  if re.search(r'(?:spec-(?:run|gate|task|ci)\.sh|tests/(?:run|test-[^ ]+|shellcheck)\.sh|reports/s(?:48|50|52|55|56|57|58)[^ ]*\.py)',args):live.append({'pid':pid,'ppid':ppid,'state':state,'argv':args})
 return {'observedAt':now(),'listingSha256':sha(out),'processCount':len(rows),'survivingOperations':live}
def pending():
 out=[]
 for base in [V,S/'notes/captures']:
  for p in base.iterdir():
   if p.name in ['lock','sequence.tmp'] or p.name.startswith(('.capture.','bindings.','return.','.accept.','.floor.','.round.')):out.append(str(p))
 for gate in ['opponent','reality-check']:
  for p in (V/'rounds'/gate).glob('ROUND-*'):
   if p.is_dir() and not (p/'COMPLETE').is_file():out.append(str(p))
 gd=Path(git('rev-parse','--absolute-git-dir').decode().strip())
 for p in [gd/'index.lock',gd/'HEAD.lock']:
  if p.exists():out.append(str(p))
 return sorted(out)
def checked(stem,argv,input=None):
 record={'argv':argv,'cwd':str(P),'GIT_OPTIONAL_LOCKS':'0','start':now(),'startNs':time.time_ns()}
 with (W/(stem+'.stdout')).open('xb') as out,(W/(stem+'.stderr')).open('xb') as err:
  child=subprocess.Popen(argv,cwd=P,env=ENV,stdin=subprocess.PIPE if input is not None else subprocess.DEVNULL,stdout=out,stderr=err)
  record['nativePid']=child.pid;save(stem+'.start.json',record)
  child.communicate(input);code=child.returncode
 record.update(end=now(),endNs=time.time_ns(),exit=code)
 for n in ['stdout','stderr']:
  b=(W/(stem+'.'+n)).read_bytes();record[n+'Sha256']=sha(b);record[n+'Bytes']=len(b)
 save(stem+'.json',record);raw(stem+'.exit.txt',(str(code)+'\n').encode());return record

def check(k,v): checks[k]=bool(v)
def meta(p):
 a=p.read_bytes().split(b'\0');assert a[-1]==b'' and len(a)%2==1;a=a[:-1];assert len(a[::2])==len(set(a[::2]));return {k.decode():v.decode() for k,v in zip(a[::2],a[1::2])}
def refsmap(t):return dict(line.split(' ',1) for line in t.splitlines())

try:
 save('identity.json',{'provider':'codex','model':'gpt-6.1-sol','reasoningEffort':'high','serviceTier':'default','basis':'Model/high declared by current harness; codex transition explicitly authorized in s56 provider-transition. Requested default tier not independently API-observed.','nestedAgents':False,'modelCLI':False,'providerSubstitution':False})
 before=inventory();save('inventory.before.json',before)
 extbefore=external();save('git.before.json',extbefore);raw('global-refs.before.txt',extbefore['refs'].encode())
 raw('git-status.before.nul',git('status','--porcelain=v1','-z','--untracked-files=all'))
 protected={str(S/'STATUS.md'):('dfa43e94c72e6b9a6b659d7454d1f7b854516a7bb42a1d58c2ceef31b674cc1d',0o600,1793309559845064145),str(S/'tasks.md'):('2380332731cede88cbcef942aed51847a80a1dd23166b03dc3b80f9381f1d9bd',0o600,1793311225510798891),'/Users/babar/projects/sdd-kit-public/.git/worktrees/003-gate-round-reduction-and-token-discipline/index':('c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700',0o644,1792957592613445716),'scripts/sdd-analyze.sh':('f2809d24b5bec01fa4ca8ab4d689c5e9585472989e66798aabc9597d80f176fd',0o755,None),'tests/test-sdd-analyze.sh':('9dd851fd6ed32797384ada5c4d263dcdbb6947ce95cdeae4d5ea0ac1bb60a393',0o644,None),'tests/test-gate-contracts.sh':('7bc13dde14004bf4ba967c0f64ec120b19bdde641643a6a7436d154c222f893c',0o644,None)}
 protection_before={p:info(p) for p in protected};save('protection.before.json',protection_before)
 for p,(h,m,t) in protected.items():
  x=protection_before[p];assert x['sha256']==h and x['mode']==m and (t is None or x['mtimeNs']==t),(p,x)
 assert extbefore['HEAD']=='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9' and extbefore['branch']=='refs/heads/spec/003-gate-round-reduction-and-token-discipline'
 assert (V/'sequence').read_bytes()==b'844\n';raw('sequence.before.txt',(V/'sequence').read_bytes());raw('evidence.before.bin',(S/'notes/evidence.md').read_bytes())
 for f in ['s55-approval/approval.json','s55-approval/result.json','s55-approval/freshness-result.json','s56-t029-recovery/result.json','s56-t029-recovery/provider-transition.json','s57-t029-control/result.json','s57-t029-control/return-provenance.json']:
  data=json.loads((R/f).read_text());assert data
 assert json.loads((R/'s57-t029-control/result.json').read_text())['exit']==0
 assert json.loads((R/'s56-t029-recovery/provider-transition.json').read_text())['toProvider']=='codex'
 preproc=operations();save('processes.preflight.json',preproc);assert not preproc['survivingOperations'],preproc
 pend=pending();save('pending.preflight.json',pend);assert not pend,pend
 scratch={str(d):sorted(x.name for x in d.iterdir()) for d in V.iterdir() if d.is_dir() and d.name.startswith(('execute.','floor-check.','opponent-readiness.'))}
 receiptpaths=[R/'s55-t029-worker/command.json',R/'s55-t029-worker/result.json',R/'s56-t029-recovery/result.json',R/'s57-t029-control/result.json']
 save('preflight.json',{'at':now(),'sequence':844,'protectedBaselineMatches':True,'ownedDirectoryWasAbsentBeforeCreation':True,'outputCollisions':[],'pending':pend,'processes':preproc,'historicalScratchPreserved':scratch,'recentExitReceipts':{str(p):{'protection':info(p),'receipt':json.loads(p.read_text())} for p in receiptpaths},'preexistingFileCount':len(before),'parentConcurrentWrites':'none authorized'})
 before_script='''set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"
vf_binding_snapshot "$spec" "$own/bindings.before.nul" || exit 3
vf_snapshot "$(cd "$spec" && pwd -P)" "$PWD" "$PWD" "$own/inputs.before.nul" || exit 3
'''
 raw('source-before.sh.txt',before_script.encode())
 sr=checked('source-before',['bash','-s','--',str(S),str(W)],before_script.encode());assert sr['exit']==0
 assert (W/'source-before.stdout').read_bytes()==(EXPECTED+'\n').encode() and sha((W/'inputs.before.nul').read_bytes())==EXPECTED
 assert inventory()==before,'Preexisting worktree changed before launch'
 assert {p:info(p) for p in protected}==protection_before and external()['files']==extbefore['files']
 prelaunch=operations();save('processes.prelaunch.json',prelaunch);assert not prelaunch['survivingOperations'];assert not pending()
 for n in ['capture.start.json','capture.json','capture.stdout','capture.stderr','capture.exit.txt','worker-return.txt','result.json']:assert not (W/n).exists(),'Output collision '+n
 print(json.dumps({'stage':'preflight-complete','source':EXPECTED,'preexistingFiles':len(before),'next':'sole-native-capture'}),flush=True)
 argv=['bash','scripts/spec-run.sh',str(S),TASK,'--from-task','--no-tick','--summary']
 save('capture-request.json',{'argv':argv,'cwd':str(P),'attempt':1,'retries':0,'environmentPolicy':'Inherited with GIT_OPTIONAL_LOCKS=0; only nonsecret execution-relevant whitelist persisted.','nonsecretEnvironment':{k:ENV[k] for k in ['GIT_OPTIONAL_LOCKS','PATH','SHELL','TMPDIR','LANG','LC_ALL','LC_CTYPE','NO_COLOR'] if k in ENV},'start':now(),'wrapperPid':os.getpid()})
 result['captureExecutions']=1
 command=checked('capture',argv);result['command']=command;check('nativeExitZero',command['exit']==0)
 print(json.dumps({'stage':'native-complete','nativeExit':command['exit'],'nativePid':command['nativePid'],'end':command['end']}),flush=True)
 stdout=(W/'capture.stdout').read_bytes();stderr=(W/'capture.stderr').read_bytes()
 match=re.match(rb'capture=(CAP-[1-9][0-9]*-[A-Za-z0-9]+) ',stdout);assert match,'No actual capture ID; no retry'
 cap=match[1].decode();result['capture']=cap;d=S/'notes/captures'/cap;ledger=V/'captures'/cap
 members=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt'];md=meta(d/'meta.nul');hashes={n:sha((d/n).read_bytes()) for n in members}
 seal=('verification:1\n'+''.join(hashes[n]+' '+n+'\n' for n in members)).encode()
 check('sevenMembersExactAndComplete',set(x.name for x in d.iterdir())==set(members+['COMPLETE']) and all((d/n).is_file() and not (d/n).is_symlink() for n in members+['COMPLETE']) and (d/'COMPLETE').read_bytes()==seal)
 check('ledgerMatchesSeal',ledger.is_file() and not ledger.is_symlink() and ledger.read_bytes()==seal)
 check('captureMetadataIdentityNoTickExit',md['id']==cap and md['version']=='1' and md['kind']=='command' and md['sequence']=='845' and cap.startswith('CAP-845-') and md['no_tick']=='1' and md['exit']=='0')
 check('sourceBeforeAfterExactCurrent',md['input_before']==md['input_after']==hashes['inputs.nul']==hashes['inputs-after.nul']==EXPECTED and (W/'inputs.before.nul').read_bytes()==(d/'inputs.nul').read_bytes()==(d/'inputs-after.nul').read_bytes())
 output=(d/'output.log').read_bytes();summary=(d/'summary.txt').read_bytes();lines=output.decode().splitlines()
 check('outputDigestByteCount',sha(output)==md['output_digest'] and len(output)==int(md['output_bytes']))
 check('actual19of19',md['key'].strip()=='-- 19/19 passed' and lines[-1].strip()=='-- 19/19 passed' and len([x for x in lines if re.match(r'^  ok   ',x)])==19 and b'assert:' not in output)
 check('actualSummaryExactOneLine',stdout==summary and stdout.endswith(b'\n') and stdout.count(b'\n')==1)
 check('nativeStderrEmpty',stderr==b'')
 check('exactTaskArgv',(d/'argv.nul').read_bytes()==b'\0'.join([md['shell'].encode(),b'-o',b'pipefail',b'-c',b'bash tests/test-sdd-analyze.sh'])+b'\0')
 check('captureCwdRepoExact',md['cwd']==md['repo']==str(P))
 result['summary']=summary.decode().removesuffix('\n')
 save('capture-proof.json',{'capture':cap,'metadata':md,'sevenMemberHashes':hashes,'complete':info(d/'COMPLETE'),'ledger':info(ledger),'outputTail':lines[-23:],'nativeCommand':command,'nativeStdoutExactSummary':stdout==summary})
 verify_script='''set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; cap="$2"; own="$3"
vf_binding_snapshot "$spec" "$own/bindings.after.nul" || exit 3
vf_snapshot "$(cd "$spec" && pwd -P)" "$PWD" "$PWD" "$own/inputs.after.nul" > "$own/source.after.txt" || exit 3
vf_capture_check "$spec" "$cap" "$own/inputs.after.nul" integrity || exit 3
vf_capture_check "$spec" "$cap" "$own/inputs.after.nul" current || exit 3
vf_task_capture_matches "$own/bindings.after.nul" T031a5o1 "$spec/notes/captures/$cap" || exit 3
'''
 raw('current-check.sh.txt',verify_script.encode())
 vr=checked('current-check',['bash','-s','--',str(S),cap,str(W)],verify_script.encode())
 check('kernelIntegrityCurrentTaskMatch',vr['exit']==0)
 check('currentLiveSourceExact', (W/'source.after.txt').read_bytes()==(EXPECTED+'\n').encode() and sha((W/'inputs.after.nul').read_bytes())==EXPECTED and (W/'inputs.after.nul').read_bytes()==(W/'inputs.before.nul').read_bytes())
 current=(W/'bindings.after.nul').read_bytes();check('currentBindingsExactBeforeCaptureAfter',current==(W/'bindings.before.nul').read_bytes()==(d/'bindings.nul').read_bytes())
 fields=current.split(b'\0');assert fields[-1]==b'';fields=fields[:-1];assert len(fields)%12==0
 rows=[fields[i:i+12] for i in range(0,len(fields),12)]
 bindings=sorted({(a[1].decode(),a[7].decode()) for a in rows if a[0]==b'binding' and a[2]==TASK.encode()})
 want=[('FM-001',LOCATOR),('INV-005',LOCATOR)]
 check('exactFM001INV005Bindings',bindings==want)
 taskrows=[[v.decode() for v in a] for a in rows if a[0]==b'task' and a[2]==TASK.encode()]
 check('currentTaskVerifyExact',len(taskrows)==1 and taskrows[0][9].startswith('`bash tests/test-sdd-analyze.sh`'))
 save('bindings-proof.json',{'task':TASK,'failureModes':bindings,'taskRows':taskrows,'bindingDigest':sha(current),'currentKernelCheck':vr})
 after=inventory();save('inventory.after.json',after);extafter=external();save('git.after.json',extafter);raw('global-refs.after.txt',extafter['refs'].encode())
 protection_after={p:info(p) for p in protected};save('protection.after.json',protection_after)
 check('protectedSourceHEADIndexSTATUSTasksExact',protection_after==protection_before and extafter['HEAD']==extbefore['HEAD'] and extafter['branch']==extbefore['branch'] and extafter['files']==extbefore['files'])
 automatic={str(S/'notes/evidence.md'),str(V/'sequence')};allowed_new={str(d/n) for n in members+['COMPLETE']}|{str(ledger)}
 differences={p:{'before':b,'after':after.get(p)} for p,b in before.items() if after.get(p)!=b};unexplained={p:v for p,v in differences.items() if p not in automatic}
 missing=sorted(set(before)-set(after));new=sorted(set(after)-set(before));unexpectednew=sorted(set(new)-allowed_new)
 refsb=refsmap(extbefore['refs']);refsa=refsmap(extafter['refs']);refdiff={p:{'before':refsb.get(p),'after':refsa.get(p)} for p in sorted(set(refsb)|set(refsa)) if refsb.get(p)!=refsa.get(p)}
 append=('\n## '+cap+' — '+md['end']+'\n\nCaptured run, exit '+md['exit']+'. Full log: `notes/captures/'+cap+'/output.log`.\n\n').encode()+summary
 raw('evidence-append.raw',append)
 check('evidenceExactAutomaticAppend',(S/'notes/evidence.md').read_bytes()==(W/'evidence.before.bin').read_bytes()+append)
 check('sequenceExact844to845',(V/'sequence').read_bytes()==b'845\n')
 check('automaticModesPreserved',all(before[p]['mode']==after[p]['mode'] for p in automatic))
 check('noMissingPreexistingFiles',not missing)
 check('newFilesExactCaptureAndLedger',set(new)==allowed_new and not unexpectednew)
 # Strict preservation remains false for every unexplained difference; .DS_Store changes do not establish capture or core failure.
 check('noUnexplainedCoreOrHistoricalChanges',not {p:v for p,v in unexplained.items() if Path(p).name!='.DS_Store'})
 pendingafter=pending();procafter=operations();save('processes.after.json',procafter);save('pending.after.json',pendingafter)
 check('noSurvivingCaptureLockStagingPending',not pendingafter and not procafter['survivingOperations'])
 raw('git-status.after.nul',git('status','--porcelain=v1','-z','--untracked-files=all'))
 strict=not unexplained and not refdiff and not missing and not unexpectednew
 proof={'preexistingFileCount':len(before),'preexistingDifferences':differences,'unknownActorDifferences':unexplained,'missing':missing,'newPaths':new,'unexpectedNewPaths':unexpectednew,'globalRefsDifferential':refdiff,'strictCurrentPreservationPassed':strict,'strictHistoricalPreservationPassed':False,'protectedCorePreserved':checks['protectedSourceHEADIndexSTATUSTasksExact'],'allOtherOriginalFilesPreserved':not unexplained and not missing,'policy':'All preexisting worktree files/symlinks compared by hash/type/size/mode/mtime. Only actual kernel evidence append and sequence update are authorized modifications; no resetting, ownership inference or broad allowlisting. Unknown .DS_Store/globalrefs differences remain separately disclosed strict failures, distinct from capture/current binding/core integrity.'}
 save('protection-proof.json',proof);result['preservation']=proof
 result.update(actualCurrentSource=EXPECTED,kernelReadOnlyChecks=vr,executionCount=1,noTick=True,acceptanceExecuted=False,sourceTaskStatusEdits=False,qualityRepeat=False,focusedProbesOrStaticChecks=False,gateFloorCIReservationTallyNetworkPRExecuted=False,minorRepairs=False,formalClearanceOrReadinessClaim=False,historicalCanonicalUnchanged=True,strictCurrentPreservationPassed=strict)
 if all(checks.values()):
  body='Verification-Return: 1\nTask: '+TASK+'\nCaptures: '+cap+'\nSummary: '+result['summary']+'\nFailure modes:\n'+''.join(a+', '+b+', '+cap+'\n' for a,b in bindings)
  data=body.encode();assert data.endswith(b'\n') and not data.endswith(b'\n\n');raw('worker-return.txt',data)
  result.update(status='passed',workerReturn={'path':str(W/'worker-return.txt'),'sha256':sha(data),'bytes':len(data),'terminalLFCount':1})
 else:result['failedChecks']=[k for k,v in checks.items() if not v]
except BaseException as exc:
 result['exception']=repr(exc);raw('failure-traceback.txt',traceback.format_exc().encode())
finally:
 result['ended']=now();save('result.json',result)
 print(json.dumps({'status':result['status'],'capture':result.get('capture'),'failedChecks':result.get('failedChecks'),'exception':result.get('exception'),'strictCurrentPreservationPassed':result.get('strictCurrentPreservationPassed'),'result':str(W/'result.json')}),flush=True)
 if result['status']=='passed':print((W/'worker-return.txt').read_text(),end='',flush=True)
raise SystemExit(0 if result['status']=='passed' else 1)
