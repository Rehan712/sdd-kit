import collections,csv,datetime,hashlib,json,os,stat,subprocess,time
from pathlib import Path
w=Path.cwd();s=w/'.specify/specs/003-gate-round-reduction-and-token-discipline';r=s/'notes/verification/reports';o=s/'notes/verification/platforms/ci-20261029-s60';p=r/'s60-evidence-preparation';scratch=Path((o/'scratch-path.txt').read_text().strip());snap=scratch/'snapshot'
assert str(w)=='/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline'
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def put(x,v):
 with x.open('x') as f:json.dump(v,f,indent=2);f.write('\n')
def run(name,argv,data=None):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic()
 invocation=dict(argv=argv,cwd=str(w),started=start,gitOptionalLocks='0')
 put(p/(name+'.invocation.json'),invocation)
 result=subprocess.run(argv,cwd=w,env=env,input=data,capture_output=True)
 (p/(name+'.stdout')).write_bytes(result.stdout);(p/(name+'.stderr')).write_bytes(result.stderr)
 put(p/(name+'.execution.json'),dict(**invocation,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-t,3),exit=result.returncode))
 assert result.returncode==0,(name,result.returncode)
 return result.stdout
assert not snap.exists() and not (p/'builder.invocation.json').exists(),'Do not retry a partial build'
result=run('builder',['/bin/bash',str(o/'build-snapshot.sh'),str(snap)])
fields=(snap/'inputs.nul').read_bytes().split(b'\0')[:-1];assert len(fields)%6==0
records=[tuple(os.fsdecode(x) for x in fields[i:i+6]) for i in range(0,len(fields),6)]
counts=dict(collections.Counter(x[0] for x in records));assert counts==dict(version=1,index=177,path=177,tool=4,harness=8,document=4),counts
source=hashlib.sha256((snap/'inputs.nul').read_bytes()).hexdigest();assert source=='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff',source
entries={}
for rec in (snap/'tree.nul').read_bytes().split(b'\0')[:-1]:
 head,path=rec.split(b'\t',1);mode,kind,oid=head.decode().split();entries[os.fsdecode(path)]=(mode,kind,oid)
raw=json.loads((o/'source-raw-before.json').read_text());assert set(raw)=={x[1] for x in records if x[0]=='path'}
rows=[]
for kind,path,value,mode,digest,target in records:
 if kind!='path':continue
 x=w/path;content=x.read_bytes();st=x.stat();baseline=raw[path];oid=hashlib.sha1(b'blob '+str(len(content)).encode()+b'\0'+content).hexdigest()
 assert value=='file' and mode==('100755' if os.access(x,os.X_OK) else '100644') and entries[path]==(mode,'blob',oid),path
 assert hashlib.sha256(content).hexdigest()==baseline['sha256'] and st.st_mtime_ns==baseline['mtime_ns'] and oct(stat.S_IMODE(st.st_mode))==baseline['mode'],path
 rows.append(dict(path=path,mode=mode,git_blob=oid,raw_sha256=baseline['sha256'],semantic_sha256=digest,bytes=len(content)))
with (o/'source-mapping.tsv').open('x') as f:
 out=csv.DictWriter(f,fieldnames=list(rows[0]),delimiter='\t',lineterminator='\n');out.writeheader();out.writerows(rows)
mapping={x['path']:x for x in rows}
for kind,path,value,mode,digest,target in records:
 if kind in ('harness','document'):
  relative=str(Path(path).relative_to(w));assert mapping[relative]['raw_sha256' if kind=='harness' else 'semantic_sha256']==value
 if kind=='tool':
  tool=Path(value);assert tool.is_file() and os.access(tool,os.X_OK) and hashlib.sha256(tool.read_bytes()).hexdigest()==mode
lines=result.decode().splitlines();tree=next(x.split('=',1)[1] for x in lines if x.startswith('tree='));parent='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9'
commit=run('commit-tree',['git','commit-tree',tree,'-p',parent],('Frozen spec003 O-034 repair, OP27 authorization and accepted T029 plus T031a5o1 CI snapshot; do not merge.\nSource: '+source+'\n').encode()).decode().strip()
summary=dict(source=source,tree=tree,commit=commit,parent=parent,tree_entries=len(entries),path_records_verified=len(rows),manifest_record_types=counts,bookkeeping_extras=len((snap/'extras.txt').read_text().splitlines()),raw_source_mapping='PASS',harness_mapping='PASS',document_mapping='PASS',tool_mapping='PASS',tree_modes=dict(collections.Counter(e[0] for e in entries.values())),scratch=str(scratch),snapshot=str(snap),manifest=str(snap/'inputs.nul'),builder_unchanged=True,freeze_proof='Single unchanged builder; all raw bytes/modes and source semantic mappings; strict verifier must match before/after',tasks_after_accept_sha256=json.loads((o/'protected-before.json').read_text())['tasks']['sha256'])
put(o/'summary.json',summary)
print(json.dumps(summary,indent=2))
