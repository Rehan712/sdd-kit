from pathlib import Path
import sys,json,os,subprocess,time
r=Path(sys.argv[1]); c=Path(sys.argv[2]); phase=sys.argv[3]; env=dict(os.environ,PATH='/usr/bin:/bin:/usr/sbin:/sbin',GIT_OPTIONAL_LOCKS='0',NO_COLOR='1'); env.pop('BASH_ENV',None); env.pop('ENV',None)
args=['/bin/bash','tests/test-sdd-analyze.sh']; start=time.time()
with (r/(phase+'-suite.stdout')).open('wb') as out,(r/(phase+'-suite.stderr')).open('wb') as err: p=subprocess.run(args,cwd=c,env=env,stdout=out,stderr=err)
text=(r/(phase+'-suite.stdout')).read_text(); result=dict(argv=args,cwd=str(c),PATH=env['PATH'],exit=p.returncode,seconds=time.time()-start,assertionFailures=text.count('assert:'),missingWeakWarnings=sum('assert:' in x and 'warns without breaking legacy missing' in x for x in text.splitlines()),wrongRunnerWarnings=sum('assert:' in x and 'has no weak executable unexpectedly' in x for x in text.splitlines()),summary=text.splitlines()[-1]); (r/(phase+'-suite.json')).write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2)); assert p.returncode==(1 if phase=='red' else 0)
