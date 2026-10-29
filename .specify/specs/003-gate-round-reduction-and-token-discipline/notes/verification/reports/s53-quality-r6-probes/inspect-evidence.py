from pathlib import Path
import collections,difflib,hashlib,json,os,re,stat,subprocess,tempfile
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline';R=S/'notes/verification/reports';P=R/'s53-quality-r6-probes';V=S/'notes/verification'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0',LC_ALL='C')
for key in ['BASH_ENV','ENV','CDPATH']:ENV.pop(key,None)
TMP=Path(tempfile.mkdtemp(prefix='sdd-r6-evidence-',dir='/tmp')).resolve()
def sha(b):return hashlib.sha256(b).hexdigest()
def save(path,b):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb') as f:f.write(b)
def emit(name,d):save(P/name,(json.dumps(d,indent=2)+'\n').encode())
def readj(name):return json.loads((R/name).read_text())
def fields(path):
 b=path.read_bytes();assert b.endswith(b'\0');return [x.decode() for x in b[:-1].split(b'\0')]
def pairs(path):
 f=fields(path);assert len(f)%2==0;assert len(set(f[::2]))==len(f)//2;return dict(zip(f[::2],f[1::2]))
def rows(path,n):
 f=fields(path);assert len(f)%n==0;return [f[i:i+n] for i in range(0,len(f),n)]
def seal(folder,expected):
 lines=(folder/'COMPLETE').read_text().splitlines();assert lines.pop(0)=='verification:1'
 out=[]
 for line in lines:
  digest,name=line.split(' ',1);assert name in expected;observed=sha((folder/name).read_bytes());assert observed==digest
  out.append({'file':name,'sha256':observed})
 assert [x['file'] for x in out]==expected;return out
checks={};commands=[]
# Full repair and latest delta are independently regenerated from the archived bytes.
paths=['scripts/sdd-analyze.sh','tests/test-sdd-analyze.sh',str((S/'tasks.md').relative_to(ROOT))]
regenerated={}
for label,archive,before in [('current','s28-o034-fix/before-live-application','C7'),('latest','s49-o034-qualified-tools-fix/before','before-OP26-repair')]:
 diff=''.join(''.join(difflib.unified_diff((R/archive/rel).read_text().splitlines(keepends=True),(ROOT/rel).read_text().splitlines(keepends=True),fromfile=before+'/'+rel,tofile='current/'+rel)) for rel in paths)
 save(P/('independent-'+label+'.diff'),diff.encode());given=(R/('s53-quality-r6-'+label+'.diff')).read_bytes()
 checks[label+'_diff_byte_match']=given==diff.encode();regenerated[label]={'sha256':sha(diff.encode()),'given_sha256':sha(given),'byte_match':given==diff.encode()}
 checks[label+'_diff_byte_match'] or (_ for _ in ()).throw(AssertionError('diff mismatch'))
insert='''    # A known tool keeps its meaning under a test-looking executable path.
    if (low ~ /^([^[:space:]<>&|;()]*\\/)?(tsc|npm|pnpm|yarn|bun|go|make|cargo|test)([[:space:]<>&|;()]|$)/)
      sub(/^[^[:space:]<>&|;()]*\\//, "", low)
'''
now=(ROOT/'scripts/sdd-analyze.sh').read_text();old=(R/'s49-o034-qualified-tools-fix/before/scripts/sdd-analyze.sh').read_text()
checks['latest_classifier_exactly_three_line_insertion']=now.count(insert)==1 and now.replace(insert,'',1)==old
assert checks['latest_classifier_exactly_three_line_insertion']
# Rehash the stored source manifest, every current path through the actual content reader, and all tool/harness rows.
inputs=P/'source-after-accept.nul';inputsha=sha(inputs.read_bytes());assert inputsha=='3e70d8170d98f13c04f550c15942f70bdb487abf30ad629ff78db2048f077497'
manifest=rows(inputs,6);pr=[r for r in manifest if r[0]=='path'];assert len(pr)==177
listfile=P/'manifest-read-paths.nul';save(listfile,b''.join(r[1].encode()+b'\0' for r in pr))
script='''set -u
. scripts/lib.sh
. scripts/verification-lib.sh
n=0
while IFS= read -r -d '' path; do
  n=$((n+1))
  vf_path_content "$1" "$path" "$2/path-$n" || exit 3
done < "$3"
'''
save(P/'read-manifest-content.sh',script.encode())
argv=['/bin/bash',str(P/'read-manifest-content.sh'),str(ROOT),str(TMP),str(listfile)]
proc=subprocess.run(argv,cwd=ROOT,env=ENV,capture_output=True);save(P/'manifest-content.stdout',proc.stdout);save(P/'manifest-content.stderr',proc.stderr)
commands.append({'label':'read-manifest-content','argv':argv,'cwd':str(ROOT),'GIT_OPTIONAL_LOCKS':'0','exit':proc.returncode,'stdout_sha256':sha(proc.stdout),'stderr_sha256':sha(proc.stderr),'mutates_source':False})
assert proc.returncode==0 and not proc.stderr
pathproof=[]
for i,row in enumerate(pr,1):
 path=ROOT/row[1];b=(TMP/f'path-{i}').read_bytes();mode='120000' if path.is_symlink() else ('100755' if os.access(path,os.X_OK) else '100644')
 assert sha(b)==row[4] and mode==row[3]
 if path.is_symlink():assert row[2]=='link' and os.readlink(path)==row[5]
 else:assert row[2]=='file'
 pathproof.append({'path':row[1],'content_sha256':sha(b),'mode':mode,'matches':True})
