import datetime, hashlib, json, os, pathlib, shutil, subprocess, time
ROOT=pathlib.Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline')
S=ROOT/'.specify/specs/003-gate-round-reduction-and-token-discipline'
R=S/'notes/verification/reports'
OWNED=R/'s41-floor-operation'
ENV=dict(os.environ, GIT_OPTIONAL_LOCKS='0')
CFG=json.loads((S/'notes/verification/platforms/ci-20261028-s38/parent-floor-launch.argv.json').read_text())
def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()
def write_json(path, value):
    path.write_text(json.dumps(value, indent=2)+'\n')
def main():
    assert pathlib.Path.cwd()==ROOT and CFG['cwd']==str(ROOT)
    power=subprocess.check_output(['/usr/bin/pmset','-g','batt'],cwd=ROOT,env=ENV,text=True)
    free=shutil.disk_usage(ROOT).free
    helper=pathlib.Path(CFG['helper_argv'][1])
    digest=hashlib.sha256(helper.read_bytes()).hexdigest()
    assert "'AC Power'" in power.splitlines()[0] and free>=8589934592
    assert digest=='230546a31f107962c5a72e31f8318a3e7df56375b24de68c46f76940972f0bf9'
    receipt=json.loads((OWNED/'launch-preflight.json').read_text())
    receipt.update(startedAt=utc(),wrapperPid=os.getpid(),power=power,freeBytes=free,helperSha256=digest,timedArgv=CFG['timed_argv'],cwd=str(ROOT),phase='native-timed-argv-starting')
    pathlib.Path(CFG['wrapper_pid_path']).write_text(str(os.getpid())+'\n')
    write_json(pathlib.Path(CFG['parent_receipt']['path']),receipt)
    write_json(OWNED/'phase-started.json',receipt)
    start=time.monotonic()
    result=subprocess.run(CFG['timed_argv'],cwd=ROOT,env=ENV,stdin=subprocess.DEVNULL,check=False)
    receipt.update(endedAt=utc(),exit=result.returncode,elapsedSeconds=time.monotonic()-start,phase='native-timed-argv-returned')
    pathlib.Path(CFG['wrapper_rc_path']).write_text(str(result.returncode)+'\n')
    write_json(pathlib.Path(CFG['parent_receipt']['path']),receipt)
    write_json(OWNED/'phase-completed.json',receipt)
    print(json.dumps(receipt),flush=True)
    return result.returncode
if __name__=='__main__':
    raise SystemExit(main())
