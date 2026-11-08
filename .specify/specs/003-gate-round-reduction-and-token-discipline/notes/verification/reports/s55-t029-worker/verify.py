import os, stat, json, hashlib, subprocess, datetime, re
from pathlib import Path

cwd=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==cwd and os.environ['GIT_OPTIONAL_LOCKS']=='0'
s=Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
own=s/'notes/verification/reports/s55-t029-worker'
approval=s/'notes/verification/reports/s55-approval'
sequence_before=int((own/'sequence-before.txt').read_text())
expected=json.loads((approval/'freshness-result.json').read_text())['actualCurrentSource']

checks={}
result={'task':'T029','status':'failed','checks':checks,'scope':'Single live no-tick capture; test-suite fixture operations remain part of the actual suite. No live acceptance, ticking, task/source edits, extra suites, CI, floor or gate reservations. STATUS approval insertion was completed and frozen before this capture.'}
def sha(b): return hashlib.sha256(b).hexdigest()
def save(n,o): (own/n).write_text(json.dumps(o,indent=2,sort_keys=True)+'\n')
def check(k,v): checks[k]=bool(v)
def git(*args):
 data=subprocess.check_output(['git',*args],cwd=cwd,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'))
 return data if args[0]=='status' else data.strip()
def info(p):
 st=p.lstat(); d={'mode':oct(stat.S_IMODE(st.st_mode)),'mtime_ns':st.st_mtime_ns,'size':st.st_size}
 if p.is_symlink(): d.update(type='symlink',target=os.readlink(p),sha256=sha(os.fsencode(os.readlink(p))))
 elif p.is_file():
  h=hashlib.sha256()
  with p.open('rb') as f:
   for b in iter(lambda:f.read(1048576),b''): h.update(b)
  d.update(type='file',sha256=h.hexdigest())
 else: d['type']='other'
 return d
def inventory():
 out={}
 for root,dirs,files in os.walk('.',followlinks=False):
  dirs.sort();files.sort()
  if root=='.' and '.git' in dirs: dirs.remove('.git')
  for n in list(dirs):
   p=Path(root)/n
   if p.is_symlink(): out[str(p)]=info(p);dirs.remove(n)
   elif p in [own,approval]: dirs.remove(n)
  for n in files:
   p=Path(root)/n;out[str(p)]=info(p)
 return out
def statuses(data):
 records=data.split(b'\0');result=[];i=0
 while i<len(records):
  b=records[i];i+=1
  if not b: continue
  record=[b]
  if b[:1] in [b'R',b'C'] or b[1:2] in [b'R',b'C']:
   record.append(records[i]);i+=1
  result.append(tuple(record))
 return result
try:
 before=json.loads((own/'before-files.json').read_text());after=inventory();save('after-files.json',after)
 command=json.loads((own/'command.json').read_text());result['command']=command
 check('command_exit_zero',command['exit']==0)
 stdout=(own/'stdout.txt').read_bytes();stderr=(own/'stderr.txt').read_bytes()
 check('command_output_hashes',sha(stdout)==command['stdout_sha256'] and sha(stderr)==command['stderr_sha256'])
 capmatch=re.match(rb'capture=(CAP-[1-9][0-9]*-[A-Za-z0-9]+) ',stdout)
 assert capmatch,'No actual capture summary emitted; no retry.'
 cap=capmatch[1].decode();result['capture']=cap;d=s/'notes/captures'/cap
 meta_bytes=(d/'meta.nul').read_bytes();parts=meta_bytes.split(b'\0');assert parts[-1]==b'' and len(parts)%2==1
 parts=parts[:-1];assert len(set(parts[::2]))==len(parts[::2])
 meta={k.decode():v.decode() for k,v in zip(parts[::2],parts[1::2])};result['capture_metadata']=meta
 files=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']
 hashes={n:sha((d/n).read_bytes()) for n in files};result['capture_sha256']=hashes
 complete=('verification:1\n'+''.join(hashes[n]+' '+n+'\n' for n in files)).encode()
 check('seal_exact', (d/'COMPLETE').read_bytes()==complete)
 ledger=s/'notes/verification/captures'/cap
 check('ledger_matches_seal',ledger.read_bytes()==complete)
 check('no_tick_one',meta['no_tick']=='1')
 check('capture_exit_zero',meta['exit']=='0')
 check('capture_identity',meta['id']==cap and meta['sequence']==str(sequence_before+1) and cap.startswith('CAP-'+str(sequence_before+1)+'-') and meta['kind']=='command' and meta['version']=='1')
 check('input_before_expected',meta['input_before']==hashes['inputs.nul']==expected)
 check('input_after_expected',meta['input_after']==hashes['inputs-after.nul']==expected)
 output=(d/'output.log').read_bytes();summary=(d/'summary.txt').read_bytes()
 check('output_digest_and_bytes',sha(output)==meta['output_digest'] and len(output)==int(meta['output_bytes']))
 check('actual_18_of_18',meta['key'].strip()=='-- 18/18 passed' and output.decode().splitlines()[-1].strip()=='-- 18/18 passed' and b'assert:' not in output)
 check('emitted_summary_exact_one_line',stdout==summary and stdout.endswith(b'\n') and stdout.count(b'\n')==1)
 check('stderr_empty',stderr==b'')
 check('cwd_repo_exact',meta['cwd']==meta['repo']==str(cwd))
 result['summary']=summary.decode().removesuffix('\n')
 result['output_tail']=output.decode().splitlines()[-21:]
 # Fresh binding/snapshot and capture checks are read-only apart from owned outputs.
 verify_argv=['bash','-s','--',str(s),cap,str(own)]
 verify_script='''set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; cap="$2"; own="$3"
vf_binding_snapshot "$spec" "$own/current-bindings.nul" || exit 3
vf_snapshot "$(cd "$spec" && pwd -P)" "$PWD" "$PWD" "$own/current-inputs.nul" > "$own/current-source.txt" || exit 3
vf_capture_check "$spec" "$cap" "$own/current-inputs.nul" current || exit 3
vf_task_capture_matches "$own/current-bindings.nul" T029 "$spec/notes/captures/$cap" || exit 3
'''
 (own/'read-only-check.sh.txt').write_text(verify_script)
 vr=subprocess.run(verify_argv,input=verify_script.encode(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,cwd=cwd,env=os.environ.copy())
 (own/'read-only-check.stdout').write_bytes(vr.stdout);(own/'read-only-check.stderr').write_bytes(vr.stderr)
 result['read_only_check']={'argv':verify_argv,'cwd':str(cwd),'exit':vr.returncode,'stdout_sha256':sha(vr.stdout),'stderr_sha256':sha(vr.stderr)}
 check('current_capture_and_task_match',vr.returncode==0)
 check('current_source_expected',(own/'current-source.txt').read_text()==expected+'\n' and sha((own/'current-inputs.nul').read_bytes())==expected)
 current=(own/'current-bindings.nul').read_bytes();check('current_bindings_equal_capture',current==(d/'bindings.nul').read_bytes())
 fields=current.split(b'\0');assert fields[-1]==b'';fields=fields[:-1];assert len(fields)%12==0
 rows=[fields[i:i+12] for i in range(0,len(fields),12)]
 bindings=sorted({(a[1].decode(),a[7].decode()) for a in rows if a[0]==b'binding' and a[2]==b'T029'})
 want=[('FM-001','tests/test-gate-contracts.sh::test_instruction_contracts'),('INV-005','tests/test-gate-contracts.sh::test_instruction_contracts')]
 result['current_T029_bindings']=bindings;check('failure_mode_rows_match_current_bindings',bindings==want)
 tasks=[a for a in rows if a[0]==b'task' and a[2]==b'T029'];result['current_T029_task_rows']=[[v.decode() for v in a] for a in tasks]
 check('exact_argv',(d/'argv.nul').read_bytes()==b'\0'.join([meta['shell'].encode(),b'-o',b'pipefail',b'-c',b'bash tests/test-gate-contracts.sh'])+b'\0')
 prior=approval/'current-inputs.nul';check('fresh_source_matches_post_waiver_full_snapshot',sha(prior.read_bytes())==hashes['inputs.nul']==expected)
 automatic={str(s/'notes/evidence.md'),str(s/'notes/verification/sequence')}
 changed=[p for p,v in before.items() if p not in automatic and after.get(p)!=v]
 missing=sorted(set(before)-set(after));allowed_new={str(d/n) for n in files+['COMPLETE']}|{str(ledger)}
 new=sorted(set(after)-set(before));unexpected=sorted(set(new)-allowed_new)
 check('every_protected_file_hash_mode_mtime_size_unchanged',not changed and not missing)
 check('new_files_exact_capture_and_ledger',set(new)==allowed_new)
 evidence_before=(own/'evidence-before.bin').read_bytes();evidence_after=(s/'notes/evidence.md').read_bytes()
 append=('\n## '+cap+' — '+meta['end']+'\n\nCaptured run, exit '+meta['exit']+'. Full log: `notes/captures/'+cap+'/output.log`.\n\n').encode()+summary
 check('evidence_exact_automatic_append',evidence_after==evidence_before+append)
 check('sequence_exact_one_increment',(s/'notes/verification/sequence').read_bytes()==(str(sequence_before+1)+'\n').encode())
 check('automatic_file_modes_preserved',all(before[p]['mode']==after[p]['mode'] for p in automatic))
 gbefore=json.loads((own/'before-git.json').read_text());gafter={p:info(Path(p)) for p in gbefore['files'] if gbefore['files'][p] is not None};save('after-git.json',{'HEAD':git('rev-parse','HEAD').decode(),'branch':git('symbolic-ref','HEAD').decode(),'files':gafter})
 check('HEAD_branch_index_refs_bytes_modes_mtimes_unchanged',gafter==gbefore['files'] and git('rev-parse','HEAD').decode()==gbefore['HEAD'] and git('symbolic-ref','HEAD').decode()==gbefore['branch'])
 status_after=git('status','--porcelain=v1','-z','--untracked-files=all');(own/'status-after.nul').write_bytes(status_after)
 def filtered(data):
  return sorted(t for t in statuses(data) if not (t[0][3:].decode().startswith(str(own)+'/') or t[0][3:].decode() in automatic|allowed_new))
 check('preexisting_git_status_set_unchanged',filtered((own/'status-before.nul').read_bytes())==filtered(status_after))
 pending=[str(p) for base in [s/'notes/captures',s/'notes/verification'] for p in base.iterdir() if p.name=='lock' or p.name=='sequence.tmp' or p.name.startswith(('.capture.','bindings.','return.'))]
 check('no_surviving_capture_lock_or_stage',not pending)
 result['preservation']={'preexisting_file_count':len(before),'protected_file_count':len(before)-len(automatic),'changed_protected_files':changed,'missing_preexisting_files':missing,'new_files':new,'unexpected_new_files':unexpected,'pending_operations':pending,'automatic_before_after':{p:{'before':before[p],'after':after[p]} for p in automatic},'git_metadata_before':gbefore,'git_metadata_after':gafter,'preexisting_history_policy':'Every preexisting worktree file including all historical captures, ledgers, reports, accepted returns, tasks and STATUS compared by sha256/type/mode/mtime_ns/size; only exact automatic evidence append and sequence update allowed.'}
 # Read-only functions must also preserve every preexisting worktree file.
 final=inventory();final_changed=[p for p,v in after.items() if final.get(p)!=v];check('read_only_checks_preserved_worktree',not final_changed and set(final)==set(after))
 result['read_only_changed_files']=final_changed
 if all(checks.values()):
  block='Verification-Return: 1\nTask: T029\nCaptures: '+cap+'\nSummary: '+result['summary']+'\nFailure modes:\n'+''.join(a+', '+b+', '+cap+'\n' for a,b in bindings)
  raw=block.encode();assert raw.endswith(b'\n') and not raw.endswith(b'\n\n')
  (own/'worker-return.txt').write_bytes(raw)
  result['worker_return']={'path':str(own/'worker-return.txt'),'sha256':sha(raw),'bytes':len(raw),'terminal_LF_count':len(raw)-len(raw.rstrip(b'\n'))}
  result['status']='passed'
 else: result['failed_checks']=[k for k,v in checks.items() if not v]
except Exception as exc:
 result['exception']=repr(exc)
finally:
 result['verification_end']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 result['approval_result']=json.loads((approval/'result.json').read_text())
 result['T031a5o1_freshness']=json.loads((approval/'freshness-result.json').read_text())
 result['actual_current_source']=expected
 result['runtime_observed']=json.loads((approval/'runtime-observed.json').read_text())
 result['execution_count']=1
 result['live_acceptance_tick_floor_gate_CI_network_executed']=False
 result['no_minor_repair']=True
 result['historical_strict_preservation_passed']=False
 rawrefs=git('for-each-ref','--format=%(refname) %(objectname)').decode()
 result['strict_current_global_refs_preserved']=rawrefs==json.loads((own/'before-git.json').read_text())['refs']
 result['current_global_refs_after']=rawrefs
 result['limitations']=['Historical strict preservation is FALSE for unknown checkpoint refs/.DS_Store/generated verifier globalrefs; nothing restored or allowlisted.','OP27 approval only; OP26 remains CHALLENGED; quality Ship is not formal clearance.','T031a5o1 capture/acceptance historical after authorization-only source change; kernel requires refresh, not performed here.','Parent still must archive actual T3 body and incomplete FM/INV rejection then accept intact before final freeze/CI.','No OP28, RC5 or merge authority.']
 save('result.json',result)
 print(json.dumps({'status':result['status'],'capture':result.get('capture'),'checks':checks,'exception':result.get('exception'),'result':str(own/'result.json')},indent=2))
 if result['status']=='passed': print((own/'worker-return.txt').read_text(),end='')
 raise SystemExit(0 if result['status']=='passed' else 1)