for row in manifest:
 if row[0]=='tool':assert sha(Path(row[2]).read_bytes())==row[3]
 if row[0]=='harness':assert sha(Path(row[1]).read_bytes())==row[2]
 if row[0]=='document':assert next(x for x in pathproof if ROOT/x['path']==Path(row[1]))['content_sha256']==row[2]
checks['all_177_current_paths_modes_tools_harness_documents_match']=True
cap=S/'notes/captures/CAP-843-YAhBBt';members=seal(cap,['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']);meta=pairs(cap/'meta.nul')
assert (V/'captures/CAP-843-YAhBBt').read_bytes()==(cap/'COMPLETE').read_bytes()
assert (cap/'inputs.nul').read_bytes()==inputs.read_bytes()==(cap/'inputs-after.nul').read_bytes()
assert meta['input_before']==meta['input_after']==inputsha and meta['no_tick']=='1' and meta['exit']=='0'
assert fields(cap/'argv.nul')==['/bin/bash','-o','pipefail','-c','bash tests/test-sdd-analyze.sh']
log=(cap/'output.log').read_bytes();assert sha(log)==meta['output_digest'] and len(log)==int(meta['output_bytes'])
assert b'  -- 19/19 passed\n' in log and b'  ok   test_verification_bindings\n' in log and b'FAIL' not in log
bindings=rows(cap/'bindings.nul',12);binding=[r for r in bindings if r[0]=='binding' and r[2]=='T031a5o1'];assert {(r[1],r[5],r[7]) for r in binding}=={('FM-001','test','tests/test-sdd-analyze.sh::test_verification_bindings'),('INV-005','test','tests/test-sdd-analyze.sh::test_verification_bindings')}
assert sha((cap/'bindings.nul').read_bytes())=='8766df908be5d8f628c3880af34ae761dd1c9c4946e8da08da3e566c8c0c788a'
checks['capture_seven_member_seal_ledger_identity_log_bindings']=True
# Only the recovery's actual provider return, plus exactly one LF, is current accepted handback.
actual=(R/'s52-o034-accept/actual-worker-return.txt').read_bytes();returned=(R/'s52-o034-accept/returned.txt').read_bytes();live=readj('s53-quality-r6-probes/recovery-live-read.json')
final=[x for x in live['items'] if x['type']=='assistant_message'][-1]['text'].encode();assert actual==final and actual+b'\n'==returned and actual!=returned
assert len(actual)==741 and len(returned)==742 and sha(returned)=='fadc7d9f0b3d5464c74b84231c14ded708a7bcc21f932652a75ec21ebb6fb162'
assert live['thread']['status']=='completed' and live['thread']['providerInstanceId']=='codex_codex_gym' and live['thread']['model']=='gpt-6.1-sol'
for name in ['s51-verification-return-recovery/worker-return.txt','s50-o034-qualified-tools-verification/worker-return.txt']:assert (R/name).read_bytes()==returned
assert (cap/'summary.txt').read_bytes().strip() in returned
acc=V/'accepted/T031a5o1/ACC-TYOLj8';amembers=seal(acc,['meta.nul','return.txt','tasks.after','digests.nul']);ameta=pairs(acc/'meta.nul');digests=pairs(acc/'digests.nul');tasks=(S/'tasks.md').read_bytes();before=(R/'s52-o034-accept/tasks-before.md').read_bytes()
assert (acc/'return.txt').read_bytes()==returned and (acc/'tasks.after').read_bytes()==tasks
assert (acc/'COMMITTED').read_text()==sha((acc/'COMPLETE').read_bytes())+'\n'
assert ameta['task']=='T031a5o1' and ameta['captures']=='CAP-843-YAhBBt' and ameta['input']==inputsha and ameta['return_digest']==sha(returned) and ameta['binding_digest']==sha((cap/'bindings.nul').read_bytes())
assert digests=={'before':sha(before),'after':sha(tasks)}
expect=before.replace(b'- [ ] **T031a5o1**',b'- [x] **T031a5o1**',1)
start=expect.index(b'- [x] **T031a5o1**');end=expect.index(b'\n\n',start)
ev=b'\n  - *Evidence:* CAP-843-YAhBBt verified by spec-gate accept; return sha256:'+sha(returned).encode()
expect=expect[:end]+ev+expect[end:];assert expect==tasks
assert (R/'s52-o034-accept/accept.rc').read_text().strip()=='0' and b'ACC-TYOLj8' in (R/'s52-o034-accept/accept.stdout').read_bytes() and not (R/'s52-o034-accept/accept.stderr').read_bytes()
checks['accepted_return_seals_current_tasks_exact_atomic_change']=True
failure=readj('s51-capacity-recovery/actual-s50-task-failure.json')['structuredContent'];assert failure['status']=='failed' and failure['summary']=='Selected model is at capacity. Please try a different model.'
checks['original_failed_capacity_is_distinct_from_native_capture_success']=True
# Inspect retained matrix streams rather than rerunning the suite or a modern runtime.
d=R/'s50-o034-qualified-tools-verification';oldarrays=json.loads((d/'before-arrays.json').read_text());arrays=json.loads((d/'current-arrays.json').read_text())
def stream(p):
 f=fields(p);assert len(f)%2==0;out={}
 for k,v in zip(f[::2],f[1::2]):out.setdefault(k,[]).append(v)
 return out
