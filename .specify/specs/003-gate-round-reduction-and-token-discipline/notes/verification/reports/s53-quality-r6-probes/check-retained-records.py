from pathlib import Path
import collections,hashlib,json,os
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==root and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
r=root/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports';d=r/'s50-o034-qualified-tools-verification';p=r/'s53-quality-r6-probes'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(name):return json.loads((r/name).read_text())
records=json.loads((d/'command-records.json').read_text());proof=[]
for rec in records:
 label=rec['label'];parts={}
 for stream in ['stdout','stderr']:
  raw=(d/(label+'.'+stream)).read_bytes();parts[stream]=sha(raw)==rec[stream+'_sha256'];assert parts[stream]
 proof.append({'label':label,'exit':rec['exit'],'digests_match':parts})
green=json.loads((d/'focused-green-results.json').read_text());assert len(green['results'])==green['count']==green['passing']==41
focused=[]
for n,row in enumerate(green['results'],1):
 out=(d/f'focused-{n:02}.stdout').read_bytes();err=(d/f'focused-{n:02}.stderr').read_bytes();task=(d/f'focused-{n:02}.tasks.md').read_text();warn=b'untyped AC Verify' in out
 assert '`'+row['command']+'`' in task and warn==row['expected_warning'] and not err and row['exit']==0 and row['passed']
 assert (b'warning(s), 0 errors' if warn else b'consistent') in out
 focused.append({'command':row['command'],'group':row['group'],'observed_warning':warn,'matches':True})
reds=set(load('s47-opponent26-max-probes/attack-summary.json')['unique_omission_commands']);assert len(reds)==28
assert reds<={x['command'] for x in green['results'] if x['expected_warning']}
# Recovery command evidence is consumed, never executed.
recovery=load('s51-verification-return-recovery/command-records.json');assert not any('spec-run.sh' in str(x['argv']) or any(y in str(x['argv']) for y in ['tests/run.sh','tests/test-sdd-analyze.sh']) for x in recovery)
result={'original_command_records':proof,'original_focused_checks':focused,'all_28_OP26_distinct_omissions_covered':True,'original_capture_invocations':load('s50-o034-qualified-tools-verification/capture-invocation.json')['attempt_count'],'recovery_commands':len(recovery),'recovery_suite_or_capture_invocations':0,'consumed_existing_outputs_only':True}
with (p/'retained-records-review.json').open('x') as f:json.dump(result,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['original_command_records','original_focused_checks']},indent=2))
