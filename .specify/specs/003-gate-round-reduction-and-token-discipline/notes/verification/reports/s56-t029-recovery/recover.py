from pathlib import Path
import os,stat,json,hashlib,subprocess,datetime,re
P=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=P/'.specify/specs/003-gate-round-reduction-and-token-discipline'; V=S/'notes/verification'; R=V/'reports'
D=R/'s56-t029-recovery'; W=R/'s55-t029-worker'; A=R/'s55-approval'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0');H=lambda b:hashlib.sha256(b).hexdigest()
source='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff'
checks={};records=[]
def save(n,j):(D/n).write_text(json.dumps(j,indent=2,sort_keys=True)+'\n')
def check(k,v):
 checks[k]=bool(v);save('checks.json',checks)
 assert v,k
def run(label,argv,input=None):
 begin=datetime.datetime.now(datetime.timezone.utc).isoformat()
 z=subprocess.run(argv,input=input,cwd=P,env=ENV,capture_output=True)
 (D/(label+'.stdout')).write_bytes(z.stdout);(D/(label+'.stderr')).write_bytes(z.stderr)
 records.append(dict(label=label,argv=argv,cwd=str(P),env_overrides={'GIT_OPTIONAL_LOCKS':'0'},start=begin,end=datetime.datetime.now(datetime.timezone.utc).isoformat(),exit=z.returncode,stdin_sha256=H(input) if input is not None else None,stdout_sha256=H(z.stdout),stderr_sha256=H(z.stderr)))
 save('command-records.json',records)
 check(label+'_exit_zero',z.returncode==0)
 return z.stdout
