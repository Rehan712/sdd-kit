from pathlib import Path
import os,stat,json,hashlib,subprocess,datetime,re
P=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==P and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=P/'.specify/specs/003-gate-round-reduction-and-token-discipline';V=S/'notes/verification';R=V/'reports';D=R/'s56-t029-recovery';W=R/'s55-t029-worker'
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0');H=lambda b:hashlib.sha256(b).hexdigest()
B=json.loads((D/'inventory.before.json').read_text());records=json.loads((D/'command-records.json').read_text())
def save(n,j):(D/n).write_text(json.dumps(j,indent=2,sort_keys=True)+'\n')
def run(label,argv):
 begin=datetime.datetime.now(datetime.timezone.utc).isoformat();z=subprocess.run(argv,cwd=P,env=ENV,capture_output=True)
 (D/(label+'.stdout')).write_bytes(z.stdout);(D/(label+'.stderr')).write_bytes(z.stderr)
 records.append(dict(label=label,argv=argv,cwd=str(P),env_overrides={'GIT_OPTIONAL_LOCKS':'0'},start=begin,end=datetime.datetime.now(datetime.timezone.utc).isoformat(),exit=z.returncode,stdout_sha256=H(z.stdout),stderr_sha256=H(z.stderr)))
 save('command-records.json',records);assert z.returncode==0,(label,z.returncode)
 return z.stdout
def info(p):
 st=p.lstat();a=dict(mode=oct(stat.S_IMODE(st.st_mode)),mtime_ns=st.st_mtime_ns,size=st.st_size)
 if stat.S_ISLNK(st.st_mode):a.update(type='symlink',target=os.readlink(p),sha256=H(os.fsencode(os.readlink(p))))
 elif stat.S_ISREG(st.st_mode):a.update(type='file',sha256=H(p.read_bytes()))
 else:a.update(type='other')
 return a
def inventory():
 a={}
 for root,dirs,files in os.walk(P,followlinks=False):
  dirs.sort();files.sort()
  for n in list(dirs):
   q=Path(root)/n
   if q==D:dirs.remove(n)
   elif q.is_symlink():a[str(q.relative_to(P))]=info(q);dirs.remove(n)
  for n in files:
   q=Path(root)/n;a[str(q.relative_to(P))]=info(q)
 return a
processes=run('processes-after',['ps','-axo','pid=,ppid=,stat=,etime=,command='])
head=run('HEAD-after',['git','rev-parse','HEAD']).decode().strip();branch=run('branch-after',['git','symbolic-ref','HEAD']).decode().strip()
refs=run('global-refs-after',['git','for-each-ref','--format=%(refname) %(objectname)']);status=run('git-status-after',['git','status','--porcelain=v1','-z','--untracked-files=all'])
after=inventory();changed={k:{'before':v,'after':after.get(k)} for k,v in B['files'].items() if after.get(k)!=v};added={k:v for k,v in after.items() if k not in B['files']}
paths=set(map(Path,B['external']))
for base in [Path(B['common_gitdir'])/'refs',Path(B['common_gitdir'])/'logs',Path(B['gitdir'])]:
 if base.exists():
  for root,dirs,files in os.walk(base,followlinks=False):
   for n in list(dirs):
    q=Path(root)/n
    if q.is_symlink():paths.add(q);dirs.remove(n)
   for n in files:paths.add(Path(root)/n)
external={str(q):info(q) for q in sorted(paths) if os.path.lexists(q)}
extchanged={k:{'before':v,'after':external.get(k)} for k,v in B['external'].items() if external.get(k)!=v};extadded={k:v for k,v in external.items() if k not in B['external']}
def refmap(b):return dict(line.split(' ',1) for line in b.decode().splitlines())
r0=refmap((D/'global-refs.before.txt').read_bytes());r1=refmap(refs);refdiff={k:{'before':r0.get(k),'after':r1.get(k)} for k in sorted(r0.keys()|r1.keys()) if r0.get(k)!=r1.get(k)}
def status_records(raw):
 fields=raw.split(b'\0');out=[];i=0
 while i<len(fields):
  x=fields[i];i+=1
  if not x:continue
  a=[x]
  if x[:1] in (b'R',b'C') or x[1:2] in (b'R',b'C'):a.append(fields[i]);i+=1
  if not x[3:].decode().startswith(str(D.relative_to(P))+'/'):out.append(tuple(a))
 return sorted(out)
