import datetime,hashlib,json,os,re,subprocess,time
from pathlib import Path
root=Path.cwd();a=Path(__file__).resolve().parent;p=a.parent
assert str(root)=="/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline"
head="616dd2d1bb0f3eb16045821b0b30b9c9b40f2395";tree="e68740dbbf9d10e3abcdfd0c6620ed9c3abd04e1";source="16ffcec3c2f0cffa21b8c35e7b90d768a27bdfdd37deba9147edd25489946494"
assert json.loads((a/"verify-before-execution.json").read_text())["exit"]==0
assert json.loads((a/"verification-before.json").read_text())["source"]==source
clean={k:v for k,v in os.environ.items() if k in ("PATH","HOME","TMPDIR","LANG","LC_ALL","SHELL","USER","LOGNAME")};clean["GIT_OPTIONAL_LOCKS"]="0"
steps=[]
def run(name,argv,env):
 started=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic()
 r=subprocess.run(argv,cwd=root,env=env,capture_output=True)
 # GH_TOKEN is never included in receipts, argv, diagnostic output, or files.
 assert not token or token not in r.stdout+r.stderr,"credential unexpectedly present in output"
 (a/(name+".stdout")).write_bytes(r.stdout);(a/(name+".stderr")).write_bytes(r.stderr)
 steps.append(dict(name=name,argv=argv,started=started,ended=datetime.datetime.now(datetime.timezone.utc).isoformat(),seconds=round(time.monotonic()-t,3),exit=r.returncode))
 (a/"network-execution.json").write_text(json.dumps(steps,indent=2)+"\n")
 assert r.returncode==0,name+" failed"
 return r.stdout
# Capture credential only in memory, with no inherited debug or trace environment.
token=b""
auth=subprocess.run(["gh","auth","token","--hostname","github.com","--user","Rehan712"],cwd=root,env=clean,capture_output=True)
assert auth.returncode==0 and auth.stdout.strip(),"stored credential retrieval failed"
token=auth.stdout.strip();net=dict(clean,GH_TOKEN=token.decode())
try:
 endpoint="repos/Rehan712/sdd-kit/actions/runs?head_sha="+head+"&event=pull_request&per_page=50"
 runs=json.loads(run("actions-runs-discovery",["gh","api",endpoint],net))
 candidates=[r for r in runs["workflow_runs"] if r["head_sha"]==head and r["event"]=="pull_request" and r["path"]==".github/workflows/ci.yml"]
 assert len(candidates)==1,"expected exactly one CI workflow run for exact head; no polling"
 discovered=candidates[0];assert discovered["status"]=="completed" and discovered["conclusion"]=="success","exact-head CI is not completed success"
 runid=discovered["id"]
 (a/"selected-run.json").write_text(json.dumps(discovered,indent=2)+"\n")
 hosted=a/"hosted";assert not hosted.exists()
 diagnostics=run("collector",["bash",str(p/"collect.sh"),str(runid),str(hosted),head],net)
 assert b"collect result: PASS" in diagnostics and b"FAIL:" not in diagnostics,"collector did not report PASS"
 actual=json.loads((hosted/"run.json").read_text());jobs=json.loads((hosted/"jobs.json").read_text())
 assert actual["id"]==runid and actual["run_attempt"]==discovered["run_attempt"] and actual["workflow_id"]==discovered["workflow_id"]
 assert actual["status"]=="completed" and actual["conclusion"]=="success" and actual["head_sha"]==head and actual["event"]=="pull_request"
 assert actual["path"]==".github/workflows/ci.yml"
 expected={"shellcheck","tests (ubuntu-latest)","tests (macos-latest)","tests-bash32"}
 assert jobs["total_count"]==len(jobs["jobs"])==4 and {j["name"] for j in jobs["jobs"]}==expected
 bound=[];merges=set()
 for j in jobs["jobs"]:
  assert j["status"]=="completed" and j["conclusion"]=="success" and j["run_id"]==runid
  safe=re.sub(r"[^A-Za-z0-9._-]","_",j["name"]);log=hosted/("job-"+safe+".log");raw=log.read_bytes()
  fetched=set(re.findall(rb"git -c protocol.version=2 fetch [^\r\n]*?\+?([0-9a-f]{40}):refs/remotes/pull/21/merge",raw))
  assert len(fetched)==1,(j["name"],"exactly one tested merge SHA required")
  merge=next(iter(fetched)).decode();merges.add(merge)
  checked=set(x.decode() for x in re.findall(rb"HEAD is now at ([0-9a-f]+)",raw))
  assert len(checked)==1 and merge.startswith(next(iter(checked))),"checkout does not bind fetched merge"
  # Checkout's final rev-parse output is the full SHA actually at HEAD.
  assert re.search(rb"\[command\][^\r\n]*git log -1 --format=%H\r?\n[^\r\n]*"+merge.encode(),raw),"missing full checked-out HEAD confirmation"
  bound.append(dict(id=j["id"],name=j["name"],status=j["status"],conclusion=j["conclusion"],url=j["html_url"],started_at=j["started_at"],completed_at=j["completed_at"],runner_name=j["runner_name"],labels=j["labels"],merge_sha=merge,checkout_short=next(iter(checked)),raw_log=str(log),raw_log_sha256=hashlib.sha256(raw).hexdigest(),raw_log_bytes=len(raw),ansi_escape_bytes=raw.count(b"\x1b")))
 assert len(merges)==1,"matrix jobs tested different merge SHAs"
 merge=next(iter(merges));commit=json.loads(run("tested-merge-commit",["gh","api","repos/Rehan712/sdd-kit/git/commits/"+merge],net))
 assert commit["sha"]==merge and commit["tree"]["sha"]==tree and head in [x["sha"] for x in commit["parents"]]
 pr=json.loads(run("current-pr21",["gh","api","repos/Rehan712/sdd-kit/pulls/21"],net))
 assert pr["head"]["sha"]==head and pr["state"]=="open" and pr["draft"] is True and pr["number"]==21
 result=dict(status="HOSTED_PASS_PENDING_AFTER_CHECK",run_id=runid,attempt=actual["run_attempt"],workflow_id=actual["workflow_id"],workflow_path=actual["path"],url=actual["html_url"],run_status=actual["status"],run_conclusion=actual["conclusion"],run_created_at=actual["created_at"],run_updated_at=actual["updated_at"],head=head,source=source,tree=tree,merge_sha=merge,merge_tree=commit["tree"]["sha"],merge_parents=[x["sha"] for x in commit["parents"]],collector_exit=0,collector_report="PASS",jobs=bound,current_pr=dict(url=pr["html_url"],state=pr["state"],draft=pr["draft"],head=pr["head"]["sha"],base=pr["base"]["sha"],merge_commit_sha=pr["merge_commit_sha"]),network_complete_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),credential_handling="stored Rehan712 credential held only in memory; GH_TOKEN supplied only to scoped network subprocesses; no global auth switch",limits=["Current AC019 hosted evidence only; formal readiness not established.","No CI rerun, floor, capture, control, tests, gates, Git mutation, PR edit, merge, watch, or polling performed."])
 (a/"network-result.json").write_text(json.dumps(result,indent=2)+"\n")
 print(json.dumps({k:result[k] for k in ("status","run_id","attempt","url","head","merge_sha","merge_tree","collector_exit")}))
finally:
 net.pop("GH_TOKEN",None);token=b"";auth=None
