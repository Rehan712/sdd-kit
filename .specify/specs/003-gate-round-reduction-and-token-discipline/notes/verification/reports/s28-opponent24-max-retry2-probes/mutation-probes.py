from pathlib import Path
import subprocess,time,json,hashlib
w=Path(__file__).resolve().parent
kit=w/'kit'
results=[]
def run(name,script):
    start=time.time()
    with (w/'logs'/f'{name}.log').open('wb') as out:
        p=subprocess.run(['/bin/bash',str(w/script),str(kit),str(w/name)],stdout=out,stderr=subprocess.STDOUT,timeout=200)
    row={'name':name,'exit':p.returncode,'elapsedSeconds':time.time()-start}
    (w/'logs'/f'{name}.result.json').write_text(json.dumps(row)+'\n')
    results.append(row)
    print(json.dumps(row),flush=True)
    print((w/'logs'/f'{name}.log').read_text()[:1400],flush=True)

a=kit/'scripts/sdd-analyze.sh'; original=a.read_bytes(); text=original.decode()
try:
    for name,old,new in [
        ('classifier-no-typecheck','|typecheck|','|'),
        ('classifier-no-tsc',r'|tsc[[:space:]]+--noemit','')]:
        assert text.count(old)==1
        a.write_text(text.replace(old,new,1))
        run(name,'classifier-regression.sh')
        a.write_bytes(original)
finally:
    a.write_bytes(original)
assert a.read_bytes()==original

v=kit/'scripts/verification-lib.sh'; original=v.read_bytes(); text=original.decode()
currency="  [[ -f \"$manifest\" && \"$before\" == \"$(vf_hash \"$manifest\")\" ]] || { echo 'capture stale: current inputs changed; refresh verification' >&2; return 3; }"
start=text.index('vf_matrix_evidence() (')
end=text.index('vf_matrix_prior() (',start)
segment=text[start:end]
check='  vf_capture_check \"$spec\" \"$cap\" \"$tmp\" current || return 3'
try:
    assert text.count(currency)==1
    v.write_text(text.replace(currency,'  : # opponent scratch mutation: omit current-manifest check',1))
    run('matrix-no-currency','matrix-regression.sh')
    v.write_bytes(original)
    assert segment.count(check)==1
    modified=segment.replace(check,'  : # opponent scratch mutation: omit matrix capture validation',1)
    v.write_text(text[:start]+modified+text[end:])
    run('matrix-no-evidence-validation','matrix-regression.sh')
finally:
    v.write_bytes(original)
assert v.read_bytes()==original
(w/'logs/mutation-summary.json').write_text(json.dumps({'results':results,'analyzerRestored':a.read_bytes()==a.read_bytes(),'libraryRestored':v.read_bytes()==original},indent=2)+'\n')
