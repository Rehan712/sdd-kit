import datetime, hashlib, json, os, pathlib, re, stat, subprocess

P = pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
assert pathlib.Path.cwd() == P and os.environ['GIT_OPTIONAL_LOCKS'] == '0'
S = P/'.specify/specs/003-gate-round-reduction-and-token-discipline'
D = S/'notes/verification/reports/s61-publication'
PACK = S/'notes/verification/platforms/ci-20261029-s60'
CFG = D/'gh-config'
env = dict(os.environ, GIT_OPTIONAL_LOCKS='0', GH_CONFIG_DIR=str(CFG))
for k in ['GH_TOKEN','GITHUB_TOKEN','GH_ENTERPRISE_TOKEN','GITHUB_ENTERPRISE_TOKEN']: env.pop(k,None)
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
H = lambda b: hashlib.sha256(b).hexdigest()
def save(n,v): (D/n).write_text(json.dumps(v,indent=2)+'\n')
def info(p):
    a=p.stat(); return dict(sha256=H(p.read_bytes()),mode=stat.S_IMODE(a.st_mode),mtimeNs=a.st_mtime_ns)
def run(label,argv):
    assert not (D/(label+'.start.json')).exists(), 'Refuse repeat operation: '+label
    rec=dict(argv=argv,cwd=str(P),started=now(),envOverrides={'GIT_OPTIONAL_LOCKS':'0','GH_CONFIG_DIR':str(CFG)})
    save(label+'.start.json',rec)
    z=subprocess.run(argv,cwd=P,env=env,capture_output=True)
    (D/(label+'.stdout')).write_bytes(z.stdout); (D/(label+'.stderr')).write_bytes(z.stderr)
    rec.update(ended=now(),exit=z.returncode,stdoutSHA256=H(z.stdout),stderrSHA256=H(z.stderr));save(label+'.json',rec)
    print(json.dumps(dict(label=label,exit=z.returncode,ended=rec['ended'])),flush=True)
    assert z.returncode==0,(label,z.stderr.decode(errors='replace'))
    return z.stdout

cfg_before=H((CFG/'hosts.yml').read_bytes())
head='2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9';new='e75b3027023ef251fa0c531c96f2b8276aa980ae'
branch='refs/heads/ci-snapshot/spec-003-20261025-s26';url='https://github.com/Rehan712/sdd-kit.git'
assert run('auth-confirm',['gh','api','user','--jq','.login']).strip()==b'Rehan712'
assert run('origin-url',['git','remote','get-url','origin']).decode().strip().lower()==url.lower()
idx=pathlib.Path(run('index-path',['git','rev-parse','--git-path','index']).decode().strip())
protected=[idx,S/'STATUS.md',S/'tasks.md',P/'scripts/sdd-analyze.sh',P/'tests/test-sdd-analyze.sh',P/'tests/test-gate-contracts.sh']
before={str(p):info(p) for p in protected};save('protected.before.json',before)
assert before[str(idx)]['sha256']=='c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700'
assert before[str(S/'tasks.md')]['sha256']=='49a1dbedb00bfdab05ac1890ca06a0ee5ca6a8d54d26c2904c18337fda72d425'
assert run('head-before',['git','rev-parse','HEAD']).decode().strip()==head
assert run('branch-before',['git','branch','--show-current']).decode().strip()=='spec/003-gate-round-reduction-and-token-discipline'
refs_before=run('refs-before',['git','for-each-ref','--format=%(refname) %(objectname)'])
for n in ['inputs-after.nul','verification-final.json']:
    (D/('generated-before-'+n)).write_bytes((PACK/n).read_bytes())
run('prepublish',['/bin/bash',str(PACK/'verify-prepublish.sh')])
assert {str(p):info(p) for p in protected}==before
pr=json.loads(run('lease-pr',['gh','api','repos/Rehan712/sdd-kit/pulls/21']))
assert pr['number']==21 and pr['state']=='open' and pr['draft'] is True and pr['base']['ref']=='main'
assert pr['head']['repo']['full_name']=='Rehan712/sdd-kit' and pr['head']['ref']==branch.removeprefix('refs/heads/')
remote=run('lease-remote',['git','ls-remote','--refs',url,branch]).decode().split()
assert len(remote)==2 and remote[1]==branch and re.fullmatch('[0-9a-f]{40}',remote[0])
lease=remote[0];assert lease==pr['head']['sha']
assert lease=='25347ba729886ae0bea029c594ac00f0bc48e767','Unexpected remote edit; preserve it and inspect before publication'
save('lease.json',dict(observedAt=now(),remoteHead=lease,prHead=pr['head']['sha'],branch=branch,newHead=new,open=True,draft=True))
# Command-only authentication settings; no Git configuration file or local ref is written.
run('push',['git','-c','credential.helper=','-c','credential.helper=!gh auth git-credential','push','--force-with-lease='+branch+':'+lease,url,new+':'+branch])
published=run('remote-after',['git','ls-remote','--refs',url,branch]).decode().split()
assert published==[new,branch]
run('edit-body',['gh','pr','edit','https://github.com/Rehan712/sdd-kit/pull/21','--body-file',str(PACK/'pr-body.md')])
pr_after=json.loads(run('pr-after',['gh','api','repos/Rehan712/sdd-kit/pulls/21']))
assert pr_after['state']=='open' and pr_after['draft'] is True
after={str(p):info(p) for p in protected};save('protected.after.json',after);assert after==before
assert run('head-after',['git','rev-parse','HEAD']).decode().strip()==head
refs_after=run('refs-after',['git','for-each-ref','--format=%(refname) %(objectname)'])
assert H((CFG/'hosts.yml').read_bytes())==cfg_before
save('result.json',dict(at=now(),published=True,pushCount=1,pr='https://github.com/Rehan712/sdd-kit/pull/21',head=new,tree='f568f3a7fcdd7099bf8f9b38c676ebcdda488d2d',source='7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff',previousRemoteHead=lease,remoteConfirmed=new,prApiHead=pr_after['head']['sha'],prApiHeadMatches=pr_after['head']['sha']==new,draft=True,protectedUnchanged=True,localRefsUnchanged=refs_before==refs_after,globalAuthConfigChanged=False,rawSecretsHandled=False,authentication='Existing Rehan712 keyring via isolated GH_CONFIG_DIR; command-only git helper, direct URL prevents local tracking-ref updates',CI='pending fresh query',floorStarted=False,gateReserved=False,historicalStrictPreservation=False))
print((D/'result.json').read_text(),flush=True)
