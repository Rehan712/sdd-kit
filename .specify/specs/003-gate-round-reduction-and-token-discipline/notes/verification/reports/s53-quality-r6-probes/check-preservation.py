from pathlib import Path
import hashlib,json,os,stat,subprocess,sys,time
root=Path('/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline');assert Path.cwd()==root and os.environ.get('GIT_OPTIONAL_LOCKS')=='0'
r=root/'.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports';p=r/'s53-quality-r6-probes';before=json.loads((p/'review-before.json').read_text())
def sha(b):return hashlib.sha256(b).hexdigest()
def inventory(base):
 out={}
 for d,dirs,files in os.walk(base,followlinks=False):
  dirs.sort();files.sort()
  for name in files+[x for x in dirs if (Path(d)/x).is_symlink()]:
   f=Path(d)/name;s=f.lstat();v={'mode':stat.S_IMODE(s.st_mode),'mtime_ns':s.st_mtime_ns,'size':s.st_size,'type':'symlink' if stat.S_ISLNK(s.st_mode) else 'file'}
   if stat.S_ISLNK(s.st_mode):v['target']=os.readlink(f);v['sha256']=sha(os.fsencode(v['target']))
   elif stat.S_ISREG(s.st_mode):v['sha256']=sha(f.read_bytes())
   else:v['type']='other'
   out[str(f.relative_to(base))]=v
 return out
after=inventory(root);old=before['preexisting'];missing=[k for k in old if k not in after];changed={k:{'before':old[k],'after':after[k]} for k in old if k in after and old[k]!=after[k]};new={k:after[k] for k in after if k not in old}
allowed_parent=before['allowed_parent_new'];allowed_report=str((r/'s53-o034-quality-review-r6.md').relative_to(root));owned_prefix=str(p.relative_to(root))+'/'
unexpected={k:v for k,v in new.items() if not (k==allowed_parent or k==allowed_report or k.startswith(owned_prefix))}
# The prefix only authorizes new files. Every original under it, including source-after-accept.nul, stays in old and is checked without an exception.
raw={}
for name,prior in before['raw_git'].items():
 f=Path(name)
 if not f.exists():raw[name]={'before':prior,'after':None};continue
 st=f.stat();v={'sha256':sha(f.read_bytes()),'mode':stat.S_IMODE(st.st_mode),'mtime_ns':st.st_mtime_ns,'size':st.st_size}
 if v!=prior:raw[name]={'before':prior,'after':v}
cmd=['git','for-each-ref','--format=%(refname)%00%(objectname)%00%(symref)'];q=subprocess.run(cmd,cwd=root,env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),capture_output=True);assert q.returncode==0 and not q.stderr
initial=next(x for x in before['commands'] if x['argv'][1]=='for-each-ref')['stdout']
def refs(text):return {x.split('\0')[0]:x.split('\0')[1:] for x in text.splitlines()}
a=refs(initial);b=refs(q.stdout.decode());refdiff={k:{'before':a.get(k),'after':b.get(k)} for k in sorted(set(a)|set(b)) if a.get(k)!=b.get(k)}
common=Path(next(x for x in before['commands'] if x['argv']==['git','rev-parse','--git-common-dir'])['stdout'].strip());rawrefs=inventory(common/'refs');prior=before['raw_refs'];rawrefdiff={k:{'before':prior.get(k),'after':rawrefs.get(k)} for k in sorted(set(prior)|set(rawrefs)) if prior.get(k)!=rawrefs.get(k)}
spec_ref='refs/heads/spec/003-gate-round-reduction-and-token-discipline';assert a.get(spec_ref)==b.get(spec_ref)
# Keep each new owned path explicit for the handback, without placing those files in the original preservation baseline.
owned={k:v for k,v in new.items() if k==allowed_report or k.startswith(owned_prefix)}
result={'observed_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'original_file_symlink_count':len(old),'missing_originals':missing,'changed_originals':changed,'external_git_changes':raw,'unexpected_additions':unexpected,'exact_parent_receipt_new':new.get(allowed_parent),'all_originals_bytes_modes_mtimes_preserved':not missing and not changed,'head_index_external_git_preserved':not raw,'spec_branch_unchanged':a.get(spec_ref)==b.get(spec_ref),'global_ref_differences':refdiff,'raw_ref_differences':rawrefdiff,'global_ref_attribution':'Unknown; this review ran no ref-writing command. No restoration or allowlist exception.','strict_global_refs_preserved':not refdiff and not rawrefdiff,'original_ownership_boundary_used':True,'source_after_accept_original_preserved':str((p/'source-after-accept.nul').relative_to(root)) in old and str((p/'source-after-accept.nul').relative_to(root)) not in changed,'own_new_files':owned,'own_new_file_count':len(owned)}
result['strict_preservation_passed']=not missing and not changed and not raw and not unexpected and not refdiff and not rawrefdiff
name=sys.argv[1] if len(sys.argv)>1 else 'protection-pre-report.json'
with (p/name).open('x') as f:json.dump(result,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['own_new_files','raw_ref_differences']},indent=2))
raise SystemExit(0 if result['strict_preservation_passed'] else 1)
