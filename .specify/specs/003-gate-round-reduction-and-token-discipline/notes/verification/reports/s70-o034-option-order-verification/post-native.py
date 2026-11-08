import os,json,subprocess,datetime,re,hashlib
from pathlib import Path
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==root
s=root/'.specify/specs/003-gate-round-reduction-and-token-discipline';o=s/'notes/verification/reports/s70-o034-option-order-verification';env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
record=json.load(open(o/'native-result.json'));assert record['nativeExit']==0,record
raw=(o/'native.stdout').read_bytes();m=re.fullmatch(rb'capture=(CAP-[1-9][0-9]*-[A-Za-z0-9]+) [^\r\n]*\n',raw);assert m,raw
cap=m.group(1).decode();assert cap.startswith('CAP-866-'),cap
(o/'actual-capture.txt').write_text(cap+'\n')
argv=['/bin/bash',str(o/'kernel-observe.sh'),'after',cap]
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (o/'kernel-after.stdout').open('xb') as out,(o/'kernel-after.stderr').open('xb') as err:
 p=subprocess.Popen(argv,cwd=root,env=env,stdout=out,stderr=err)
 (o/'kernel-after-started.json').write_text(json.dumps({'argv':argv,'cwd':str(root),'pid':p.pid,'started':start,'envOverrides':{'GIT_OPTIONAL_LOCKS':'0'}},indent=2)+'\n')
 rc=p.wait()
(o/'kernel-after-result.json').write_text(json.dumps({'exit':rc,'ended':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
print(json.dumps({'exit':rc,'capture':cap,'sourceAfter':(o/'source-after.txt').read_text() if (o/'source-after.txt').exists() else None,'stderr':(o/'kernel-after.stderr').read_text()}),flush=True)
