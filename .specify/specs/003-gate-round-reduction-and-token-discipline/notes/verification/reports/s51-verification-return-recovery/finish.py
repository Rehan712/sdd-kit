from pathlib import Path
import os,stat,json,hashlib,subprocess,datetime,re
p=Path.cwd();s=p/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';d=r/'s51-verification-return-recovery';old=r/'s50-o034-qualified-tools-verification';b=json.loads((d/'inventory.before.json').read_text());H=lambda x:hashlib.sha256(x).hexdigest()
def write(n,a):(d/n).write_text(json.dumps(a,indent=2)+'\n')
records=json.loads((d/'command-records.json').read_text())
def run(label,argv):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat();z=subprocess.run(argv,cwd=p,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),capture_output=True)
 records.append(dict(label=label,argv=argv,cwd=str(p),env_overrides={'GIT_OPTIONAL_LOCKS':'0'},start=start,end=datetime.datetime.now(datetime.timezone.utc).isoformat(),exit=z.returncode,stdout_sha256=H(z.stdout),stderr_sha256=H(z.stderr)))
 write('command-records.json',records);assert z.returncode==0,(label,z.stderr)
 return z.stdout
processes=run('processes-after',['ps','-axo','pid,ppid,lstart,command']);(d/'processes.after.txt').write_bytes(processes)
refs=run('refs-after',['git','show-ref','--head']);(d/'global-refs.after.txt').write_bytes(refs)
head=run('head-after',['git','rev-parse','HEAD']).decode().strip()
status=run('status-after',['git','status','--porcelain=v1','-z','--untracked-files=all']);(d/'git-status.after.nul').write_bytes(status)
def meta(x):
 st=x.lstat();a={'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns,'size':st.st_size}
 if stat.S_ISLNK(st.st_mode):a.update(kind='symlink',target=os.readlink(x))
 elif stat.S_ISREG(st.st_mode):a.update(kind='file',sha256=H(x.read_bytes()))
 else:raise RuntimeError(str(x))
 return a
files={}
for root,dirs,names in os.walk(p,followlinks=False):
 for n in list(dirs):
  x=Path(root)/n
  if x==d:dirs.remove(n);continue
  if x.is_symlink():files[str(x.relative_to(p))]=meta(x);dirs.remove(n)
 for n in names:
  x=Path(root)/n;files[str(x.relative_to(p))]=meta(x)
changed={k:{'before':v,'after':files.get(k)} for k,v in b['files'].items() if files.get(k)!=v}
added={k:v for k,v in files.items() if k not in b['files']};parent=str((r/'s51-verification-return-recovery-invocation.json').relative_to(p));unexpected_added={k:v for k,v in added.items() if k!=parent}
oldbase=json.loads((old/'inventory.before.json').read_text());common=Path(oldbase['common_gitdir']);gitdir=Path(oldbase['gitdir']);external_paths=set(map(Path,b['external']))
for root in [common/'refs',common/'logs',gitdir]:
 if root.exists():
  for cur,dirs,names in os.walk(root,followlinks=False):
   for n in names:external_paths.add(Path(cur)/n)
   for n in list(dirs):
    x=Path(cur)/n
    if x.is_symlink():external_paths.add(x);dirs.remove(n)
external={str(x):meta(x) for x in sorted(external_paths) if os.path.lexists(x)}
extchanged={k:{'before':v,'after':external.get(k)} for k,v in b['external'].items() if external.get(k)!=v};extnew={k:v for k,v in external.items() if k not in b['external']}
def status_records(raw):
 fields=raw.split(b'\0');out=[];i=0
 while i<len(fields)-1:
  a=fields[i];i+=1;rec=a+b'\0'
  if a[:1] in [b'R',b'C'] or a[1:2] in [b'R',b'C']:rec+=fields[i]+b'\0';i+=1
  out.append((a[3:].decode(),rec))
 return out
before_status=(d/'git-status.before.nul').read_bytes()
filtered=b''.join(rec for path,rec in status_records(status) if not path.startswith(str(d.relative_to(p))+'/') and not (path==parent and path in added))
refbefore=(d/'global-refs.before.txt').read_bytes()
def refmap(raw):return {line.split(b' ',1)[1].decode():line.split(b' ',1)[0].decode() for line in raw.splitlines()}
r0=refmap(refbefore);r1=refmap(refs);refdiff={k:{'before':r0.get(k),'after':r1.get(k)} for k in sorted(r0.keys()|r1.keys()) if r0.get(k)!=r1.get(k)}
# Revalidate the original capture's only two preexisting-file changes from full saved originals.
original_proof=json.loads((old/'protection-proof.json').read_text());hist_changes={k:{'before':v,'after':files.get(k)} for k,v in oldbase['files'].items() if files.get(k)!=v};allowed_original={str((s/'notes/evidence.md').relative_to(p)),str((s/'notes/verification/sequence').relative_to(p))}
hist_unexpected={k:v for k,v in hist_changes.items() if k not in allowed_original}
original_evidence_key=str((s/'notes/evidence.md').relative_to(p));original_blob=Path(oldbase['original_blob_directory'])/oldbase['files'][original_evidence_key]['sha256'];original_evidence=original_blob.read_bytes();current_evidence=(s/'notes/evidence.md').read_bytes()
history_checks={'only_original_two_authorized_changes':set(hist_changes)==allowed_original,'original_authorized_changes_match_s50_proof':hist_changes==original_proof['changed_preexisting'],'evidence_exact_original_append':current_evidence==original_evidence+(old/'evidence-append.raw').read_bytes(),'sequence_single_original_increment':(s/'notes/verification/sequence').read_text()=='843\n' and (Path(oldbase['original_blob_directory'])/oldbase['files'][str((s/'notes/verification/sequence').relative_to(p))]['sha256']).read_text()=='842\n','all_original_saved_external_exact':all(external.get(k)==v for k,v in oldbase['external'].items())}
# Process text retained unfiltered. Only report executable candidates, excluding this own process chain.
parentpid=os.getppid();ownpid=os.getpid();candidates=[]
for line in processes.decode().splitlines()[1:]:
 parts=line.strip().split(None,7)
 if len(parts)<8:continue
 pid=int(parts[0]);cmd=parts[7]
 if pid in [parentpid,ownpid]:continue
 if re.search(r'(^|[ /])(spec-run\.sh|spec-gate\.sh|sdd-analyze\.sh|test-sdd-analyze\.sh|finalize\.py)( |$)',cmd):candidates.append(line)
checks={'all_preexisting_worktree_bytes_modes_mtimes_preserved':not changed,'no_unexpected_new_files_or_symlinks':not unexpected_added,'all_protected_external_files_preserved':not extchanged,'no_new_protected_external_files':not extnew,'git_status_preserved_except_own_outputs_and_exact_parent_receipt':filtered==before_status,'head_unchanged':head==b['head'],'global_refs_byte_identical_this_recovery':not refdiff,'capture_lock_absent':not os.path.lexists(s/'notes/verification/lock'),'capture_staging_absent':not list((s/'notes/captures').glob('.capture.*')),'pending_bindings_absent':not list((s/'notes/verification').glob('bindings.*')),'no_surviving_original_worker_finalizer_capture_analyzer':not candidates}
write('inventory.after.json',dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),files=files,external=external,head=head))
proof=dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),preexisting_worktree_count=len(b['files']),protected_external_count=len(b['external']),before_inventory='inventory.before.json',after_inventory='inventory.after.json',full_original_blobs=b['original_blob_directory'],changed_preexisting=changed,new_paths_outside_owned=added,unexpected_new_paths=unexpected_added,exact_parent_receipt_addition=added.get(parent),external_changes=extchanged,external_additions=extnew,global_ref_differences=refdiff,global_ref_attribution='Unknown concurrent actor if changed; no refs written, reset, hidden, or allowlisted.',checks=checks,current_recovery_strict_preservation_passed=all(checks.values()),historical_s50_strict_preservation_passed=False,historical_s50_global_refs_byte_identical=False,historical_s50_global_ref_differences=original_proof['global_ref_differences'],historical_original_capture_checks=history_checks,historical_unexpected_changes=hist_unexpected,historical_preservation_exceptions_retained=original_proof['historical_preservation_exceptions_retained'],hostwide_OS_claim='Only actual process observations retained; no claim that host-wide OS state is unchanged.',active_process_candidates=candidates)
write('protection-proof.json',proof)
assert not changed and not unexpected_added and checks['git_status_preserved_except_own_outputs_and_exact_parent_receipt'] and checks['head_unchanged'], 'Recovery preservation mismatch; no handback issued'
assert all(history_checks.values()) and not hist_unexpected, 'Original protection mismatch; no handback issued'
assert checks['capture_lock_absent'] and checks['capture_staging_absent'] and checks['pending_bindings_absent'] and not candidates, 'Active capture/process/lock; no handback issued'
assert not extchanged and not extnew, 'External state changed; no handback issued'
checks_capture=json.loads((d/'checks.json').read_text());assert all(checks_capture.values())
body=(d/'validated-return.pending').read_bytes();assert body==(old/'worker-return.txt').read_bytes() and body.endswith(b'\n') and not body.endswith(b'\n\n')
(d/'worker-return.txt').write_bytes(body)
write('result.json',dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(),task='T031a5o1',capture='CAP-843-YAhBBt',recovery_completed=True,new_genuine_HIGH_return=True,requested_identity='codex_codex_gym/gpt-6.1-sol/HIGH/serviceTierdefault',substitutions=False,nested_agents=False,original_delegate_status='failed',original_delegate_summary='Selected model is at capacity. Please try a different model.',original_delegate_completed_successfully=False,original_native_capture_completed=True,original_local_finalizer_result_persisted=True,recovery_executed_suite=False,recovery_executed_capture=False,recovery_executed_focused_probes_or_static_checks=False,canonical_capture_count=1,recovery_capture_count=0,current_identity_and_bindings_independently_verified=True,actual_current_source='3e70d8170d98f13c04f550c15942f70bdb487abf30ad629ff78db2048f077497',sealed_capture_suite_counts=['19/19'],sealed_capture_exit=0,sealed_capture_no_tick=1,capture_checks=checks_capture,protection_checks=checks,historical_original_capture_checks=history_checks,current_recovery_strict_preservation_passed=all(checks.values()),historical_strict_preservation_passed=False,historical_global_refs_byte_identical=False,historical_unknown_checkpoint_ref_preserved=original_proof['global_ref_differences'],no_hidden_product_or_capture_retry=True,source_edits=False,tasks_edits=False,acceptance_or_tick=False,new_gate_floor_CI_PR_or_network=False,OP26_formal_state='CHALLENGED',OP27_authorized=False,RC5_authorized=False,RC4_state='blocked',O032_and_minors='unchanged',gate_or_readiness_verdict_issued=False,worker_return_bytes=len(body),worker_return_sha256=H(body),worker_return_byte_identical_to_s50=True,worker_return_one_terminal_LF=True,original_s50_result_file_preserved=True,receipt_references=['capture-proof.json','existing-execution-proof.json','protection-proof.json','command-records.json','inventory.before.json','inventory.after.json']))
print(json.dumps(dict(recovery_complete=True,current_strict_preservation=all(checks.values()),historical_strict_preservation=False,changed_preexisting=len(changed),external_changes=len(extchanged),external_additions=len(extnew),parent_addition=added.get(parent),worker_return_bytes=len(body),worker_return_sha256=H(body))))