original=json.loads((W/'result.json').read_text());oldgit=json.loads((W/'before-git.json').read_text());original_proof=json.loads((D/'original-preservation-proof.json').read_text());cproof=json.loads((D/'capture-proof.json').read_text());cap=cproof['capture'];C=S/'notes/captures'/cap
receiptproof=json.loads((D/'original-receipt-protection.json').read_text())
receiptchanges={n:{'before':v,'after':info(W/n) if os.path.lexists(W/n) else None} for n,v in receiptproof['original_receipts'].items() if not os.path.lexists(W/n) or info(W/n)!=v}
pending=[str(q.relative_to(P)) for base in [S/'notes/captures',V] for q in base.iterdir() if q.name in ('lock','sequence.tmp') or q.name.startswith(('.capture.','bindings.','return.'))]
live=[]
for l in processes.decode().splitlines():
 a=l.split(None,4)
 if len(a)!=5:continue
 pid=int(a[0]);cmd=a[4]
 if pid in (os.getpid(),os.getppid()):continue
 if pid in (17951,18016) or re.search(r'(^|[ /])(spec-run\.sh|spec-gate\.sh|test-gate-contracts\.sh)( |$)',cmd) or re.search(r's55-t029-worker/(run-once|verify)\.py( |$)',cmd):live.append(l)
