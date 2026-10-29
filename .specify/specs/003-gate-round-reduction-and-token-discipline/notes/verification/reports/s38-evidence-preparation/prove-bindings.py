import csv,datetime,hashlib,json,os,subprocess
from pathlib import Path
w=Path.cwd();s=w/'.specify/specs/003-gate-round-reduction-and-token-discipline';v=s/'notes/verification';r=v/'reports';p=r/'s38-evidence-preparation';o=v/'platforms/ci-20261028-s38'
assert str(w)=='/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline'
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
def put(path,data):
 with path.open('x') as f:json.dump(data,f,indent=2);f.write('\n')
def sha(data):return hashlib.sha256(data).hexdigest()
summary=json.loads((o/'summary.json').read_text());snap=Path(summary['snapshot']);control=json.loads((r/'s37-t029-control/result.json').read_text())
assert datetime.datetime.fromisoformat(json.loads((p/'builder.invocation.json').read_text())['started'])>datetime.datetime.fromisoformat(control['ended'])
seals=[]
for relative,required in [('accept-events/ACCEPT-0LHiyU',{'meta.nul'}),('accept-events/ACCEPT-1F42D0',{'meta.nul'}),('accepted/T029/ACC-5OLy1X',{'meta.nul','return.txt','tasks.after','digests.nul'})]:
 base=v/relative;lines=(base/'COMPLETE').read_text().splitlines();assert lines[0]=='verification:1';actual={}
 for line in lines[1:]:
  digest,name=line.split(' ',1);assert name in required and name not in actual
  assert sha((base/name).read_bytes())==digest;actual[name]=digest
 assert set(actual)==required
 if relative.startswith('accepted/'):
  assert (base/'COMMITTED').read_text().strip()==sha((base/'COMPLETE').read_bytes())
  assert (base/'tasks.after').read_bytes()==(s/'tasks.md').read_bytes()
 seals.append(dict(path=relative,completeSha256=sha((base/'COMPLETE').read_bytes()),members=actual))
fields=(snap/'inputs.nul').read_bytes().split(b'\0')[:-1];assert len(fields)%6==0
records=[[os.fsdecode(x) for x in fields[i:i+6]] for i in range(0,len(fields),6)]
argv=['git','ls-files','--stage','-z'];raw=subprocess.check_output(argv,cwd=w,env=env);(p/'actual-index-stage.nul').write_bytes(raw)
put(p/'actual-index-stage.invocation.json',dict(argv=argv,cwd=str(w),gitOptionalLocks='0',exit=0))
index={}
for rec in raw.split(b'\0')[:-1]:
 header,path=rec.split(b'\t',1);mode,oid,stage=header.decode().split();index[os.fsdecode(path)]=(mode,oid,stage)
rows=[]
for kind,path,mode,stage,semantic,target in records:
 if kind!='index':continue
 actual_mode,oid,actual_stage=index[path];assert (actual_mode,actual_stage)==(mode,stage)
 blob=subprocess.check_output(['git','cat-file','blob',oid],cwd=w,env=env)
 assert hashlib.sha1(b'blob '+str(len(blob)).encode()+b'\0'+blob).hexdigest()==oid
 rows.append(dict(path=path,mode=mode,stage=stage,git_blob=oid,raw_sha256=sha(blob),semantic_sha256=semantic,bytes=len(blob)))
assert len(rows)==177 and len({x['path'] for x in rows})==177
with (o/'index-mapping.tsv').open('x') as f:
 writer=csv.DictWriter(f,fieldnames=list(rows[0]),delimiter='\t',lineterminator='\n');writer.writeheader();writer.writerows(rows)
before=(p/'status-before.nul').read_bytes();argv=['git','status','--porcelain=v1','-z','--untracked-files=all'];after=subprocess.check_output(argv,cwd=w,env=env);(p/'status-after.nul').write_bytes(after)
put(p/'status-after.invocation.json',dict(argv=argv,cwd=str(w),gitOptionalLocks='0',exit=0))
special=str((r/'s38-evidence-preparation-invocation.json').relative_to(w));prefixes=[str(o.relative_to(w))+'/',str(p.relative_to(w))+'/'];floor=str((r/'s38-final-floor.sh').relative_to(w))
def statusset(data):
 records=set(data.split(b'\0')[:-1]);assert all(len(x)>3 and x[2:3]==b' ' for x in records),'Unexpected rename format: inspect instead of dropping records'
 return {x for x in records if not (os.fsdecode(x[3:]).startswith(tuple(prefixes)) or os.fsdecode(x[3:]) in (floor,special))}
assert statusset(before)==statusset(after),'Preexisting status set changed'
initial=json.loads((p/'initial-verification.json').read_text());existing=json.loads((p/'preexisting-files.json').read_text())
assert initial['parentInvocationPresentAtBaseline']==(special in existing)
put(p/'supplemental-binding-proof.json',dict(result='PASS',snapshotAfterCompletedT029Control=True,tasksAfterAcceptBaseline=control['afterAccept']['tasks'],currentTasksSha256=sha((s/'tasks.md').read_bytes()),sealedAcceptReceipts=seals,indexRawBlobMappings=177,indexMapping=str(o/'index-mapping.tsv'),manifestIndexSemanticRecords=177,preexistingStatusSetUnchanged=True,parentOnlyConcurrentNewPath=special,parentInvocationPresentAtBaseline=special in existing,collectorTransport='Actual donor invokes gh API through collect.sh, which already includes --allow-escape-sequences for raw logs. No HTTP transport rewrite.',prohibitedActionsExecuted=False))
print(json.dumps(dict(result='PASS',indexRawBlobMappings=len(rows),sealedReceipts=len(seals),statusSet='UNCHANGED',afterCompletedControl=True)))
