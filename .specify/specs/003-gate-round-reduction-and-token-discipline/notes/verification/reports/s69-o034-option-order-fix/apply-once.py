from pathlib import Path
import datetime, difflib, hashlib, json, os, stat, subprocess

ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert Path.cwd()==ROOT and os.environ['GIT_OPTIONAL_LOCKS']=='0'
S=Path('.specify/specs/003-gate-round-reduction-and-token-discipline');D=S/'notes/verification/reports/s69-o034-option-order-fix'
assert not (D/'application-started.json').exists()
H=lambda b:hashlib.sha256(b).hexdigest()
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(n,v):(D/n).write_text(json.dumps(v,indent=2)+'\n')
def info(p):
    st=p.lstat();return dict(mode=stat.S_IMODE(st.st_mode),mtimeNs=st.st_mtime_ns,size=st.st_size,type='symlink' if p.is_symlink() else 'file',sha256=H(os.fsencode(os.readlink(p))) if p.is_symlink() else H(p.read_bytes()))
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def git(*a):return subprocess.check_output(['git',*a],cwd=ROOT,env=env).strip()
ownership=json.loads((D/'ownership.json').read_text());red=json.loads((D/'red/result.json').read_text())
assert red['reportedWarningsMissing']==30 and red['allNativeExitsZero'] and red['reorderedControlsAllWarn']
idx=Path(git('rev-parse','--git-path','index').decode());assert info(idx)==ownership['indexBefore']
assert git('rev-parse','HEAD').decode()==ownership['HEAD']
assert git('branch','--show-current')==b'spec/003-gate-round-reduction-and-token-discipline'
paths=[Path(x) for x in ownership['ownedSourcePaths']]
before={str(p):p.read_bytes() for p in paths}
for p in paths:assert H(before[str(p)])==ownership['expectedBefore'][str(p)]
new={k:v.decode() for k,v in before.items()}
analyzer='scripts/sdd-analyze.sh';tests='tests/test-sdd-analyze.sh';tasks=str(S/'tasks.md');status=str(S/'STATUS.md')
old=r'tsc[[:space:]]+--noemit';replacement=r'^tsc[[:space:]]+([^[:space:]]+[[:space:]]+)*--noemit'
assert new[analyzer].count(old)==1;new[analyzer]=new[analyzer].replace(old,replacement)
direct="    for fixture in 'tsc --noEmit tests/unit.ts' 'npm run build' 'npm run typecheck' \\\n"
direct_new="    for fixture in 'tsc --noEmit tests/unit.ts' \\\n      'tsc --project tests/tsconfig.json --noEmit' 'tsc --pretty false --noEmit tests/unit.ts' \\\n      'npm run build' 'npm run typecheck' \\\n"
assert new[tests].count(direct)==1;new[tests]=new[tests].replace(direct,direct_new)
redirect_anchor="    for fixture in 'npm test -- --grep typecheck' 'npm run test -- --grep typecheck' \\\n"
redirect_new="""    for redirect in '<input.txt' '>out.txt' '>>out.txt' '>|out.txt' '<>input.txt' '<&0' '>&1' '&>out.txt'; do
      for fixture in 'tscREDIRECT --project tests/tsconfig.json --noEmit' \\
        'tscREDIRECT --pretty false --noEmit tests/unit.ts'; do
        weak_qualified_cases+=("$prefix${fixture%%REDIRECT*}$redirect${fixture#*REDIRECT}")
      done
    done
"""
assert new[tests].count(redirect_anchor)==1;new[tests]=new[tests].replace(redirect_anchor,redirect_new+redirect_anchor)
custom_anchor='    "${runner_redirect_cases[@]}" "${runner_qualified_cases[@]}"; do\n'
custom_new="""    'node scripts/assert-options.js --noEmit tests/unit.ts' \\
    'node scripts/assert-options.js tsc --project tests/tsconfig.json --noEmit' \\
    'node scripts/assert-options.js tsc --pretty false --noEmit tests/unit.ts' \\
    'node scripts/assert-options.js tsc --noEmit' \\
"""
assert new[tests].count(custom_anchor)==1;new[tests]=new[tests].replace(custom_anchor,custom_new+custom_anchor)
reconstructed=new[tests].replace(direct_new,direct).replace(redirect_new,'').replace(custom_new,'')
assert reconstructed.encode()==before[tests], 'Every earlier test byte must remain after removing only the additions'
a=new[tasks].index('- [x] **T031a5o1**');b=new[tasks].index('\n- [',a+1);block=new[tasks][a:b]
block=block.replace('- [x] **T031a5o1**','- [ ] **T031a5o1**',1)
assert block.count('tsc --noEmit,')==1
block=block.replace('tsc --noEmit,','tsc --noEmit with ordinary preceding --project/--pretty options,',1)
block=block.replace('all prior 287 weak/162 clean cases','all prior 396 weak/250 clean cases',1)
lines=block.splitlines(True);old_notes=[l for l in lines if l.startswith('  - *Notes:*')];old_ev=[l for l in lines if l.startswith('  - *Evidence:*')]
assert len(old_notes)==len(old_ev)==1 and 'CAP-845-hwbWOH' in old_ev[0]
note='  - *Notes:* O-034 remains open after sealed and tallied formal opponent round 27 (Prior O-034, verification-command-classification, wrong-result, implementation-error; Blocks AC-004/REQ-005). Match the normalized direct tsc executable and allow ordinary words before --noEmit, without treating a tsc operand inside a custom assertion as the executable. Retain all earlier path, redirect, numeric, operand, runner and explicit-kind controls; add both reproduced option orders across the seven known executable prefixes and eight redirects, plus custom assertion operand controls. The same T031a5o1 is reopened for fresh no-tick verification and acceptance; its exact previous task/source/Evidence bytes are archived under notes/verification/reports/s69-o034-option-order-fix/before/. OP27 and all earlier reports remain sealed historical evidence. O-032 and recorded minor follow-ups remain open and unchanged. No OP28, RC5 or merge authorization is granted by this repair.\n'
block=block.replace(old_notes[0],note).replace(old_ev[0],'')
new[tasks]=new[tasks][:a]+block+new[tasks][b:]
ts=now();heading='## Decisions log\n';start=new[status].index(heading);end=new[status].index('\n## ',start+len(heading))
decision=('\n- '+ts+' — O-034 continuation after formal OP27 was completed and tallied once, native exits 0/0, report sha256 9425b8f8f0db0c24895a9bdbf9479abe49e9216489508fc7be0e3bd111109479, source 7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff / FLOOR-DJZyNl. The actual verdict remains CHALLENGED, O-034 blocking and O-032 minor; wrapper exit 1 and unknown-actor FETCH_HEAD/origin-directory mtime differences are retained in notes/verification/reports/s68-op27-sealing/. This entry continues the same ongoing O-034 repair; it records an implementation decision and is not a new user authorization. Before editing source, the parent reproduced all 30 distinct reported option-order omissions and all 27 reordered positive controls through the unmodified public analyzer (notes/verification/reports/s69-o034-option-order-fix/red/). The four custom-assertion operand controls also exposed one preexisting unanchored tsc false warning. Repair only the shared direct-tsc predicate and its public regression declarations, preserving prior known-basename/redirect/runner behavior and all earlier tests. Reopen the same T031a5o1 and archive its prior Evidence rather than overwrite historical returns. Use codex / gpt-6.1-sol HIGH for execution and MAX for independent quality, default tier, under the existing explicit provider transition. The input identity changes; old source-bound captures, hosted CI and floor are historical after this batch. Obtain fresh genuine no-tick verification and intact acceptance, then independent MAX quality before asking for exact OP28-after-completed-OP27 authorization under REQ-012. No OP28 waiver or reservation, RC5, merge, minor-finding repair or cleanup is authorized here. RC4 after3 and the same-repair temporary draft PR21 refresh remain standing approvals, but RC4 cannot proceed without formal opponent clearance. Decisions freeze after this repair batch through its verification and quality pass; a later exact-round user approval is still required before another gate-proof refresh. Original failures, raw returned-body comparisons and strict historical preservation FALSE remain unchanged.\n')
new[status]=new[status][:end]+decision+new[status][end:]
assert new[status].replace(decision,'',1).encode()==before[status]
save('application-started.json',dict(at=ts,oldHashes={k:H(v) for k,v in before.items()},newHashes={k:H(v.encode()) for k,v in new.items()},OP27SealedBeforeRepair=True,OP28Authorized=False))
# Record the closed gate and repair decision before applying code and task changes.
for name in [status,analyzer,tests,tasks]:
    p=Path(name);old_mode=info(p)['mode'];p.write_bytes(new[name].encode());assert info(p)['mode']==old_mode
    save('applied-'+p.name+'.json',dict(at=now(),path=name,after=info(p)))
