import datetime,hashlib,json,pathlib,re,stat,os,subprocess,sys
ROOT=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert pathlib.Path.cwd()==ROOT
SPEC=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline';OWN=SPEC/'notes/verification/reports/s29-t029-worker-retry2'
p=OWN/'result.json';raw=p.read_bytes();result=json.loads(raw)
assert result['run_count']==1
(OWN/'result-initial-check.json').write_bytes(raw)
cap=SPEC/'notes/captures'/result['capture'];meta=result['metadata'];checks=result['checks']
files=['meta.nul','argv.nul','inputs.nul','inputs-after.nul','bindings.nul','output.log','summary.txt']
sha=lambda b:hashlib.sha256(b).hexdigest()
expected='verification:1\n'+''.join(sha((cap/f).read_bytes())+' '+f+'\n' for f in files)
checks['complete_seal_matches']=(cap/'COMPLETE').read_text()==expected
result['receipt_checker_correction']='Initial receipt checker treated COMPLETE version header as a digest row; this finalizer checks exact verification:1 header and ordered seven-file seal. No verification command was rerun.'
historical=SPEC/'notes/verification/rounds/opponent/ROUND-24/meta.nul'
f=historical.read_bytes().split(b'\0');old={f[i].decode():f[i+1].decode() for i in range(0,len(f)-1,2)}
checks['new_source_not_c7']=meta['input_before']!=old['source'];result['historical_c7_source']=old['source']
# Independently verify the emitted command and binding record against the declared task.
argv=(cap/'argv.nul').read_bytes().split(b'\0');assert argv.pop()==b''
checks['captured_declared_command']=argv[1:]==[b'-o',b'pipefail',b'-c',b'bash tests/test-gate-contracts.sh']
checks['captured_cwd']=meta['cwd']==str(ROOT) and meta['repo']==str(ROOT)
tasks=(SPEC/'tasks.md').read_text();section=tasks.split('- [x] **T029**',1)[1].split('\n- [',1)[0].split('\n## ',1)[0]
checks['task_declares_requested_tests']='*Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`' in section
checks['task_declares_both_refs']=all(i in section.split('*Refs:*',1)[1].split('\n',1)[0] for i in ['FM-001','INV-005'])
plan=(SPEC/'plan.md').read_text();checks['plan_permits_both_guidance_bindings']=all(any(line.startswith('| '+id+' |') and 'guidance' in line for line in plan.splitlines()) for id in ['FM-001','INV-005']) and any(line.startswith('| guidance | test |') and 'tests/test-gate-contracts.sh::test_instruction_contracts' in line for line in plan.splitlines())
grammar=(ROOT/'templates/verification-contract.md').read_text();checks['grammar_contains_return_shape']=all(line in grammar for line in ['Verification-Return: 1','Captures: CAP-1-example','Summary: <exact complete summary.txt line from this capture>','Failure modes:'])
# Preserve raw protected bytes, mode and nanosecond modification times through final handback.
after=json.loads((OWN/'after-state.json').read_bytes());changes=[]
for name,r in after['protected'].items():
 f=pathlib.Path(r['path']);s=f.lstat();observed={'sha256':sha(f.read_bytes()),'mode':format(stat.S_IMODE(s.st_mode),'04o'),'mtime_ns':s.st_mtime_ns,'size':s.st_size}
 if any(observed[k]!=r[k] for k in observed):changes.append({'name':name,'observed':observed,'expected':r})
checks['protected_still_unchanged_at_handback']=not changes
checks['head_still_unchanged_at_handback']=subprocess.check_output(['git','--no-optional-locks','rev-parse','HEAD'],cwd=ROOT).decode().strip()=='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
checks['no_verification_lock_at_handback']=not os.path.lexists(SPEC/'notes/verification/lock')
result['final_protected_changes']=changes;result['finalized_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();result['success']=all(checks.values())
result['skipped']='Floor validation, formal gates, CI, acceptance, task ticking, Git mutations, and source edits were not performed by this worker.'
if result['success']:
 summary=(OWN/'stdout.log').read_bytes();assert summary.endswith(b'\n') and summary.count(b'\n')==1
 block=('Verification-Return: 1\nTask: T029\nCaptures: '+result['capture']+'\nSummary: '+summary.decode().rstrip('\n')+'\nFailure modes:\nFM-001, tests/test-gate-contracts.sh::test_instruction_contracts, '+result['capture']+'\nINV-005, tests/test-gate-contracts.sh::test_instruction_contracts, '+result['capture']+'\n')
 (OWN/'worker-return.txt').write_bytes(block.encode())
 result['worker_return']={'path':str(OWN/'worker-return.txt'),'sha256':sha(block.encode()),'bytes':len(block.encode()),'one_terminal_LF':block.endswith('\n') and not block.endswith('\n\n')}
with p.open('w') as f:json.dump(result,f,indent=2,sort_keys=True);f.write('\n')
print(json.dumps({'success':result['success'],'run_count':result['run_count'],'exit':result['exit'],'capture':result['capture'],'checks':checks,'elapsed_seconds':result['elapsed_seconds']}))
if result['success']:print((OWN/'worker-return.txt').read_text(),end='')
sys.exit(0 if result['success'] else 1)
