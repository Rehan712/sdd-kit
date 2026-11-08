import datetime, hashlib, json, os, pathlib, stat, subprocess, sys, tarfile, time, traceback
ROOT=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline'
V=S/'notes/verification'; R=V/'reports'; O=R/'s46-op26-reservation'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
SOURCE='f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0'
HEAD='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
FLOOR='FLOOR-LxJkv3'
REPORT='862bb96f89392722f86f6063bf560b3de1bf12de431a38fe85227d4a7ae92868'
def utc(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(data): return hashlib.sha256(data).hexdigest()
def write(name,value):
    with (O/name).open('x') as f: json.dump(value,f,indent=2); f.write('\n')
def raw(path):
    st=path.lstat(); result={'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns,'size':st.st_size}
    if stat.S_ISLNK(st.st_mode): result.update(kind='symlink',target=os.readlink(path))
    elif stat.S_ISREG(st.st_mode): result.update(kind='file',sha256=sha(path.read_bytes()))
    else: result.update(kind='other')
    return result
def inventory(base):
    result={}
    for directory,dirs,files in os.walk(base,followlinks=False):
        for name in sorted(dirs+files):
            p=pathlib.Path(directory)/name
            if p.is_symlink() or not p.is_dir(): result[str(p.relative_to(base))]=raw(p)
    return result
def meta(p):
    f=p.read_bytes().split(b'\0'); assert f.pop()==b'' and len(f)%2==0
    return dict(zip((x.decode() for x in f[::2]),(x.decode() for x in f[1::2])))
def git(*args): return subprocess.check_output(['git',*args],cwd=ROOT,env=ENV,text=True).strip()
def state(label):
    lines=(R/('r23-state-'+label+'.txt')).read_text().splitlines()
    return lines[1:]
def activity():
    ps=subprocess.check_output(['ps','-axo','pid,ppid,lstart,command'],cwd=ROOT,env=ENV,text=True)
    relevant=[l for l in ps.splitlines() if any(t in l for t in ['spec-gate.sh','r23-worktree-state.sh','s44-floor-retry/runner.py'])]
    pending=[str(p) for p in (V/'rounds').glob('*/ROUND-*') if not (p/'report.sha256').is_file()]
    staged=[str(p) for p in (V/'rounds').glob('*/.reservation-*')]+[str(p) for p in V.glob('round-check.*')]
    return {'processes':relevant,'pending':pending,'staged':staged,'lockExists':os.path.lexists(V/'lock')}
def assert_inactive(a): assert not any(a.values()),a
def execute(name,argv):
    start=utc(); tick=time.monotonic()
    with (O/(name+'.stdout')).open('xb') as out, (O/(name+'.stderr')).open('xb') as err:
        proc=subprocess.Popen(argv,cwd=ROOT,env=ENV,stdin=subprocess.DEVNULL,stdout=out,stderr=err)
        record={'name':name,'argv':argv,'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':'0','nativePid':proc.pid,'started':start}
        write(name+'.started.json',record); print(json.dumps(record),flush=True)
        rc=proc.wait()
    record.update(exit=rc,ended=utc(),elapsedSeconds=time.monotonic()-tick)
    write(name+'.completed.json',record); steps.append(record); print(json.dumps(record),flush=True)
    assert rc==0,record
    return rc
steps=[]; result={'started':utc(),'runnerPid':os.getpid(),'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':ENV['GIT_OPTIONAL_LOCKS'],'source':SOURCE,'floor':FLOOR,'gate':'opponent','round':26,'steps':steps,'reservationCreated':False,'independentReviewStarted':False,'formalClearance':False,'historicalFullPreservationPassed':False,'deviation':'Initial read-only pwd tool call had explicit cwd but omitted explicit GIT_OPTIONAL_LOCKS; every subsequent shell and child command sets it to 0.'}
try:
    assert pathlib.Path.cwd()==ROOT and os.environ['GIT_OPTIONAL_LOCKS']=='0'
    assert sha(b'')=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    assert set(meta(V/'floors'/FLOOR/'meta.nul'))=={'version','id','kind','stage','start','end','source','exit'}
    initial_activity=activity(); write('activity-before.json',initial_activity); assert_inactive(initial_activity)
    assert not os.path.lexists(V/'rounds/opponent/ROUND-26')
    for label in ['s46-op26-prereserve','s46-op26-reserved']:
        for suffix in ['txt','entries']: assert not os.path.lexists(R/('r23-state-'+label+'.'+suffix))
    assert git('rev-parse','HEAD')==HEAD
    gd=pathlib.Path(git('rev-parse','--absolute-git-dir')); common=pathlib.Path(git('rev-parse','--git-common-dir')).resolve()
    protected=[gd/'HEAD',gd/'index',ROOT/'.git',S/'STATUS.md',S/'tasks.md']
    before_protected={str(p):raw(p) for p in protected}
    assert before_protected[str(gd/'index')]['sha256']=='c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700'
    assert before_protected[str(gd/'index')]['mode']==0o644 and before_protected[str(gd/'index')]['mtimeNs']==1792957592613445716
    assert before_protected[str(S/'STATUS.md')]['sha256']=='569eba99f2f1860ccb083c72f88e3a1cc21ce49be31547d5ce34cc75f1415099'
    assert before_protected[str(S/'tasks.md')]['sha256']=='3d0b827856d89b6b1ae08b096dd5277920375f26f5fc1c97cc3e45f1f569b3d7'
    assert all(before_protected[str(S/x)]['mode']==0o600 for x in ['STATUS.md','tasks.md'])
    approval=json.loads((R/'s34-approval/approval.json').read_text())
    assert approval['actualUserAnswer']=='Approve opponent round 26 after completed round 25'
    status=(S/'STATUS.md').read_text()
    assert '2026-10-28T09:02:49Z — waiver: gate=opponent; round=26; after=25; by=user;' in status
    assert approval['actualUserAnswer'] in status
    op25=V/'rounds/opponent/ROUND-25'
    assert (op25/'report.sha256').read_text().strip()==REPORT
    assert sha((R/'opponent-round25.md').read_bytes())==REPORT and 'CHALLENGED' in (R/'opponent-round25.md').read_text()
    assert (op25/'COMPLETE').read_text()=='verification:1\n'+sha((op25/'meta.nul').read_bytes())+' meta.nul\n'
    completion=json.loads((R/'s33-op25-sealing/result.json').read_text())
    assert completion['completed'] and completion['exit']==0 and completion['verdict']=='CHALLENGED'
    assert completion['ended']<approval['recordedAt']
    assert (V/'floor-latest').read_text().strip()==FLOOR
    fm=meta(V/'floors'/FLOOR/'meta.nul'); assert fm['source']==SOURCE and fm['id']==FLOOR and fm['exit']=='0'
    parent=json.loads((O/'parent-floor-verification.json').read_text())
    assert parent['source']==SOURCE and parent['floor']==FLOOR
    for name,digest in parent['sealHashesRechecked'].items(): assert sha((V/'floors'/FLOOR/name).read_bytes())==digest
    prior=json.loads((R/'s45-floor-execution/result.json').read_text()); exceptions=json.loads((R/'s45-floor-execution/preservation-exceptions.json').read_text())
    assert prior['actualFloorExit']==0 and prior['actualWrapperExit']==0 and prior['newFloorId']==FLOOR
    assert prior['sourceManifestsByteIdentical'] and not exceptions['fullPreservationPassed']
    write('preflight.json',{'at':utc(),'passed':True,'activity':initial_activity,'floorMetadata':fm,'approval':approval['actualUserAnswer'],'OP25Completed':completion['ended'],'OP25ReportSha256':REPORT,'protected':before_protected,'extraFloorValidatorInvoked':False})
    with tarfile.open(O/'protected-originals.tar','x') as archive:
        for i,p in enumerate(protected): archive.add(p,arcname=str(i)+'-'+p.name,recursive=False)
    baseline=inventory(ROOT); write('baseline-inventory.json',baseline)
    def refs():
        r=inventory(common/'refs')
        for n in ['HEAD','packed-refs']:
            if (common/n).exists(): r['@'+n]=raw(common/n)
        return r
    refs_before=refs(); write('refs-before.json',refs_before)
    assert_inactive(activity())
    execute('prereserve',['bash',str(R/'r23-worktree-state.sh'),'s46-op26-prereserve'])
    pre=state('s46-op26-prereserve'); assert 'source='+SOURCE in pre and 'head='+HEAD in pre
    assert {str(p):raw(p) for p in protected}==before_protected
    assert_inactive(activity())
    execute('reserve',['bash','scripts/spec-gate.sh','round',str(S.relative_to(ROOT)),'opponent','--floor',FLOOR])
    result['reservationCreated']=(V/'rounds/opponent/ROUND-26').is_dir()
    execute('reserved',['bash',str(R/'r23-worktree-state.sh'),'s46-op26-reserved'])
    a=(R/'r23-state-s46-op26-prereserve.entries').read_bytes(); b=(R/'r23-state-s46-op26-reserved.entries').read_bytes()
    ledger=V/'rounds/opponent/ROUND-26'; metadata=meta(ledger/'meta.nul')
    result.update(metadata=metadata,entriesByteIdentical=a==b,entriesSha256=sha(a),entryCount=len(a.splitlines()),stateFieldsMatch=pre==state('s46-op26-reserved'),pendingWithoutFinalReport=not (ledger/'report.sha256').exists())
    assert a==b and result['stateFieldsMatch']
    assert all(metadata[k]==v for k,v in {'gate':'opponent','round':'26','source':SOURCE,'floor':FLOOR}.items())
    assert (ledger/'COMPLETE').read_text()=='verification:1\n'+sha((ledger/'meta.nul').read_bytes())+' meta.nul\n'
    assert set(p.name for p in ledger.iterdir())=={'meta.nul','COMPLETE'}
    result['exit']=0
except BaseException as exc:
    result.update(exit=1,error=repr(exc),traceback=traceback.format_exc())
    print(result['traceback'],file=sys.stderr,flush=True)
finally:
    if 'baseline' in globals():
        after=inventory(ROOT); write('after-inventory.json',after)
        differences={p:{'before':v,'after':after.get(p)} for p,v in baseline.items() if after.get(p)!=v}
        additions=sorted(set(after)-set(baseline))
        def allowed(p):
            return p.startswith(str(O.relative_to(ROOT))+'/') or p==str((R/'s46-op26-reservation-invocation.json').relative_to(ROOT)) or p in [str((R/('r23-state-s46-op26-'+label+'.'+suffix)).relative_to(ROOT)) for label in ['prereserve','reserved'] for suffix in ['txt','entries']] or p in [str((V/'rounds/opponent/ROUND-26'/name).relative_to(ROOT)) for name in ['meta.nul','COMPLETE']]
        unexpected=[p for p in additions if not allowed(p)]
        after_protected={str(p):raw(p) for p in protected}
        refs_after=refs(); write('refs-after.json',refs_after)
        preservation={'at':utc(),'preexistingEntriesChecked':len(baseline),'preexistingDifferences':differences,'additions':additions,'unexpectedAdditions':unexpected,'protectedBefore':before_protected,'protectedAfter':after_protected,'protectedUnchanged':before_protected==after_protected and git('rev-parse','HEAD')==HEAD,'globalRefsUnchanged':refs_before==refs_after,'reservationWindowPreservationPassed':not differences and not unexpected and refs_before==refs_after,'historicalFullPreservationPassed':False,'historicalExceptionsRetained':str(R/'s45-floor-execution/preservation-exceptions.json')}
        write('preservation.json',preservation)
        result.update(protectedUnchanged=preservation['protectedUnchanged'],reservationWindowPreservationPassed=preservation['reservationWindowPreservationPassed'],preexistingDifferenceCount=len(differences),unexpectedAdditions=unexpected)
        if not preservation['reservationWindowPreservationPassed'] or not preservation['protectedUnchanged']: result['exit']=1
    result.update(ended=utc(),reservationInvocations=sum(x['name']=='reserve' for x in steps),automaticRetries=0,completedOrTallied=False)
    write('result.json',result); print(json.dumps(result),flush=True)
sys.exit(result['exit'])
