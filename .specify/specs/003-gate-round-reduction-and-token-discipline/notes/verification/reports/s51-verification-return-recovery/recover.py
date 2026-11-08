from pathlib import Path
import os,json,hashlib,subprocess,datetime,re
p=Path.cwd();s=p/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';d=r/'s51-verification-return-recovery';old=r/'s50-o034-qualified-tools-verification';cap='CAP-843-YAhBBt';c=s/'notes/captures'/cap
H=lambda b:hashlib.sha256(b).hexdigest()
def write(name,obj): (d/name).write_text(json.dumps(obj,indent=2)+'\n')
records=json.loads((d/'command-records.json').read_text())
def run(label,argv):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat()
 z=subprocess.run(argv,cwd=p,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),capture_output=True)
 (d/(label+'.stdout')).write_bytes(z.stdout);(d/(label+'.stderr')).write_bytes(z.stderr)
 records.append(dict(label=label,argv=argv,cwd=str(p),env_overrides={'GIT_OPTIONAL_LOCKS':'0'},start=start,end=datetime.datetime.now(datetime.timezone.utc).isoformat(),exit=z.returncode,stdout_sha256=H(z.stdout),stderr_sha256=H(z.stderr)))
 write('command-records.json',records)
 assert z.returncode==0,(label,z.returncode,z.stderr.decode(errors='replace'))
 return z.stdout
checks={}
def check(k,v):
 checks[k]=bool(v);write('checks.json',checks)
 assert v,k
seal=(c/'COMPLETE').read_bytes();ledger=s/'notes/verification/captures'/cap
names=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']
expected=b'verification:1\n'+b''.join((H((c/n).read_bytes())+' '+n+'\n').encode() for n in names)
check('seal_all_seven_members_and_exact_framing',seal==expected)
check('ledger_identical',ledger.read_bytes()==seal)
check('seal_matches_original_proof',H(seal)==json.loads((old/'capture-proof.json').read_text())['seal_sha256'])
meta_fields=(c/'meta.nul').read_bytes().split(b'\0')
check('meta_nul_terminated_even_pairs',meta_fields[-1]==b'' and len(meta_fields[:-1])%2==0)
meta=dict(zip([x.decode() for x in meta_fields[:-1:2]],[x.decode() for x in meta_fields[1:-1:2]]))
argv=[x.decode() for x in (c/'argv.nul').read_bytes().split(b'\0')[:-1]]
check('exact_argv',argv==['/bin/bash','-o','pipefail','-c','bash tests/test-sdd-analyze.sh'])
check('capture_id_cwd_repo',meta['id']==cap and meta['repo']==meta['cwd']==str(p))
check('completed_once_no_tick_exit_zero',meta['no_tick']=='1' and meta['exit']=='0' and meta['end']=='2026-10-29T17:46:38Z')
source='3e70d8170d98f13c04f550c15942f70bdb487abf30ad629ff78db2048f077497'
check('before_after_source_bytes_identical',(c/'inputs.nul').read_bytes()==(c/'inputs-after.nul').read_bytes())
check('before_after_source_metadata_hashes',meta['input_before']==meta['input_after']==H((c/'inputs.nul').read_bytes())==source)
log=(c/'output.log').read_bytes();counts=re.findall(rb'-- ([0-9]+)/([0-9]+) passed',log)
check('raw_log_actual_19_of_19',counts==[(b'19',b'19')] and len(re.findall(rb'^  ok   ',log,re.M))==19 and not re.search(rb'^  (FAIL|not ok)',log,re.M))
check('raw_log_verification_binding_pass',b'  ok   test_verification_bindings\n' in log)
check('output_digest_byte_count',H(log)==meta['output_digest']=='f9166fdc124954abb48f7c8ed789d96a1ce68c06a9da6df0d9d49a79a07aca5a' and str(len(log))==meta['output_bytes']=='862')
check('original_delegate_failed_capacity',json.loads((r/'s51-capacity-recovery/actual-s50-task-failure.json').read_text())['structuredContent']['status']=='failed')
inv=json.loads((old/'capture-invocation.json').read_text())
check('original_capture_one_native_invocation',inv['attempt_count']==1 and inv['exit']==0 and inv['source']==source)
check('original_invocation_outputs_match',H((old/'capture.stdout').read_bytes())==inv['stdout_sha256'] and H((old/'capture.stderr').read_bytes())==inv['stderr_sha256'])
check('native_stdout_equals_sealed_summary',(old/'capture.stdout').read_bytes()==(c/'summary.txt').read_bytes())
record_checks=[]
for a in json.loads((old/'command-records.json').read_text()):
 label=a['label'];values={k:H((old/(label+'.'+k)).read_bytes())==a[k+'_sha256'] for k in ['stdout','stderr']}
 record_checks.append(dict(label=label,exit=a['exit'],digests=values))
