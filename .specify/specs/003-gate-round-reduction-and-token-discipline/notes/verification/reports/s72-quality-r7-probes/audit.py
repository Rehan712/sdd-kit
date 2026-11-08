from pathlib import Path
import os,json,hashlib,stat,difflib,re,shlex
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline'
R=S/'notes/verification/reports'
OWN=R/'s72-quality-r7-probes'
assert os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
def sha(b):return hashlib.sha256(b).hexdigest()
def write(name,data):
 with (OWN/name).open('x') as f:f.write(data)
def save(name,obj):write(name,json.dumps(obj,indent=2,sort_keys=True)+'\n')
scope=json.loads((R/'s72-quality-r7-scope.json').read_text())
files={}
for rel,want in scope['files'].items():
 p=ROOT/rel;s=p.stat()
 got={'sha256':sha(p.read_bytes()),'mode':stat.S_IMODE(s.st_mode),'mtimeNs':s.st_mtime_ns,'bytes':s.st_size}
 files[rel]={'actual':got,'expected':want,'matches':got==want}
relpaths=['scripts/sdd-analyze.sh','tests/test-sdd-analyze.sh',str((S/'tasks.md').relative_to(ROOT))]
diffchecks={}
for name,oldroot,label,paths in [
 ('current',R/'s28-o034-fix/before-live-application','C7-original',relpaths),
 ('latest',R/'s69-o034-option-order-fix/before','before-OP27-repair',relpaths+[str((S/'STATUS.md').relative_to(ROOT))])
]:
 text=''.join(''.join(difflib.unified_diff((oldroot/p).read_text().splitlines(True),(ROOT/p).read_text().splitlines(True),fromfile=label+'/'+p,tofile=p)) for p in paths)
 write(name+'-recomputed.diff',text)
 supplied=(R/('s72-quality-r7-'+name+'.diff')).read_bytes()
 diffchecks[name]={'reconstructedSHA256':sha(text.encode()),'suppliedSHA256':sha(supplied),'literalMatch':text.encode()==supplied}
def lists(path):
 body=path.read_text().split('  # O-034: simple Bash',1)[1].split('  # AC-023:',1)[0]
 headers=[(var,shlex.split(values.replace('\\\n',''))) for var,values in re.findall(r'for ([a-z]+) in (.*?); do',body,re.S)]
 current=len(headers)==17
 assert len(headers) in [15,17]
 h=[values for _,values in headers]
 redirects=[p+t+r+' old new' for t in h[0] for p in h[1] for r in h[2]]
 redirects += [f.replace('REDIRECT',spacing+r) for r in h[3] for spacing in h[4] for f in h[5]]
 runners=[f.replace('REDIRECT',spacing+r) for r in h[3] for spacing in h[4] for f in h[6]]
 qualified=[]
 for p in h[7]:
  qualified += [p+f for f in h[8]]
  if current:qualified += [p+f.replace('REDIRECT',r) for r in h[9] for f in h[10]]
 shift=2 if current else 0
 qrunners=[p+f for p in h[7] for f in h[9+shift]]
 qualified += [f.replace('REDIRECT',r) for r in h[10+shift] for f in h[11+shift]]
 qrunners += [f.replace('REDIRECT',r) for r in h[10+shift] for f in h[12+shift]]
 assert h[13+shift][-2:]==['$'+'{weak_redirect_cases[@]}','$'+'{weak_qualified_cases[@]}']
 assert h[14+shift][-2:]==['$'+'{runner_redirect_cases[@]}','$'+'{runner_qualified_cases[@]}']
 weak=h[13+shift][:-2]+redirects+qualified
 clean=h[14+shift][:-2]+runners+qrunners
 return {'weak':weak,'clean':clean,'weakRedirects':len(redirects),'weakQualified':len(qualified),'runnerRedirects':len(runners),'runnerQualified':len(qrunners),'literalWeak':len(h[13+shift])-2,'literalClean':len(h[14+shift])-2,'headerTokenCounts':[(v,len(vals)) for v,vals in headers]}
before=lists(R/'s69-o034-option-order-fix/before/tests/test-sdd-analyze.sh')
current=lists(ROOT/'tests/test-sdd-analyze.sh')
def subseq(old,new):
 it=iter(new);return all(any(x==v for x in it) for v in old)
countchecks={'beforeWeak':len(before['weak']),'currentWeak':len(current['weak']),'beforeClean':len(before['clean']),'currentClean':len(current['clean']),'weakAdded':len(current['weak'])-len(before['weak']),'cleanAdded':len(current['clean'])-len(before['clean']),'priorWeakOrderedSubsequence':subseq(before['weak'],current['weak']),'priorCleanOrderedSubsequence':subseq(before['clean'],current['clean']),'explicitKinds':sorted(set(re.findall(r'\*Verify kind:\* ([a-z]+)',(ROOT/'tests/helpers.sh').read_text().split('make_verification_spec_dir() {',1)[1].split('make_verification_git_dir()',1)[0])))}
save('test-declarations.json',{'before':before,'current':current,'checks':countchecks})
def seal(d,expected):
 lines=(d/'COMPLETE').read_text().splitlines();assert lines[0]=='verification:1'
 members={}
 for line in lines[1:]:
  digest,name=line.split(' ',1)
  members[name]={'recorded':digest,'actual':sha((d/name).read_bytes())}
 return {'memberCount':len(members),'expectedCount':expected,'members':members,'valid':len(members)==expected and all(m['recorded']==m['actual'] for m in members.values()),'completeSHA256':sha((d/'COMPLETE').read_bytes())}
