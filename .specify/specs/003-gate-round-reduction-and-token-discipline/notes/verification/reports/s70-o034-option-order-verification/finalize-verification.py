import os,stat,json,hashlib,subprocess,datetime,re
from pathlib import Path
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==root
s=root/'.specify/specs/003-gate-round-reduction-and-token-discipline';v=s/'notes/verification';o=v/'reports/s70-o034-option-order-verification';env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def sha(b):return hashlib.sha256(b).hexdigest()
def entry(p):
 st=p.lstat();d={'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns,'type':'dir' if stat.S_ISDIR(st.st_mode) else 'symlink' if stat.S_ISLNK(st.st_mode) else 'file','size':st.st_size}
 if d['type']=='file':d['sha256']=sha(p.read_bytes())
 elif d['type']=='symlink':d['target']=os.readlink(p)
 return d
def tree(base):
 d={str(base):entry(base)}
 for cur,dirs,files in os.walk(base,followlinks=False):
  for name in dirs+files:
   p=Path(cur)/name;d[str(p)]=entry(p)
 return d
def save(name,d):(o/name).write_text(json.dumps(d,indent=2)+'\n')
native=json.load(open(o/'native-result.json'));cap=(o/'actual-capture.txt').read_text().strip();d=s/'notes/captures'/cap
members=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt'];ledger=v/'captures'/cap
fields=(d/'meta.nul').read_bytes().split(b'\0');assert fields.pop()==b'' and len(fields)%2==0
meta={fields[i].decode():fields[i+1].decode() for i in range(0,len(fields),2)}
rawsummary=(d/'summary.txt').read_bytes();output=(d/'output.log').read_bytes();before=(o/'source-before.txt').read_text().strip();after=(o/'source-after.txt').read_text().strip()
complete=b'verification:1\n'+b''.join((sha((d/name).read_bytes())+' '+name+'\n').encode() for name in members)
checks={
 'nativeExitZero':native['nativeExit']==0,
 'nativeExactArgv':native['argv']==['bash','scripts/spec-run.sh',str(s.relative_to(root)),'T031a5o1','--from-task','--no-tick','--summary'],
 'nativeCwd':native['cwd']==str(root),
 'nativeOptionalLocksZero':native['env']['GIT_OPTIONAL_LOCKS']=='0',
 'oneNativeInvocationNoRetry':native['attempt']==1 and native['automaticRetries']==0,
 'nativeSummaryExact':(o/'native.stdout').read_bytes()==rawsummary,
 'summaryOneFullLineTerminalLF':rawsummary.endswith(b'\n') and rawsummary.count(b'\n')==1 and b'\r' not in rawsummary,
 'captureExitZero':meta['exit']=='0',
 'noTickOne':meta['no_tick']=='1',
 'captureIdSequence':meta['id']==cap and meta['sequence']=='866' and cap.startswith('CAP-866-'),
 'sequenceIncrementedOnce':(v/'sequence').read_bytes()==b'866\n',
 'captureCwdRepo':meta['cwd']==str(root) and meta['repo']==str(root),
 'captureExactTaskArgv':(d/'argv.nul').read_bytes()==(meta['shell']+'\0-o\0pipefail\0-c\0bash tests/test-sdd-analyze.sh\0').encode(),
 'inputBeforeAfterActualNewSource':meta['input_before']==meta['input_after']==before==after and before not in ['7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff'],
 'inputManifestHashes':sha((d/'inputs.nul').read_bytes())==meta['input_before'] and sha((d/'inputs-after.nul').read_bytes())==meta['input_after'],
 'freshIndependentManifestBytes':(o/'inputs-before.nul').read_bytes()==(d/'inputs.nul').read_bytes()==(d/'inputs-after.nul').read_bytes()==(o/'inputs-after.nul').read_bytes(),
 'freshIndependentBindingBytes':(o/'bindings-before.nul').read_bytes()==(d/'bindings.nul').read_bytes()==(o/'bindings-after.nul').read_bytes(),
 'outputDigestAndBytes':sha(output)==meta['output_digest'] and str(len(output))==meta['output_bytes'],
 'completeRehashSevenMembers':(d/'COMPLETE').read_bytes()==complete,
 'ledgerRehashMatchesComplete':ledger.read_bytes()==complete,
 'kernelBeforeExitZero':json.load(open(o/'kernel-before-result.json'))['exit']==0,
 'kernelAfterExitZero':json.load(open(o/'kernel-after-result.json'))['exit']==0,
 'kernelCaptureCurrentExitZero':(o/'capture-current.exit').read_bytes()==b'0\n',
 'kernelTaskCaptureMatchesExitZero':(o/'task-capture-matches.exit').read_bytes()==b'0\n',
 'taskCommandUnchanged':(o/'task-command-before.txt').read_bytes()==(o/'task-command-after.txt').read_bytes()==b'bash tests/test-sdd-analyze.sh\n',
 'lockAbsent':not (v/'lock').exists()
}
rows=(o/'bindings-after.nul').read_bytes().split(b'\0');assert rows.pop()==b'' and len(rows)%12==0
rows=[[x.decode() for x in rows[i:i+12]] for i in range(0,len(rows),12)]
loc='tests/test-sdd-analyze.sh::test_verification_bindings';bound=[r for r in rows if r[0]=='binding' and r[2]=='T031a5o1']
checks['FM001INV005ExactTestLocator']=all(len([r for r in bound if r[1]==f and r[7]==loc])==1 for f in ['FM-001','INV-005'])
suites=[line for line in output.decode().splitlines() if re.match(r'^\s+ok\s+test_',line)]
checks['nineteenSuitePasses']=len(suites)==19 and not re.search(rb'^\s*(FAIL|not ok)\b',output,re.M) and bool(re.search(rb'19 passed',output))
old=json.load(open(o/'original-worktree-boundary.json'));oldgit=json.load(open(o/'original-git-boundary.json'));now=tree(root);nowgit=tree(Path('/Users/babar/projects/sdd-kit-public/.git'))
mutations={str(v/'sequence'),str(s/'notes/evidence.md')}
parentdirs={str(o.parent),str(v),str(v/'captures'),str(s/'notes/captures')}
changes=[];unexpected=[];missing=[]
for p,b in old.items():
 if p not in now:missing.append(p);continue
 a=now[p]
 if a==b:continue
 expected=(p in mutations and a['type']==b['type']=='file' and a['mode']==b['mode']) or (p in parentdirs and a['type']==b['type']=='dir' and a['mode']==b['mode'])
 item={'path':p,'before':b,'after':a,'expectedExactNativeOrOwnedMutation':expected};changes.append(item)
 if not expected:unexpected.append(item)
allowednew={str(d)}|{str(d/name) for name in members+['COMPLETE']}|{str(ledger)}
newpaths=[p for p in now if p not in old]
unexpectednew=[p for p in newpaths if p!=str(o) and not p.startswith(str(o)+'/') and p not in allowednew]
gitchanges=[{'path':p,'before':b,'after':nowgit.get(p)} for p,b in oldgit.items() if nowgit.get(p)!=b];gitnew=[p for p in nowgit if p not in oldgit]
head=subprocess.run(['git','rev-parse','HEAD'],cwd=root,env=env,capture_output=True);refs=subprocess.run(['git','show-ref','--head'],cwd=root,env=env,capture_output=True)
(o/'HEAD-after.raw').write_bytes(head.stdout);(o/'refs-after.raw').write_bytes(refs.stdout)
index='/Users/babar/projects/sdd-kit-public/.git/worktrees/003-gate-round-reduction-and-token-discipline/index';githead='/Users/babar/projects/sdd-kit-public/.git/worktrees/003-gate-round-reduction-and-token-discipline/HEAD'
core=json.load(open(o/'protected-core-before.json'));checks['protectedCoreBytesModesMtimesUnchanged']=all(now.get(str(root/p))==b for p,b in core.items())
checks['realIndexBytesModeMtimeUnchanged']=nowgit.get(index)==oldgit[index]
checks['realHeadBytesModeMtimeUnchanged']=nowgit.get(githead)==oldgit[githead] and head.returncode==0 and head.stdout==(o/'HEAD-before.raw').read_bytes()
checks['rawTasksStatusUnchanged']=all((s/name).read_bytes()==(o/('before-'+name)).read_bytes() for name in ['tasks.md','STATUS.md'])
tasklines=[line for line in (s/'tasks.md').read_text().splitlines() if '**T031a5o1**' in line];checks['sameTaskUnchecked']=len(tasklines)==1 and '[ ]' in tasklines[0]
oldEvidence=(o/'before-evidence.md').read_bytes();actualEvidence=(s/'notes/evidence.md').read_bytes();append=(f'\n## {cap} — {meta["end"]}\n\nCaptured run, exit {meta["exit"]}. Full log: `notes/captures/{cap}/output.log`.\n\n').encode()+rawsummary
checks['evidenceOnlyOneExactNativeAppend']=actualEvidence==oldEvidence+append
checks['onlyExactNewNativeCaptureAndLedger']=not unexpectednew
protection={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'originalEntryCount':len(old),'originalGitEntryCount':len(oldgit),'changedOriginalWorktreeEntries':changes,'unexpectedOriginalChanges':unexpected,'missingOriginalEntries':missing,'unexpectedAdditions':unexpectednew,'globalGitChangesUnknownActor':gitchanges,'globalGitAdditionsUnknownActor':gitnew,'rawRefsUnchanged':refs.returncode==0 and refs.stdout==(o/'refs-before.raw').read_bytes(),'allOriginalFilesOutsideExactNativeMutationsPreserved':not missing and not [x for x in unexpected if x['before']['type']!='dir'],'strictPreservation':not unexpected and not missing and not unexpectednew and not gitchanges and not gitnew,'historicalStrictPreservation':False,'unknownChangesRestored':False,'unknownChangesAttributed':False,'expectedDirectoryChangesOnlyAt':sorted(parentdirs)}
save('protection-after.json',protection)
save('capture-rehash.json',{'capture':cap,'metadata':meta,'members':{name:{'sha256':sha((d/name).read_bytes()),'bytes':(d/name).stat().st_size} for name in members+['COMPLETE']},'ledger':{'sha256':sha(ledger.read_bytes()),'bytes':ledger.stat().st_size},'outputSuitePassLines':suites,'outputBytes':len(output),'outputSHA256':sha(output),'bindingRows':bound})
result={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'task':'T031a5o1','capture':cap,'actualNewSource':before,'nativeExit':native['nativeExit'],'no_tick':meta['no_tick'],'checks':checks,'verified':all(checks.values()),'strictPreservation':protection['strictPreservation'],'historicalStrictPreservation':False,'unknownGlobalChanges':len(gitchanges)+len(gitnew),'unknownWorktreeChanges':len(unexpected)+len(missing)+len(unexpectednew),'qualityVerdict':None,'accepted':False,'ticked':False,'OP28Started':False}
save('result.json',result)
if result['verified']:
 body='Verification-Return: 1\nTask: T031a5o1\nCaptures: '+cap+'\nSummary: '+rawsummary.decode().rstrip('\n')+'\nFailure modes:\nFM-001, '+loc+', '+cap+'\nINV-005, '+loc+', '+cap+'\n'
 assert body.endswith('\n') and not body.endswith('\n\n')
 with (o/'worker-return.txt').open('x') as f:f.write(body)
 save('worker-return-receipt.json',{'sha256':sha(body.encode()),'bytes':len(body.encode()),'oneTerminalLF':True,'capture':cap,'source':before,'actualSummaryBytesUnmodified':body.split('Summary: ',1)[1].split('\nFailure modes:',1)[0].encode()+b'\n'==rawsummary,'accepted':False,'ticked':False})
print(json.dumps(result,indent=2));print('PROTECTION',json.dumps({'unexpectedOriginalChanges':unexpected,'missing':missing,'unexpectedAdditions':unexpectednew,'gitChanges':gitchanges,'gitNew':gitnew}))
if not result['verified']:raise SystemExit(1)
