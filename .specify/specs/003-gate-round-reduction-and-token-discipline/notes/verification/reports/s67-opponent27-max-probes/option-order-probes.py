from pathlib import Path
import os,json,tempfile,subprocess,hashlib
ROOT=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==ROOT and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
OUT=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s67-opponent27-max-probes'
prior=json.loads((OUT/'classifier-results.json').read_text());BASE=Path(prior['scratch'])/'case-159';SCRATCH=Path(tempfile.mkdtemp(prefix='sdd003-op27-options-',dir='/private/tmp'))
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS='0',LC_ALL='C',NO_COLOR='1',TMPDIR=str(SCRATCH))
for n in ('BASH_ENV','ENV','CDPATH'):ENV.pop(n,None)
results=[]
for prefix in ('','./tests/','tools/'):
 for redir in ('','<input.txt','>out.txt','>>out.txt','>|out.txt','<>input.txt','<&0','>&1','&>out.txt'):
  for args in ('--project tests/tsconfig.json --noEmit','--noEmit --project tests/tsconfig.json'):
   i=len(results);command=prefix+'tsc'+redir+' '+args;warn=True;iscontrol=args.startswith('--noEmit')
   d=SCRATCH/f'case-{i:03d}';spec=d/'.specify/specs/001-feature';spec.mkdir(parents=True);(d/'agents').mkdir()
   for n in ('opponent.agent.md','reality-check.agent.md'):(d/'agents'/n).write_bytes((BASE/'agents'/n).read_bytes())
   (d/'.specify/stack.yml').write_bytes((BASE/'.specify/stack.yml').read_bytes())
   for n in ('spec.md','plan.md','STATUS.md','tasks.md'):
    body=(BASE/'.specify/specs/001-feature'/n).read_text()
    if n=='tasks.md':body=body.replace('`tsc --project tests/tsconfig.json --noEmit`','`'+command+'`')
    (spec/n).write_text(body)
   argv=['/bin/bash',str(ROOT/'scripts/sdd-analyze.sh'),str(spec)]
   r=subprocess.run(argv,cwd=str(ROOT),env=ENV,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   cap=OUT/f'options-{i:03d}';cap.mkdir()
   for n,b in [('tasks.md',(spec/'tasks.md').read_bytes()),('stdout.txt',r.stdout),('stderr.txt',r.stderr)]: (cap/n).write_bytes(b)
   warning=b'task T002 has an untyped AC Verify' in r.stdout
   results.append({'index':i,'command':command,'reorderedControl':iscontrol,'expectedWarning':True,'observedWarning':warning,'asExpected':r.returncode==0 and warning,'exit':r.returncode,'argv':argv,'cwd':str(ROOT),'envOverrides':{n:ENV[n] for n in ('GIT_OPTIONAL_LOCKS','LC_ALL','NO_COLOR','TMPDIR')},'envUnset':['CDPATH','BASH_ENV','ENV'],'hashes':{n:hashlib.sha256((cap/n).read_bytes()).hexdigest() for n in ('tasks.md','stdout.txt','stderr.txt')}})
summary={'cases':len(results),'omissions':sum(not r['observedWarning'] and r['exit']==0 for r in results),'controlsWarn':all(r['asExpected'] for r in results if r['reorderedControl']),'unexpectedNonzeroExits':sum(r['exit']!=0 for r in results),'taskVerifyDataExecuted':False,'scratch':str(SCRATCH),'casesDetail':results}
with (OUT/'option-order-results.json').open('x') as f:f.write(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='casesDetail'},indent=2))
