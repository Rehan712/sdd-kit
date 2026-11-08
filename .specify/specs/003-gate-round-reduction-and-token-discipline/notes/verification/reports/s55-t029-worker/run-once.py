exec(compile(open('.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s55-approval/common.py').read(),'common.py','exec'))
assert json.loads((A/'result.json').read_text())['approvalRecorded']
fresh=json.loads((A/'freshness-result.json').read_text());expected=fresh['actualCurrentSource']
for n in ['command.json','command-start.json','stdout.txt','stderr.txt','result.json','worker-return.txt']:
 assert not (W/n).exists(),'Output collision: '+n
proc=processes();save(W/'process-preflight.json',proc);assert not proc['survivingOperations'],proc['survivingOperations'];assert not pending(),pending()
old=json.loads((A/'worktree-after-approval.json').read_text());current=inventory();assert current==old,'Pre-launch original-file mismatch'
status=S/'STATUS.md';assert info(status)==json.loads((A/'result.json').read_text())['statusAfter']
ext=external();approved=json.loads((A/'git-after-approval.json').read_text());assert ext['HEAD']==approved['HEAD'] and ext['branch']==approved['branch'] and ext['files']==approved['files']
# Preserve the donor verifier's established inventory representation.
def donor_info(v):
 d={'mode':oct(v['mode']),'mtime_ns':v['mtimeNs'],'size':v['size'],'type':v['type']}
 for k in ['sha256','target']:
  if k in v:d[k]=v[k]
 return d
save(W/'before-files.json',{p:donor_info(v) for p,v in current.items()})
external_before={p:donor_info(v) for p,v in ext['files'].items() if v is not None}
save(W/'before-git.json',{'HEAD':ext['HEAD'],'branch':ext['branch'],'files':external_before,'refs':ext['refs']})
(W/'status-before.nul').write_bytes(git('status','--porcelain=v1','-z','--untracked-files=all'))
(W/'evidence-before.bin').write_bytes((S/'notes/evidence.md').read_bytes())
(W/'sequence-before.txt').write_bytes((V/'sequence').read_bytes())
seq=int((W/'sequence-before.txt').read_text());assert seq==843,seq
# Re-observe native process and lock state immediately before the sole launch.
proc2=processes();save(W/'process-prelaunch.json',proc2);assert not proc2['survivingOperations'];assert not pending()
receipts={}
for p in [R/'s48-op26-sealing/complete-exit.json',R/'s48-op26-sealing/tally-exit.json',R/'s50-o034-qualified-tools-verification/result.json',R/'s52-o034-accept/result.json']:
 data=json.loads(p.read_text());receipts[str(p)]={'file':info(p),'exit':data.get('exit',data.get('captured_suite_exit')),'ended':data.get('ended',data.get('at')),'nativePid':data.get('nativePid'),'capture':data.get('capture')}
historical_scratch={str(d):sorted(x.name for x in d.iterdir()) for d in V.iterdir() if d.is_dir() and d.name.startswith(('execute.','floor-check.','opponent-readiness.'))}
save(W/'preflight.json',{'observedAt':now(),'cwd':str(P),'expectedCurrentSource':expected,'locksStagingPendingAbsent':True,'noSurvivingNativeOperation':True,'ownedOutputsAbsentBeforeLaunch':True,'sequenceBefore':seq,'originalFiles':len(current),'protectedFilesUnchangedSinceApproval':True,'recentCompletedPidExitReceipts':receipts,'historicalScratchPreserved':historical_scratch,'parentConcurrentWrites':'none authorized or observed','statusTasksIndex':{str(p):info(p) for p in [status,S/'tasks.md',pathlib.Path(git('rev-parse','--git-path','index').decode().strip())]}})
argv=['bash','scripts/spec-run.sh',str(S),'T029','--from-task','--no-tick','--summary']
command={'argv':argv,'cwd':str(P),'environment_policy':'Inherited environment, GIT_OPTIONAL_LOCKS explicitly 0; only execution-relevant nonsecret whitelist recorded.','nonsecret_environment':{k:ENV[k] for k in ['GIT_OPTIONAL_LOCKS','PATH','SHELL','TMPDIR','LANG','LC_ALL','LC_CTYPE','NO_COLOR'] if k in ENV},'expected_source':expected,'attempt':1,'retries':0,'start':now(),'start_time_ns':time.time_ns()}
with (W/'stdout.txt').open('xb') as out,(W/'stderr.txt').open('xb') as err:
 child=subprocess.Popen(argv,cwd=P,env=ENV,stdout=out,stderr=err)
 command['nativePid']=child.pid;save(W/'command-start.json',command)
 (W/'native.pid').write_text(str(child.pid)+'\n')
 code=child.wait()
command.update(end=now(),end_time_ns=time.time_ns(),exit=code)
for name in ['stdout','stderr']:
 b=(W/(name+'.txt')).read_bytes();command[name+'_sha256']=sha(b);command[name+'_bytes']=len(b)
save(W/'command.json',command);(W/'exit.txt').write_text(str(code)+'\n')
print(json.dumps({'nativeExit':code,'pid':child.pid,'ended':command['end'],'stdoutBytes':command['stdout_bytes']}),flush=True)
verify=run(['python3',str(W/'verify.py')],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(W/'verify.stdout').write_bytes(verify.stdout);(W/'verify.stderr').write_bytes(verify.stderr)
print(verify.stdout.decode(),end='',flush=True)
if verify.stderr:print(verify.stderr.decode(),flush=True)
raise SystemExit(verify.returncode)