assert stream(d/'before-bash32-fixture.stdout')==oldarrays
matrix={}
for name in ['current-bash32-fixture.stdout','current-bash52-on.stdout','current-bash52-off.stdout']:
 assert stream(d/name)==arrays;matrix[name]={'sha256':sha((d/name).read_bytes()),'same_bytes_as_bash32':(d/name).read_bytes()==(d/'current-bash32-fixture.stdout').read_bytes()}
assert all(arrays[k][:len(oldarrays[k])]==oldarrays[k] for k in oldarrays)
assert [len(arrays[k]) for k in ['weak','runner','qualified_weak','qualified_runner']]==[396,250,109,88]
assert all('REDIRECT' not in v for vals in arrays.values() for v in vals)
source=(ROOT/'tests/test-sdd-analyze.sh').read_text();extract=(d/'current-fixture-extracted.sh').read_text()
source_build=source[source.index('  local weak_redirect_cases=()'):source.index('  # AC-004/O-034: arguments')];assert source_build in extract
for key in ['weak','runner']:
 marker='"${weak_redirect_cases[@]}" "${weak_qualified_cases[@]}"; do' if key=='weak' else '"${runner_redirect_cases[@]}" "${runner_qualified_cases[@]}"; do'
 stop=source.index(marker);start=source.rfind('  for fixture in \\\n',0,stop);assert source[start:stop+len(marker)] in extract
checks['retained_matrix_all_646_old_449_and_source_declarations_match']=True
static=json.loads((d/'static-checks.json').read_text());assert all(x['exit']==0 for x in static)
for entry in static:
 for streamname in ['stdout','stderr']:
  assert sha((d/(entry['label']+'.'+streamname)).read_bytes())==entry[streamname+'_sha256']
assert '--norc' in static[-1]['argv'] and static[-1]['env_overrides']['SHELLCHECK_OPTS'] is None
invocation=readj('s53-quality-r6-invocation.json')['structuredContent'];runtime=readj('s53-quality-r6-probes/runtime-observed.json')['structuredContent']
assert runtime['threadId']==invocation['childThreadId'] and runtime['modelSelection']['instanceId']==invocation['providerInstanceId'] and runtime['modelSelection']['model']==invocation['model'] and runtime['modelSelection']['options']==invocation['options']
checks['live_MAX_identity_matches_exact_parent_invocation']=True
emit('evidence-review-command-records.json',commands)
result={'checks':checks,'diffs':regenerated,'input_sha256':inputsha,'manifest_counts':dict(collections.Counter(r[0] for r in manifest)),'source_path_proofs':pathproof,'capture_metadata':meta,'capture_members':members,'accepted_members':amembers,'COMMITTED_value':(acc/'COMMITTED').read_text().strip(),'actual_return_literal_byte_match':actual==returned,'actual_return_matches_after_exactly_one_LF':actual+b'\n'==returned,'actual_return_bytes':len(actual),'canonical_return_bytes':len(returned),'retained_matrix':matrix,'retained_array_counts':{k:len(v) for k,v in arrays.items()},'static_receipts_checked':True,'syntax_check_scope':'bash -n with two path arguments parses the first script only; test script syntax is independently exercised by the actual Bash 3.2 19/19 suite. No fresh static or suite run here.','new_suite_capture_acceptance_floor_gate_CI_runtime_executions':0,'scratch':str(TMP)}
emit('evidence-review.json',result)
print(json.dumps({k:v for k,v in result.items() if k not in ['source_path_proofs','capture_metadata','capture_members','accepted_members']},indent=2))
