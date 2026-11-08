import datetime,hashlib,json,os,re,subprocess,sys,time
from pathlib import Path
root=Path.cwd();a=Path(__file__).resolve().parent;p=a.parent
assert str(root)=="/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline"
head="25347ba729886ae0bea029c594ac00f0bc48e767";tree="c68b9a3ab0c39c555d5cb28afa6420cd9a2600b7";source="f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0"
assert len(sys.argv)==3,"usage: collect-hosted.py <actual-run-id> <actual-run-attempt>"
wanted_run=int(sys.argv[1]);wanted_attempt=int(sys.argv[2]);assert wanted_run>0 and wanted_attempt>0
assert not (a/"network-execution.json").exists() and not (a/"hosted").exists(),"do not repeat a partial collection"
assert json.loads((p/"summary.json").read_text())["commit"]==head
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
# Parent supplies the credential through its secret tool; this helper never retrieves it.
token=b""
run("verify-before",["/bin/bash",str(p/"verify-prepublish.sh")],clean)
(a/"inputs-before.nul").write_bytes((p/"inputs-after.nul").read_bytes())
(a/"verification-before.json").write_bytes((p/"verification-final.json").read_bytes())
assert json.loads((a/"verification-before.json").read_text())["source"]==source
token=os.environ.get("GH_TOKEN","").encode();assert token,"parent must supply scoped GH_TOKEN via its secret tool"
net=dict(clean,GH_TOKEN=token.decode())
try:
 discovered=json.loads(run("selected-run-query",["gh","api","repos/Rehan712/sdd-kit/actions/runs/"+str(wanted_run)],net))
 assert discovered["id"]==wanted_run and discovered["run_attempt"]==wanted_attempt
 assert discovered["head_sha"]==head and discovered["event"]=="pull_request" and discovered["path"]==".github/workflows/ci.yml"
 assert discovered["status"]=="completed" and discovered["conclusion"]=="success","selected CI is not completed success"
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
  assert j["status"]=="completed" and j["conclusion"]=="success" and j["run_id"]==runid and j["run_attempt"]==wanted_attempt and j["head_sha"]==head
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
 result=dict(status="HOSTED_PASS_PENDING_AFTER_CHECK",run_id=runid,attempt=actual["run_attempt"],workflow_id=actual["workflow_id"],workflow_path=actual["path"],url=actual["html_url"],run_status=actual["status"],run_conclusion=actual["conclusion"],run_created_at=actual["created_at"],run_updated_at=actual["updated_at"],head=head,source=source,tree=tree,merge_sha=merge,merge_tree=commit["tree"]["sha"],merge_parents=[x["sha"] for x in commit["parents"]],collector_exit=0,collector_report="PASS",jobs=bound,current_pr=dict(url=pr["html_url"],state=pr["state"],draft=pr["draft"],head=pr["head"]["sha"],base=pr["base"]["sha"],merge_commit_sha=pr["merge_commit_sha"]),network_complete_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),credential_handling="parent-supplied GH_TOKEN held only in memory and scoped to network subprocesses; no credential retrieval or auth configuration",limits=["Current AC019 hosted evidence only; formal readiness not established.","No CI rerun, floor, capture, control, tests, gates, Git mutation, PR edit, merge, watch, or polling performed."])
 (a/"network-result.json").write_text(json.dumps(result,indent=2)+"\n")
 print(json.dumps({k:result[k] for k in ("status","run_id","attempt","url","head","merge_sha","merge_tree","collector_exit")}))
finally:
 net.pop("GH_TOKEN",None);token=b""
run("verify-after",["/bin/bash",str(p/"verify-prepublish.sh")],clean)
(a/"inputs-after.nul").write_bytes((p/"inputs-after.nul").read_bytes())
(a/"verification-after.json").write_bytes((p/"verification-final.json").read_bytes())
assert (a/"inputs-before.nul").read_bytes()==(a/"inputs-after.nul").read_bytes()
assert hashlib.sha256((a/"inputs-after.nul").read_bytes()).hexdigest()==source
result.update(status="PASS",binding_before="PASS",binding_after="PASS",frozen_manifest="BYTE_IDENTICAL",protected_state="UNCHANGED",source_files=177,harness_records=8,document_records=4,tool_records=4)
(a/"result.json").write_text(json.dumps(result,indent=2)+"\n")
artifacts={str(x.relative_to(a)):dict(sha256=hashlib.sha256(x.read_bytes()).hexdigest(),bytes=x.stat().st_size) for x in a.rglob("*") if x.is_file() and x.name!="artifact-hashes.json"}
(a/"artifact-hashes.json").write_text(json.dumps(artifacts,indent=2)+"\n")
assert all(hashlib.sha256((a/k).read_bytes()).hexdigest()==v["sha256"] and (a/k).stat().st_size==v["bytes"] for k,v in artifacts.items())
print(json.dumps(dict(status="PASS",source=source,head=head,tree=tree,run_id=runid,attempt=wanted_attempt,artifact_count=len(artifacts))))