check('original_recorded_commands_stdout_stderr_digests',all(all(x['digests'].values()) and x['exit']==0 for x in record_checks))
focused=json.loads((old/'focused-green-results.json').read_text());red=json.loads((old/'retained-red-baseline.json').read_text())
check('41_existing_focused_checks_green',focused['count']==focused['passing']==len(focused['results'])==41 and all(x['passed'] and x['exit']==0 and x['observed_warning']==x['expected_warning'] for x in focused['results']))
check('28_retained_op26_inputs',set(x['command'] for x in focused['results'] if x['group']=='retained-op26-red')==set(red['commands']) and len(set(red['commands']))==28)
for a in red['proofs']:check('retained_red_'+str(a['omissions']),H((p/a['path']).read_bytes())==a['sha256'])
a=json.loads((old/'current-arrays.json').read_text());b=json.loads((old/'before-arrays.json').read_text())
check('existing_actual_array_counts',len(a['weak'])==396 and len(a['runner'])==250 and len(a['qualified_weak'])==109 and len(a['qualified_runner'])==88 and len(b['weak'])==287 and len(b['runner'])==162)
check('all_old_array_cases_retained',all(a[k][:len(v)]==v for k,v in b.items()))
check('bash32_bash52_on_off_existing_stdout_identical',(old/'current-bash32-fixture.stdout').read_bytes()==(old/'current-bash52-on.stdout').read_bytes()==(old/'current-bash52-off.stdout').read_bytes())
check('four_explicit_kinds_existing_proof',focused['explicit_kinds']==['test','assertion','static','manual'] and focused['explicit_kinds_passed'] and b'verification contract bindings valid' in (old/'explicit-controls.stdout').read_bytes())
run('source-snapshot',['/bin/bash',str(old/'snapshot.sh'),str(s),str(d/'current-inputs.nul')])
check('fresh_actual_vf_snapshot_equals_capture',(d/'current-inputs.nul').read_bytes()==(c/'inputs.nul').read_bytes())
run('capture-integrity-and-bindings',['/bin/bash',str(old/'check-capture.sh'),str(s),cap,str(d)])
check('fresh_binding_snapshot_equals_capture',(d/'current-bindings.nul').read_bytes()==(c/'bindings.nul').read_bytes())
# This read-only predicate checks shell/command/cwd identity and later failed captures.
run('capture-current',['/bin/bash','-c','. scripts/lib.sh; . scripts/verification-lib.sh; vf_capture_check "$1" "$2" "$3" current', 's51-recovery',str(s),cap,str(d/'current-inputs.nul')])
f=(d/'current-bindings.nul').read_bytes().split(b'\0')[:-1];rows=[[x.decode() for x in f[i:i+12]] for i in range(0,len(f),12)];taskrows=[x for x in rows if x[2]=='T031a5o1']
bindings=[(x[1],x[7]) for x in taskrows if x[0]=='binding']
check('both_current_FM001_INV005_bindings',bindings==[('FM-001','tests/test-sdd-analyze.sh::test_verification_bindings'),('INV-005','tests/test-sdd-analyze.sh::test_verification_bindings')])
check('task_kind_test',len([x for x in taskrows if x[0]=='task' and x[5]=='test'])==1)
rawtasks=(s/'tasks.md').read_text();lines=rawtasks.splitlines();i=next(i for i,l in enumerate(lines) if re.search(r'\[ \].*T031a5o1(?:[^a-z0-9]|$)',l));end=next((j for j in range(i+1,len(lines)) if re.match(r'\s*- \[[ x]\]',lines[j])),len(lines));tasktext='\n'.join(lines[i:end])
check('current_task_unchecked_without_Evidence','Evidence:' not in tasktext)
summary=(c/'summary.txt').read_bytes();check('summary_one_LF',summary.endswith(b'\n') and not summary.endswith(b'\n\n'))
body=b'Verification-Return: 1\nTask: T031a5o1\nCaptures: '+cap.encode()+b'\nSummary: '+summary+b'Failure modes:\n'+b''.join((fm+', '+loc+', '+cap+'\n').encode() for fm,loc in bindings)
check('reconstructed_canonical_body_identical_to_s50',body==(old/'worker-return.txt').read_bytes())
check('original_finalizer_completed_receipt_not_delegate_success',json.loads((old/'result.json').read_text())['at']=='2026-10-29T17:47:32.540947+00:00')
write('capture-proof.json',dict(metadata=meta,argv=argv,seal_sha256=H(seal),ledger_sha256=H(ledger.read_bytes()),members={n:H((c/n).read_bytes()) for n in names},current_source_sha256=H((d/'current-inputs.nul').read_bytes()),current_bindings_sha256=H((d/'current-bindings.nul').read_bytes()),current_task_rows=taskrows,raw_task_block=tasktext,checks=checks))
write('existing-execution-proof.json',dict(original_record_checks=record_checks,focused_count=41,retained_red_distinct=28,fixture_counts={k:len(v) for k,v in a.items()},prior_counts={k:len(v) for k,v in b.items()},existing_receipts_consumed_only=True,new_suite_capture_probe_or_static_check_execution=False,original_delegate_failed=True,original_failed_tool_time='2026-10-29T17:47:26Z',local_finalizer_result_time='2026-10-29T17:47:32.540947+00:00',original_delegate_success_claimed=False))
(d/'validated-return.pending').write_bytes(body)
print(json.dumps(dict(independent_checks=len(checks),all_passed=all(checks.values()),body_bytes=len(body),body_sha256=H(body),source=source)))
