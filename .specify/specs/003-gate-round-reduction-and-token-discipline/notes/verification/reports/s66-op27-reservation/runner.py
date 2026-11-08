import datetime, hashlib, json, os, pathlib, stat, subprocess, sys, time, traceback
ROOT=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline'; V=S/'notes/verification'; R=V/'reports'; O=R/'s66-op27-reservation'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
SOURCE='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff'; HEAD='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'; FLOOR='FLOOR-DJZyNl'
def utc(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(b): return hashlib.sha256(b).hexdigest()
def load(n): return json.loads((O/n).read_text())
def write(n,d):
    with (O/n).open('x') as f:
        json.dump(d,f,indent=2); f.write('\n'); f.flush(); os.fsync(f.fileno())
def raw(p):
    st=p.lstat(); d={'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns,'size':st.st_size}
    if stat.S_ISLNK(st.st_mode): d.update(kind='symlink',target=os.readlink(p))
    elif stat.S_ISREG(st.st_mode):
        h=hashlib.sha256()
        with p.open('rb') as f:
            for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
        d.update(kind='file',sha256=h.hexdigest())
    else: d.update(kind='other')
    return d
def inventory(base):
    d={}
    for folder,dirs,files in os.walk(base,followlinks=False):
        for n in sorted(dirs+files):
            p=pathlib.Path(folder)/n
            if p.is_symlink() or not p.is_dir(): d[str(p.relative_to(base))]=raw(p)
    return d
def git(*a): return subprocess.check_output(['git',*a],cwd=ROOT,env=ENV,text=True).strip()
def meta(p):
    f=p.read_bytes().split(b'\0'); assert f.pop()==b'' and len(f)%2==0
    d=dict(zip((x.decode() for x in f[::2]),(x.decode() for x in f[1::2]))); assert len(d)*2==len(f)
    return d
def state(label): return (R/('r23-state-s66-op27-'+label+'.txt')).read_text().splitlines()[1:]
def activity():
    ps=subprocess.check_output(['ps','-axo','pid,ppid,lstart,stat,command'],cwd=ROOT,env=ENV,text=True)
    return {'at':utc(),'activeProcesses':[l for l in ps.splitlines() if any(t in l for t in ['spec-gate.sh','r23-worktree-state.sh','s60-evidence-preparation/runner.py','s46-op26-reservation/runner.py'])], 'pending':[str(p) for p in (V/'rounds').glob('*/ROUND-*') if not (p/'report.sha256').is_file()], 'staged':[str(p) for p in (V/'rounds').glob('*/.reservation-*')]+[str(p) for p in V.glob('round-check.*')], 'lock':os.path.lexists(V/'lock'),'op27Exists':os.path.lexists(V/'rounds/opponent/ROUND-27')}
def inactive(a): assert not any(a[k] for k in ['activeProcesses','pending','staged','lock','op27Exists']),a
def execute(name,argv):
    tick=time.monotonic(); started=utc()
    with (O/(name+'.stdout')).open('xb') as out,(O/(name+'.stderr')).open('xb') as err:
        p=subprocess.Popen(argv,cwd=ROOT,env=ENV,stdin=subprocess.DEVNULL,stdout=out,stderr=err)
        d={'name':name,'argv':argv,'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'},'nativePid':p.pid,'runnerPid':os.getpid(),'stdin':'DEVNULL','stdout':str(O/(name+'.stdout')),'stderr':str(O/(name+'.stderr')),'startedAt':started,'startMonotonic':tick}
        write(name+'.started.json',d); print(json.dumps(d),flush=True)
        rc=p.wait(); out.flush(); err.flush(); os.fsync(out.fileno()); os.fsync(err.fileno())
    end=utc(); d.update(exit=rc,endedAt=end,elapsedMonotonicSeconds=time.monotonic()-tick,elapsedUtcSeconds=(datetime.datetime.fromisoformat(end)-datetime.datetime.fromisoformat(started)).total_seconds())
    steps.append(d); write(name+'.completed.json',d); print(json.dumps(d),flush=True)
    return rc
boundary=load('original-boundary.json'); baseline=load('baseline-inventory.json'); external_before=load('external-git-before.json'); refs_before=load('refs-before.json')
gd=pathlib.Path(boundary['gitDir']); common=pathlib.Path(boundary['gitCommonDir'])
protected=[gd/'HEAD',gd/'index',ROOT/'.git',S/'STATUS.md',S/'tasks.md',ROOT/'scripts/sdd-analyze.sh',ROOT/'tests/test-sdd-analyze.sh',ROOT/'tests/test-gate-contracts.sh',R/'s66-op27-reservation-request.json',R/'r23-worktree-state.sh']
def before(p): return external_before[str(p.relative_to(gd))] if p.is_relative_to(gd) else baseline[str(p.relative_to(ROOT))]
protected_before={str(p):before(p) for p in protected}
def refs():
    d=inventory(common/'refs')
    for n in ['HEAD','packed-refs','config']:
        if (common/n).exists(): d['@'+n]=raw(common/n)
    return d
def differences(a,b): return {p:{'before':v,'after':b.get(p)} for p,v in a.items() if b.get(p)!=v}
steps=[]; result={'startedAt':utc(),'runnerPid':os.getpid(),'cwd':str(ROOT),'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'},'source':SOURCE,'floor':FLOOR,'gate':'opponent','round':27,'steps':steps,'reservationCreated':False,'reservationInvocations':0,'automaticRetries':0,'independentReviewStarted':False,'completedOrTallied':False,'formalClearanceClaimed':False,'historicalStrictPreservation':False,'exit':1}
try:
    assert pathlib.Path.cwd()==ROOT and os.environ['GIT_OPTIONAL_LOCKS']=='0'
    assert sha(b'')=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    assert differences({'a':1},{'a':1})=={} and differences({'a':1},{'a':2})=={'a':{'before':1,'after':2}}
    a=activity(); write('activity-at-launch.json',a); inactive(a)
    assert {str(p):raw(p) for p in protected}==protected_before
    assert git('rev-parse','HEAD')==HEAD and git('symbolic-ref','HEAD')==boundary['branch']
    approval=json.loads((R/'s55-approval/approval.json').read_text()); assert approval['actualUserAnswer']=='i approve' and approval['round']==27 and approval['after']==26
    assert '2026-10-29T21:28:39Z — waiver: gate=opponent; round=27; after=26; by=user;' in (S/'STATUS.md').read_text()
    transition=json.loads((R/'s56-t029-recovery/provider-transition.json').read_text()); assert transition['toProvider']=='codex'
    prior=V/'rounds/opponent/ROUND-26'; assert (prior/'report.sha256').read_text().strip()=='06f47f7fdb87803cd7dcd4e4e027549f331dc3e7e019b601998dd999bd4068cd'
    fm=meta(V/'floors'/FLOOR/'meta.nul'); assert fm['source']==SOURCE and fm['id']==FLOOR and fm['exit']=='0'
    assert (V/'floor-latest').read_text().strip()==FLOOR
    parent=json.loads((R/'s65-parent-floor-confirmation/parent-floor-observation.json').read_text())
    assert parent['floor']==FLOOR and parent['source']==SOURCE
    for n,d in parent['sealedMembers'].items(): assert sha((V/'floors'/FLOOR/n).read_bytes())==d['sha256']
    assert sha((V/'floors'/FLOOR/'COMPLETE').read_bytes())==parent['COMPLETE_SHA256']
    floor_result=json.loads((R/'s64-floor-operation/result.json').read_text()); assert floor_result['floorId']==FLOOR and floor_result['source']==SOURCE and set(floor_result['exits'].values())=={0} and floor_result['floorLaunchCount']==1
    write('preflight.json',{'at':utc(),'passed':True,'floor':fm,'protected':protected_before,'approvalReceipt':'s55-approval/approval.json','providerTransitionReceipt':'s56-t029-recovery/provider-transition.json','noStandaloneFloorValidator':True,'historicalStrictPreservation':False,'floorPowerLimitation':parent['powerLimitation'],'runtimeBasis':'Harness declares gpt-6.1-sol HIGH; default service tier explicitly requested; no independent runtime API assertion.'})
    assert execute('prereserve',['bash',str(R/'r23-worktree-state.sh'),'s66-op27-prereserve'])==0
    pre=state('prereserve'); assert 'source='+SOURCE in pre and 'head='+HEAD in pre
    assert {str(p):raw(p) for p in protected}==protected_before
    a=activity(); write('activity-before-reserve.json',a); inactive(a)
    result['reservationInvocations']=1
    rc=execute('reserve',['bash','scripts/spec-gate.sh','round',str(S.relative_to(ROOT)),'opponent','--floor',FLOOR]); result['actualReservationExit']=rc
    assert rc==0,('native reservation failed; no retry',rc)
    assert execute('reserved',['bash',str(R/'r23-worktree-state.sh'),'s66-op27-reserved'])==0
    x=(R/'r23-state-s66-op27-prereserve.entries').read_bytes(); y=(R/'r23-state-s66-op27-reserved.entries').read_bytes()
    result.update(entriesByteIdentical=x==y,entriesSha256=sha(x),entryCount=len(x.splitlines()),stateFieldsMatch=pre==state('reserved'))
    assert x==y and result['stateFieldsMatch']
    result['exit']=0