diff=''.join(''.join(difflib.unified_diff(before[k].decode().splitlines(True),new[k].splitlines(True),fromfile='before/'+k,tofile=k)) for k in [analyzer,tests,tasks,status])
(D/'repair.diff').write_text(diff)
assert info(idx)==ownership['indexBefore'] and git('rev-parse','HEAD').decode()==ownership['HEAD']
files={}
for root,dirs,names in os.walk('.',followlinks=False):
    for n in list(dirs):
        p=Path(root)/n
        if p==D:dirs.remove(n)
        elif p.is_symlink():files[str(p)]=info(p);dirs.remove(n)
    for n in names:
        p=Path(root)/n;files[str(p)]=info(p)
baseline=json.loads((D/'inventory.before.json').read_text());changes={k:dict(before=v,after=files.get(k)) for k,v in baseline.items() if files.get(k)!=v}
unexpected={k:v for k,v in changes.items() if k not in new};added=sorted(set(files)-set(baseline));missing=sorted(set(baseline)-set(files))
save('inventory.after.json',files)
refs=git('for-each-ref','--format=%(refname) %(objectname)')+b'\n';(D/'refs.after.txt').write_bytes(refs)
result=dict(at=now(),ownedChanges={k:info(Path(k)) for k in new},changedPreexisting=changes,unexpectedPreexistingChanges=unexpected,unexpectedAdditions=added,missingPreexisting=missing,allOtherOriginalWorktreeEntriesPreserved=not unexpected and not added and not missing,realHEADIndexPreserved=True,globalRefsUnchanged=refs==(D/'refs.before.txt').read_bytes(),allPriorTestBytesRetained=True,expectedAddedWeakDeclarations=126,expectedAddedCustomAssertionControls=4,OP27RemainsChallenged=True,OP28Authorized=False,minorRepairs=False,acceptanceOrCaptureRun=False,historicalStrictPreservation=False,newNormalizedSource='not yet derived; next genuine kernel capture must compute it')
save('application.json',result)
print(json.dumps({k:v for k,v in result.items() if k!='changedPreexisting'},indent=2),flush=True)
assert not unexpected and not added and not missing
