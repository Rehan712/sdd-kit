import os,sys,json,subprocess,time
from pathlib import Path
r=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
o=Path(__file__).parent
label=sys.argv[1];argv=sys.argv[2:]
env={**os.environ,'TMPDIR':str(o/'tmp'),'PATH':str(o/'bin')+':'+os.environ['PATH'],'GIT_OPTIONAL_LOCKS':'0','NO_COLOR':'1'}
start=time.time()
with (o/(label+'.stdout')).open('w') as stdout,(o/(label+'.stderr')).open('w') as stderr:
 p=subprocess.run(argv,cwd=r,env=env,stdout=stdout,stderr=stderr)
record={'argv':argv,'cwd':str(r),'environment':{k:env[k] for k in ['TMPDIR','PATH','GIT_OPTIONAL_LOCKS','NO_COLOR']},'exit':p.returncode,'elapsed_seconds':time.time()-start}
(o/(label+'.json')).write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record))