command=json.loads((W/'command.json').read_text());start=json.loads((W/'command-start.json').read_text());original=json.loads((W/'result.json').read_text())
check('original_delegate_failed_not_completed',json.loads((D/'original-failure-provenance.json').read_text())['status']=='failed')
check('original_finalizer_finished_with_honest_failed_preservation',original['status']=='failed' and original['failed_checks']==['every_protected_file_hash_mode_mtime_size_unchanged'] and original.get('exception') is None and bool(original['verification_end']))
check('native_command_exact_and_single',command['argv']==['bash','scripts/spec-run.sh',str(S.relative_to(P)),'T029','--from-task','--no-tick','--summary'] and command['attempt']==1 and command['retries']==0 and command['cwd']==str(P) and command['nativePid']==18016 and command['expected_source']==source and all(start[k]==command[k] for k in start))
check('actual_native_exit_zero',command['exit']==0 and (W/'exit.txt').read_bytes()==b'0\n')
stdout=(W/'stdout.txt').read_bytes();stderr=(W/'stderr.txt').read_bytes()
check('native_stdout_stderr_digests_bytes',all(H(b)==command[n+'_sha256'] and len(b)==command[n+'_bytes'] for n,b in [('stdout',stdout),('stderr',stderr)]) and stderr==b'')
m=re.fullmatch(rb'capture=(CAP-844-[A-Za-z0-9]+) [^\n]+\n',stdout);check('native_summary_one_full_line',bool(m))
cap=m[1].decode();C=S/'notes/captures'/cap;ledger=V/'captures'/cap
members=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']
check('capture_exact_eight_regular_members',set(x.name for x in C.iterdir())==set(members+['COMPLETE']) and all((C/n).is_file() and not (C/n).is_symlink() for n in members+['COMPLETE']) and ledger.is_file() and not ledger.is_symlink())
hashes={n:H((C/n).read_bytes()) for n in members};seal=b'verification:1\n'+b''.join((hashes[n]+' '+n+'\n').encode() for n in members)
check('all_seven_members_complete_and_ledger',seal==(C/'COMPLETE').read_bytes()==ledger.read_bytes())
f=(C/'meta.nul').read_bytes().split(b'\0');check('meta_even_unique_terminated',f[-1]==b'' and len(f[:-1])%2==0 and len(f[:-1:2])==len(set(f[:-1:2])))
meta={k.decode():v.decode() for k,v in zip(f[:-1:2],f[1:-1:2])}
check('meta_identity_exit_no_tick',meta['id']==cap and meta['sequence']=='844' and meta['kind']=='command' and meta['version']=='1' and meta['exit']=='0' and meta['no_tick']=='1' and meta['repo']==meta['cwd']==str(P) and meta['start']<=meta['end'])
check('input_before_after_current_source',meta['input_before']==meta['input_after']==hashes['inputs.nul']==hashes['inputs-after.nul']==source and (C/'inputs.nul').read_bytes()==(C/'inputs-after.nul').read_bytes()==(A/'current-inputs.nul').read_bytes())
argv=(C/'argv.nul').read_bytes();check('sealed_exact_task_argv',argv==b'/bin/bash\0-o\0pipefail\0-c\0bash tests/test-gate-contracts.sh\0' and meta['shell']=='/bin/bash')
output=(C/'output.log').read_bytes();summary=(C/'summary.txt').read_bytes()
check('actual_log_18_passing_checks_exit_zero',re.findall(rb'-- ([0-9]+)/([0-9]+) passed',output)==[(b'18',b'18')] and len(re.findall(rb'^  ok   ',output,re.M))==18 and not re.search(rb'^\s*(FAIL|not ok|assert:)',output,re.M) and b'  ok   test_instruction_contracts\n' in output and meta['key'].strip()=='-- 18/18 passed')
check('output_digest_and_byte_count',H(output)==meta['output_digest']==hashes['output.log'] and len(output)==int(meta['output_bytes']))
check('summary_is_actual_native_stdout_one_LF',summary==stdout and summary.endswith(b'\n') and summary.count(b'\n')==1)
script=r"""set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; cap="$2"; own="$3"
vf_binding_snapshot "$spec" "$own/current-bindings.nul" || exit 3
vf_snapshot "$(cd "$spec" && pwd -P)" "$PWD" "$PWD" "$own/current-inputs.nul" > "$own/current-source.txt" || exit 3
vf_capture_check "$spec" "$cap" "$own/current-inputs.nul" current || exit 3
vf_task_capture_matches "$own/current-bindings.nul" T029 "$spec/notes/captures/$cap" || exit 3
"""
(D/'read-only-check.sh.txt').write_text(script)
run('independent-current-source-capture-bindings',['/bin/bash','-s','--',str(S.relative_to(P)),cap,str(D.relative_to(P))],script.encode())
check('independent_current_snapshot_equals_sealed_before_after',(D/'current-source.txt').read_bytes()==(source+'\n').encode() and (D/'current-inputs.nul').read_bytes()==(C/'inputs.nul').read_bytes())
current=(D/'current-bindings.nul').read_bytes();check('independent_bindings_equal_sealed',current==(C/'bindings.nul').read_bytes())
f=current.split(b'\0');check('bindings_NUL_framed_12_fields',f[-1]==b'' and len(f[:-1])%12==0)
rows=[[v.decode() for v in f[i:i+12]] for i in range(0,len(f)-1,12)];taskrows=[a for a in rows if a[2]=='T029'];bindings=[(a[1],a[7]) for a in taskrows if a[0]=='binding']
check('both_current_FM001_INV005_bindings',bindings==[('FM-001','tests/test-gate-contracts.sh::test_instruction_contracts'),('INV-005','tests/test-gate-contracts.sh::test_instruction_contracts')])
tasks=[a for a in taskrows if a[0]=='task'];check('current_task_exact_command_and_locator',len(tasks)==1 and tasks[0][5]=='test' and tasks[0][7]=='`tests/test-gate-contracts.sh::test_instruction_contracts`' and tasks[0][9]=='`bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0')
# Sequence and automatic evidence are compared directly with saved originals, without rewriting any history.
check('sequence_843_to_844_once',(W/'sequence-before.txt').read_bytes()==b'843\n' and (V/'sequence').read_bytes()==b'844\n' and len(list((V/'captures').glob('CAP-844-*')))==1 and next((V/'captures').glob('CAP-844-*'))==ledger and not list((V/'captures').glob('CAP-845-*')))
append=('\n## '+cap+' — '+meta['end']+'\n\nCaptured run, exit 0. Full log: `notes/captures/'+cap+'/output.log`.\n\n').encode()+summary
check('evidence_exact_automatic_append',(S/'notes/evidence.md').read_bytes()==(W/'evidence-before.bin').read_bytes()+append)
(D/'evidence-append.raw').write_bytes(append)
before=json.loads((W/'before-files.json').read_text());nativeafter=json.loads((W/'after-files.json').read_text());baseline=json.loads((D/'inventory.before.json').read_text())
automatic={str((S/'notes/evidence.md').relative_to(P)),str((V/'sequence').relative_to(P))}
originalchanges={k:{'before':v,'after':baseline['files'].get(k)} for k,v in before.items() if baseline['files'].get(k)!=v}
allowednew={str((C/n).relative_to(P)) for n in members+['COMPLETE']}|{str(ledger.relative_to(P))}
new=set(nativeafter)-set(before)
check('original_additions_exact_capture_and_ledger',new==allowednew and set(original['preservation']['new_files'])==allowednew)
check('original_after_inventory_still_exact',all(baseline['files'].get(k)==v for k,v in nativeafter.items()))
check('original_actual_difference_preserved_without_allowlisting',set(originalchanges)==automatic|{'.DS_Store'} and originalchanges['.DS_Store']['before']==before['.DS_Store'] and originalchanges['.DS_Store']['after']==nativeafter['.DS_Store'])
check('automatic_modes_preserved',all(before[k]['mode']==nativeafter[k]['mode'] for k in automatic))
expected={str((S/'STATUS.md').relative_to(P)):('dfa43e94c72e6b9a6b659d7454d1f7b854516a7bb42a1d58c2ceef31b674cc1d','0o600',1793309559845064145),str((S/'tasks.md').relative_to(P)):('859042532b2b0c71136b6db6184008fb354a697b190e77accae10ec1ea166575','0o600',1793296519245071301),'scripts/sdd-analyze.sh':('f2809d24b5bec01fa4ca8ab4d689c5e9585472989e66798aabc9597d80f176fd','0o755',None),'tests/test-sdd-analyze.sh':('9dd851fd6ed32797384ada5c4d263dcdbb6947ce95cdeae4d5ea0ac1bb60a393','0o644',None),'tests/test-gate-contracts.sh':('7bc13dde14004bf4ba967c0f64ec120b19bdde641643a6a7436d154c222f893c','0o644',None)}
check('protected_source_tasks_STATUS_hashes_modes_mtimes',all(baseline['files'][k]['sha256']==v[0] and baseline['files'][k]['mode']==v[1] and (v[2] is None or baseline['files'][k]['mtime_ns']==v[2]) and before[k]==baseline['files'][k] for k,v in expected.items()))
gbefore=json.loads((W/'before-git.json').read_text());idx='/Users/babar/projects/sdd-kit-public/.git/worktrees/003-gate-round-reduction-and-token-discipline/index'
check('HEAD_branch_real_index_preserved',baseline['head']==gbefore['HEAD']=='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9' and baseline['branch']==gbefore['branch']=='refs/heads/spec/003-gate-round-reduction-and-token-discipline' and all(baseline['external'].get(k)==v for k,v in gbefore['files'].items()) and baseline['external'][idx]['sha256']=='c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700' and baseline['external'][idx]['mtime_ns']==1792957592613445716)
def refs(raw):return dict(line.split(' ',1) for line in raw.splitlines())
def diff(a,b):return {k:{'before':a.get(k),'after':b.get(k)} for k in sorted(a.keys()|b.keys()) if a.get(k)!=b.get(k)}
refdiff=diff(refs(gbefore['refs']),refs(original['current_global_refs_after']))
projection={k:v for k,v in originalchanges.items() if k not in automatic}
save('original-preservation-proof.json',dict(original_status=original['status'],failed_checks=original['failed_checks'],all_original_checks=original['checks'],strict_global_refs_preserved=original['strict_current_global_refs_preserved'],strict_preservation_passed=False,changed_preexisting=originalchanges,unexpected_changed_preexisting=projection,new_capture_and_ledger_paths=sorted(allowednew),missing_original=sorted(set(before)-set(baseline['files'])),global_ref_differences=refdiff,attribution='Unknown actor for .DS_Store and checkpoint ref differences; no actor inferred, no file/ref restored, no difference hidden or broadly allowlisted.',original_inventory_excluded_owned_worker_and_approval_directories=True,recovery_inventory_covers_both_original_owned_directories=True,protected_source_HEAD_index_tasks_STATUS_preserved=True,historical_strict_preservation_passed=False))
save('capture-proof.json',dict(capture=cap,metadata=meta,argv=[x.decode() for x in argv.split(b'\0')[:-1]],member_sha256=hashes,complete_sha256=H(seal),ledger_sha256=H(ledger.read_bytes()),source_before_after_current=source,current_task_and_binding_rows=taskrows,output_bytes=len(output),output_digest=H(output),checks=checks,original_command=command,actual_emitted_summary=summary.decode().removesuffix('\n'),original_finalizer_failed=True,original_delegate_failed=True,independent_recovery=True,suite_or_capture_reexecuted=False))
body=b'Verification-Return: 1\nTask: T029\nCaptures: '+cap.encode()+b'\nSummary: '+summary+b'Failure modes:\n'+b''.join((a+', '+b+', '+cap+'\n').encode() for a,b in bindings)
check('canonical_body_one_terminal_LF',body.endswith(b'\n') and not body.endswith(b'\n\n'))
(D/'validated-return.pending').write_bytes(body)
print(json.dumps(dict(capture=cap,independent_checks=len(checks),all_checks_passed=all(checks.values()),originalFinalizerStatus=original['status'],originalStrictPreservation=False,originalDifferences=list(projection),originalGlobalRefDifferenceCount=len(refdiff),returnBytes=len(body),returnSha256=H(body))))
