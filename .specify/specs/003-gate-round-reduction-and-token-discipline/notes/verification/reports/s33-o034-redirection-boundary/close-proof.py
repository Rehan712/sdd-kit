from pathlib import Path
import os,json,subprocess,hashlib,stat,shutil,collections
r=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s33-o034-redirection-boundary'); b=json.loads((r/'baseline.json').read_text()); c=Path(b['candidate']); env=dict(os.environ,PATH='/usr/bin:/bin:/usr/sbin:/sbin',GIT_OPTIONAL_LOCKS='0'); env.pop('SHELLCHECK_OPTS',None)
checks=[('bash-version',['/bin/bash','--version']),('analyzer-syntax',['/bin/bash','-n','scripts/sdd-analyze.sh']),('tests-syntax',['/bin/bash','-n','tests/test-sdd-analyze.sh']),('shellcheck',['/opt/homebrew/bin/shellcheck','--norc','-S','warning','-x','scripts/sdd-analyze.sh','tests/test-sdd-analyze.sh']),('tasks-analyzer',['/bin/bash','scripts/sdd-analyze.sh',str(c/'.specify/specs/003-gate-round-reduction-and-token-discipline'),'--phase','tasks']),('candidate-whitespace',['git','diff','--check'])]
for name,args in checks:
 p=subprocess.run(args,cwd=c,env=env,capture_output=True); (r/(name+'.stdout')).write_bytes(p.stdout); (r/(name+'.stderr')).write_bytes(p.stderr); (r/(name+'.json')).write_text(json.dumps(dict(argv=args,cwd=str(c),PATH=env['PATH'],SHELLCHECK_OPTS='unset',exit=p.returncode),indent=2)+'\n'); print(name,p.returncode); assert p.returncode==0,(name,p.stdout,p.stderr)
p=subprocess.run(['git','diff','--binary','--',*b['owned']],cwd=c,env=env,capture_output=True,check=True); (r/'candidate.patch').write_bytes(p.stdout)
# Expand both lists using their actual Bash declarations and confirm retention.
def cases(s,init=''):
 pos=s.index('  # AC-004/O-034:'); loops=[]
 for label in ['weak','clean']:
  a=s.index('  for fixture in ',pos); z=s.index('; do\n',a)+len('; do\n'); loops.append(s[a:z]+'    printf "'+label+'\\t%s\\0" "$fixture"\n  done\n'); pos=s.index('\n  done',z)+7
 script='collect() {\n'+init+''.join(loops)+'}\ncollect\n'; p=subprocess.run(['/bin/bash'],input=script.encode(),cwd=c,env=env,capture_output=True,check=True); return [dict(zip(['kind','command'],x.decode().split('\t',1))) for x in p.stdout.split(b'\0') if x],script
s=(c/'tests/test-sdd-analyze.sh').read_text(); start=s.index('  # O-034: simple'); end=s.index('  # AC-004/O-034:',start); new,script=cases(s,s[start:end]); old,_=cases((r/'before/tests/test-sdd-analyze.sh').read_text()); (r/'expand-declarations.sh').write_text(script); (r/'cases.json').write_text(json.dumps(new,indent=2)+'\n'); count=lambda xs:collections.Counter((x['kind'],x['command']) for x in xs); assert not count(old)-count(new)
coverage=dict(baseline={k:sum(x['kind']==k for x in old) for k in ['weak','clean']},candidate={k:sum(x['kind']==k for x in new) for k in ['weak','clean']},allPriorDeclarationsRetained=True,explicitKinds=['test','assertion','static','manual']); (r/'coverage.json').write_text(json.dumps(coverage,indent=2)+'\n')
changed=sorted(x.decode() for x in subprocess.check_output(['git','diff','--name-only','-z'],cwd=c,env=env).split(b'\0') if x); assert changed==sorted(b['owned']),changed
for rel in b['owned']:
 dst=r/'after'/rel; dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(c/rel,dst)
meta=lambda p:dict(sha256=hashlib.sha256(p.read_bytes()).hexdigest(),mode=oct(stat.S_IMODE(p.stat().st_mode)),mtime_ns=p.stat().st_mtime_ns,bytes=p.stat().st_size)
after={rel:meta(c/rel) for rel in b['owned']}; manifest=''.join(after[p]['sha256']+'  '+p+'\n' for p in b['owned']); (r/'candidate-files.sha256').write_text(manifest); result=dict(files=after,patch=meta(r/'candidate.patch'),candidateManifestSha256=hashlib.sha256(manifest.encode()).hexdigest(),changedPaths=changed,physicalTaskMode='0600',gitTaskIndexMode='100644',editingBatch='closed'); (r/'owned-after.json').write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))
# No source edits after this closure. The live apply check and integrity read run separately in the worktree.