capture=S/'notes/captures/CAP-866-eXyQTW'
accepted=S/'notes/verification/accepted/T031a5o1/ACC-0HVJw8'
event=S/'notes/verification/accept-events/ACCEPT-ouC5Ma'
seals={'capture':seal(capture,7),'accepted':seal(accepted,4),'event':seal(event,1)}
def nulmeta(p):
 a=p.read_bytes().split(b'\0');assert a[-1]==b'';a=a[:-1];assert len(a)%2==0
 return {k.decode():v.decode() for k,v in zip(a[::2],a[1::2])}
cm=nulmeta(capture/'meta.nul');am=nulmeta(accepted/'meta.nul')
source=sha((capture/'inputs.nul').read_bytes())
checks={'captureSource':source==scope['source'],'sameInputBytes':(capture/'inputs.nul').read_bytes()==(capture/'inputs-after.nul').read_bytes()==(R/'s71-option-order-accept/inputs-after.nul').read_bytes(),'metaSameSource':cm['input_before']==cm['input_after']==am['input']==source,'captureExitNoTick':cm['exit']=='0' and cm['no_tick']=='1','outputDigestMatches':sha((capture/'output.log').read_bytes())==cm['output_digest'],'nineteenPassingFunctions':len(re.findall(rb'^  ok   test_', (capture/'output.log').read_bytes(),re.M))==19 and (capture/'output.log').read_bytes().endswith(b'  -- 19/19 passed\n'),'currentTasksEqualAcceptedAfter':(S/'tasks.md').read_bytes()==(accepted/'tasks.after').read_bytes(),'committedBindsComplete':(accepted/'COMMITTED').read_text().strip()==seals['accepted']['completeSHA256'],'actualCanonicalSealedReturnIdentical':(R/'s71-option-order-accept/actual-worker-return.txt').read_bytes()==(R/'s71-option-order-accept/returned.txt').read_bytes()==(accepted/'return.txt').read_bytes(),'returnHashMatches':sha((accepted/'return.txt').read_bytes())==am['return_digest']}
runtime_raw=json.loads((OWN/'runtime.json').read_text())
runtime=None
for content in runtime_raw.get('content',[]):
 if content.get('type')=='text':
  try:d=json.loads(content['text'])
  except ValueError:continue
  if 'modelSelection' in d:runtime=d
assert runtime is not None
sel=runtime['modelSelection'];options={x['id']:x['value'] for x in sel['options']}
runtime_check={'instanceId':sel.get('instanceId'),'model':sel['model'],'reasoningEffort':options.get('reasoningEffort'),'serviceTier':options.get('serviceTier'),'requestedMatch':sel.get('instanceId')=='codex' and sel['model']=='gpt-6.1-sol' and options.get('reasoningEffort')=='max' and options.get('serviceTier')=='default','callArguments':{}}
gitdir=ROOT.joinpath((ROOT/'.git').read_text().strip().split(': ',1)[1]).resolve()
common=(gitdir/(gitdir/'commondir').read_text().strip()).resolve()
head=(gitdir/'HEAD').read_text().strip();ref=head.split(': ',1)[1]
head_sha=(common/ref).read_text().strip() if (common/ref).exists() else next(line.split(' ')[0] for line in (common/'packed-refs').read_text().splitlines() if line.endswith(' '+ref))
idx=gitdir/'index';st=idx.stat()
result={'source':source,'rawScopeFiles':files,'diffs':diffchecks,'declarationChecks':countchecks,'seals':seals,'evidenceChecks':checks,'runtime':runtime_check,'head':head_sha,'branchRef':ref,'realIndex':{'sha256':sha(idx.read_bytes()),'mode':stat.S_IMODE(st.st_mode),'mtimeNs':st.st_mtime_ns},'allChecks':all(v['matches'] for v in files.values()) and all(v['literalMatch'] for v in diffchecks.values()) and all(v['valid'] for v in seals.values()) and all(checks.values()) and runtime_check['requestedMatch'] and countchecks['priorWeakOrderedSubsequence'] and countchecks['priorCleanOrderedSubsequence'] and head_sha==scope['HEAD'] and sha(idx.read_bytes())==scope['realIndexSHA256']}
save('scope-and-evidence-audit.json',result)
print(json.dumps({'allChecks':result['allChecks'],'source':source,'diffs':diffchecks,'declarations':countchecks,'runtime':runtime_check,'evidenceChecks':checks,'sealMemberCounts':{k:v['memberCount'] for k,v in seals.items()},'head':head_sha,'realIndex':result['realIndex']}))