checks={
 'every_preexisting_worktree_file_bytes_modes_mtimes_preserved':not changed,
 'no_new_worktree_paths_outside_owned_directory':not added,
 'all_original_worker_receipts_bytes_modes_mtimes_preserved':not receiptchanges,
 'HEAD_and_branch_preserved':head==B['head']==oldgit['HEAD'] and branch==B['branch']==oldgit['branch'],
 'original_five_protected_git_files_including_real_index_preserved':all(external.get(k)==v for k,v in oldgit['files'].items()),
 'all_baselined_external_files_preserved':not extchanged,
 'no_new_external_files':not extadded,
 'global_refs_byte_identical_this_recovery':not refdiff,
 'git_status_preserved_except_exact_owned_outputs':status_records(status)==status_records((D/'git-status.before.nul').read_bytes()),
 'no_surviving_original_or_live_capture_gate_process':not live,
 'no_capture_lock_or_stage_or_pending_binding_return':not pending,
 'sequence_still_exact_844':(V/'sequence').read_bytes()==b'844\n',
 'original_finalizer_failed_result_not_rewritten':original['status']=='failed' and original['failed_checks']==['every_protected_file_hash_mode_mtime_size_unchanged'],
 'capture_seven_members_complete_and_ledger_still_exact':all(H((C/n).read_bytes())==v for n,v in cproof['member_sha256'].items()) and H((C/'COMPLETE').read_bytes())==cproof['complete_sha256'] and (C/'COMPLETE').read_bytes()==(V/'captures'/cap).read_bytes(),
}
save('inventory.after.json',dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),files=after,external=external,head=head,branch=branch,only_excluded_worktree_path=str(D.relative_to(P))))
save('protection-proof.json',dict(checks=checks,baseline_preexisting_file_count=len(B['files']),after_preexisting_file_count=len(after),changed_preexisting=changed,added_outside_owned=added,external_changes=extchanged,external_additions=extadded,global_ref_differences=refdiff,original_worker_receipt_changes=receiptchanges,pending_operations=pending,live_operations=live,strict_current_recovery_preservation_passed=all(checks.values()),original_strict_preservation_passed=False,historical_strict_preservation_passed=False,original_capture_unexpected_preexisting_changes=original_proof['unexpected_changed_preexisting'],original_capture_global_ref_differences=original_proof['global_ref_differences'],unknown_actor_policy='Every actual difference is retained; actor unknown. No restoration, broad allowlist, deletion or claim of hostwide state preservation.'))
capturechecks=json.loads((D/'checks.json').read_text());assert all(capturechecks.values()),'Independent capture check failed'
# Unknown global checkpoint activity is reported, never converted into a source or execution success claim.
required=[k for k in checks if k not in ['all_baselined_external_files_preserved','no_new_external_files','global_refs_byte_identical_this_recovery']]
assert all(checks[k] for k in required),'Protected recovery state mismatch; no handback issued'
body=(D/'validated-return.pending').read_bytes();assert body.endswith(b'\n') and not body.endswith(b'\n\n')
assert body.splitlines()[3]==b'Summary: '+(W/'stdout.txt').read_bytes().removesuffix(b'\n')
assert not (D/'worker-return.txt').exists();(D/'worker-return.txt').write_bytes(body)
save('result.json',dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),task='T029',capture=cap,recovery_completed=True,new_genuine_independent_HIGH_verification_return=True,identity=dict(provider='codex',model='gpt-6.1-sol',reasoningEffort='high',serviceTier='default',runtimeObservation='Provider transition authenticated by parent; current model/high declared by harness; serviceTier default requested, not independently API-observed.'),original_delegate_status='failed',original_delegate_error='You’ve hit your usage limit',original_delegate_completed_successfully=False,original_authentic_T3_return=False,original_native_capture_exit=0,original_automatic_finalizer_status='failed',original_automatic_finalizer_failed_checks=original['failed_checks'],original_wrapper_final_exit_independently_observed=False,original_result_and_receipts_preserved=True,original_strict_preservation_passed=False,historical_strict_preservation_passed=False,current_recovery_strict_preservation_passed=all(checks.values()),original_unknown_actor_differences=dict(worktree=original_proof['unexpected_changed_preexisting'],global_refs=original_proof['global_ref_differences']),recovery_unknown_actor_differences=dict(worktree=changed,external_changes=extchanged,external_additions=extadded,global_refs=refdiff),independent_capture_checks=capturechecks,recovery_protection_checks=checks,actual_current_source=cproof['source_before_after_current'],sealed_suite_passed='18/18',sealed_capture_exit=0,sealed_no_tick=1,original_capture_execution_count=1,recovery_capture_execution_count=0,recovery_suite_or_focused_test_execution_count=0,source_task_STATUS_edits=False,acceptance_or_tick=False,gate_floor_CI_network_PR_execution=False,nested_agents_provider_fallback_or_model_CLI=False,provider_transition_record='provider-transition.json',OP27_only_authorization_unchanged=True,OP28_RC5_merge_authorized=False,T031a5o1_refresh_required_later=True,formal_OP26_state='CHALLENGED',readiness_or_clearance_claim=False,summary=cproof['actual_emitted_summary'],worker_return_path=str((D/'worker-return.txt').relative_to(P)),worker_return_bytes=len(body),worker_return_sha256=H(body),worker_return_terminal_LF_count=len(body)-len(body.rstrip(b'\n')),return_provenance='New independently verified recovery envelope from the original sealed native capture; never represented as an original delegate handback.',receipt_references=['original-failure-provenance.json','original-receipt-protection.json','original-command-start.json','original-command.json','original-exit.txt','original-result.json','original-preservation-proof.json','capture-proof.json','checks.json','command-records.json','provider-transition.json','inventory.before.json','inventory.after.json','protection-proof.json','read-only-check.sh.txt','worker-return.txt']))
print(json.dumps(dict(recoveryComplete=True,capture=cap,captureChecksPassed=all(capturechecks.values()),recoveryStrictPreservation=all(checks.values()),originalStrictPreservation=False,originalFinalizer='failed',worktreeChanges=len(changed),externalChanges=len(extchanged),externalAdditions=len(extadded),globalRefDifferences=len(refdiff),bodyBytes=len(body),bodySha256=H(body))))