except BaseException as exc:
    result.update(exit=1,error=repr(exc),traceback=traceback.format_exc()); print(result['traceback'],file=sys.stderr,flush=True)
finally:
    try:
        ledger=V/'rounds/opponent/ROUND-27'; result['reservationCreated']=ledger.is_dir()
        if ledger.is_dir():
            metadata=meta(ledger/'meta.nul'); sealed=(ledger/'COMPLETE').read_text()=='verification:1\n'+sha((ledger/'meta.nul').read_bytes())+' meta.nul\n'
            reserve_step=next((s for s in steps if s['name']=='reserve'),None)
            timestampCurrent=bool(reserve_step and datetime.datetime.fromisoformat(reserve_step['startedAt']).replace(microsecond=0)<=datetime.datetime.fromisoformat(metadata['reserved'].replace('Z','+00:00'))<=datetime.datetime.fromisoformat(reserve_step['endedAt']))
            result.update(metadata=metadata,roundCompleteSealMatches=sealed,reservationTimestampWithinNativeWindow=timestampCurrent,pendingWithoutFinalReport=not (ledger/'report.sha256').exists(),ledgerFiles=sorted(p.name for p in ledger.iterdir()))
            result['reservationValid']=sealed and timestampCurrent and result['pendingWithoutFinalReport'] and result['ledgerFiles']==['COMPLETE','meta.nul'] and all(metadata.get(k)==v for k,v in {'gate':'opponent','round':'27','source':SOURCE,'floor':FLOOR}.items())
            if not result['reservationValid']: result['exit']=1
        after=inventory(ROOT); write('after-inventory.json',after); delta=differences(baseline,after); added=sorted(set(after)-set(baseline))
        own=str(O.relative_to(ROOT))+'/'
        exact={str((R/('r23-state-s66-op27-'+l+'.'+s)).relative_to(ROOT)) for l in ['prereserve','reserved'] for s in ['txt','entries']}|{str((ledger/n).relative_to(ROOT)) for n in ['meta.nul','COMPLETE']}
        unexpected=[p for p in added if not p.startswith(own) and p not in exact]
        external_after=inventory(gd); refs_after=refs(); logical_after=git('for-each-ref','--format=%(objectname) %(refname)')+'\n'
        write('external-git-after.json',external_after); write('refs-after.json',refs_after); (O/'logical-refs-after.txt').write_text(logical_after)
        protected_after={str(p):raw(p) for p in protected}
        ed=differences(external_before,external_after); ea=sorted(set(external_after)-set(external_before)); rd=differences(refs_before,refs_after); ra=sorted(set(refs_after)-set(refs_before))
        logical_before=(O/'logical-refs-before.txt').read_text()
        preservation={'at':utc(),'originalFilesAndSymlinksChecked':len(baseline),'originalFileDifferences':delta,'additions':added,'unexpectedAdditions':unexpected,'externalGitDifferences':ed,'externalGitAdditions':ea,'rawRefsDifferences':rd,'rawRefsAdditions':ra,'logicalRefsUnchanged':logical_before==logical_after,'logicalRefsAdded':sorted(set(logical_after.splitlines())-set(logical_before.splitlines())),'logicalRefsRemoved':sorted(set(logical_before.splitlines())-set(logical_after.splitlines())),'protectedBefore':protected_before,'protectedAfter':protected_after,'protectedUnchanged':protected_before==protected_after and git('rev-parse','HEAD')==HEAD and git('symbolic-ref','HEAD')==boundary['branch'],'allPreexistingWorktreeFilesBytesModesMtimesUnchanged':not delta,'strictGlobalRefsPreserved':refs_before==refs_after and logical_before==logical_after,'strictExternalGitPreserved':external_before==external_after,'historicalStrictPreservation':False,'unknownDifferenceAttribution':'UNKNOWN; no bytes, refs, modes or timestamps restored; no differences hidden or allowlisted.'}
        preservation['reservationWindowStrictPreservationPassed']=not delta and not unexpected and preservation['protectedUnchanged'] and preservation['strictGlobalRefsPreserved'] and preservation['strictExternalGitPreserved']
        write('preservation.json',preservation)
        result.update(protectedUnchanged=preservation['protectedUnchanged'],reservationWindowStrictPreservationPassed=preservation['reservationWindowStrictPreservationPassed'],preexistingDifferenceCount=len(delta),externalGitDifferenceCount=len(ed),rawRefsDifferenceCount=len(rd),rawRefsAdditionCount=len(ra),strictGlobalRefsPreserved=preservation['strictGlobalRefsPreserved'],unexpectedAdditions=unexpected,preservationReceipt=str(O/'preservation.json'))
        if not preservation['reservationWindowStrictPreservationPassed']: result['exit']=1
    except BaseException as exc:
        result.update(exit=1,finalizationError=repr(exc),finalizationTraceback=traceback.format_exc()); print(result['finalizationTraceback'],file=sys.stderr,flush=True)
    result.update(endedAt=utc(),nextStep='Parent independently dispatches genuine MAX OP27 on this same reserved source/floor; seal and tally actual report before any repair. This return supplies no opponent clearance.')
    write('result.json',result); print(json.dumps(result),flush=True)
sys.exit(result['exit'])
