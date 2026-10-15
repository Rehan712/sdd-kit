#!/usr/bin/env python3
"""T030o39/T030o40 mutation table, run 3 (git-free anchor, filesystem fold probe).
--list prints "<name> <stem:function>" per mutant; <name> <root> applies it.
Every old string must occur exactly once in its file."""
import sys

LIB = 'scripts/verification-lib.sh'
TGC = 'tests/test-gate-contracts.sh'
PROV = 'test-verification:test_capture_provenance'
TALLY = 'test-gate-contracts:test_reports_and_tally'
GUIDE = 'test-gate-contracts:test_instruction_contracts'
BROAD = ('.specify/specs/*/.tasks.accept.*|.specify/specs/*/notes/captures/*|.specify/specs/*/notes/verification/*|'
         '.specify/specs/*/notes/evidence.md|.specify/specs/*/notes/opponent.md|.specify/specs/*/notes/reality-check.md')
ANCHORED = ('"$2"/.tasks.accept.*|"$2"/notes/captures/*|"$2"/notes/verification/*|'
            '"$2"/notes/evidence.md|"$2"/notes/opponent.md|"$2"/notes/reality-check.md')
OLD_FOLD = '''  awk -F '\\t' '
    function tier(s) {return (s=="minor" || s=="degraded") ? "minor" : "blocking"}
    { k=%s
      if((k in first) && first[k]=="blocking" && tier($6)=="minor" && $3!="resolved") down++
      if(!(k in first) || tier($6)=="blocking") first[k]=tier($6)
    }
    END {printf "severity-downgrades=%%d\\n", down+0}' "$tmp/classes"'''
LOWERED = '      lowered = ((fid in firsttier) && firsttier[fid]=="blocking" && sev ~ /^(minor|degraded)$/ && status!="resolved")'
SCAN_ANCHOR = '    case "$path" in .specify/specs/*/*) own="${path#.specify/specs/}"; own=".specify/specs/${own%%/*}";; esac'
REFUSAL_IF = ('    if [[ -n "$real" ]] && { vf_bookkeeping_path "$real" "$own" "$fold" || '
              '{ [[ -d "$repo/$real" ]] && vf_bookkeeping_path "$real/." "$own" "$fold"; }; }; then')
TALLY_PRINT = '''  printf 'severity-downgrades=%s\\n' "$downgrades"'''

M = [
  # T030o39 kill mutants
  ('M1-old-broad-predicate', PROV, [(LIB, '    ' + ANCHORED + ') rc=0;;', '    ' + BROAD + ') rc=0;;')]),
  ('M2-no-exclusion', PROV, [(LIB, '  [[ -n "$2" ]] || return 1', '  return 1')]),
  ('M3-anchor-empty', PROV, [(LIB, '''  [[ -z "$own" ]] || printf '%s\\n' "$own"''', '  :')]),
  ('M4-index-pass-broad', PROV, [(LIB, '    vf_bookkeeping_path "$path" "$own" "$fold" && continue', '    case "$path" in ' + BROAD + ') continue;; esac')]),
  ('M5-path-pass-broad', PROV, [(LIB, '  if vf_bookkeeping_path "$path" "$own" "$fold"; then return 0; fi', '  case "$path" in ' + BROAD + ') return 0;; esac')]),
  ('M6-no-refusal', PROV, [(LIB, '''      echo "verification inputs: declared input is this spec's own generated bookkeeping: $path" >&2; return 3''', '      :')]),
  ('M7-lexical-refusal', PROV, [(LIB, '''    real="$(vf_physical_rel "$repo" "$path" "$fold")" || real=\'\'''', '    real="$path"')]),
  ('M8-no-link-follow', PROV, [(LIB, '  while [[ -L "$path" ]]; do', '  while false; do')]),
  ('M9-no-member-skip', PROV, [(LIB, '        vf_bookkeeping_path "${record#"$repo/"}" "$own" "$fold" && continue', '        :')]),
  ('M10-scan-unanchored', GUIDE, [(TGC, SCAN_ANCHOR, '    :')]),
  ('M11-scan-fixed-anchor', GUIDE, [(TGC, SCAN_ANCHOR, '    own=.specify/specs/003-x')]),
  # Review follow-ups (run 2)
  ('M17-no-fold-probe', PROV, [(LIB, '  local d="$1" alt\n  while [[ "$d" == /?* ]]; do', '  local d="$1" alt\n  return 1\n  while [[ "$d" == /?* ]]; do')]),
  ('M25-probe-does-not-climb', PROV, [(LIB, '    d="$(dirname -- "$d")"\n  done\n  return 1', '    return 1\n  done\n  return 1')]),
  ('M24-no-alias-guard-cs', PROV, [(LIB, '[[ ! -L "$alt" && "$d" -ef "$alt" ]]', '[[ "$d" -ef "$alt" ]]')]),
  ('M18-fold-from-git-config', PROV, [(LIB, '  ! vf_case_folds "$spec" || fold=1', '  [[ "$(git -C "$repo" config --bool core.ignorecase 2>/dev/null)" != true ]] || fold=1')]),
  ('M19-logical-cd', PROV, [(LIB, '  dir="$(cd -P -- "$dir" 2>/dev/null && pwd -P)" || return 1', '  dir="$(cd -- "$dir" 2>/dev/null && pwd -P)" || return 1')]),
  ('M23-anchor-from-git-discovery', PROV, [(LIB, '''  if [[ "$1" == "$2"/* ]]; then own="${1:$((${#2}+1))}"; [[ "$own" =~ ^\\.specify/specs/[^/]+$ ]] || own=''; fi''',
      '''  own="$(git -C "$1" rev-parse --show-prefix 2>/dev/null)"; own="${own%/}"; [[ "$own" =~ ^\\.specify/specs/[^/]+$ ]] || own=\'\'''')]),
  ('M20-no-root-refusal', PROV, [(LIB, '''    if [[ "$real" == . ]]; then echo "verification inputs: declared input is the repository root: $path" >&2; return 3; fi''', '    :')]),
  ('M21-lexical-member-base', PROV, [(LIB, '      find "$repo/${real:-$path}" \\( -type f -o -type l \\) -print0', '      find "$repo/$path" \\( -type f -o -type l \\) -print0')]),
  ('M22-unbounded-link-loop', PROV, [(LIB, '    (( n++ < 40 )) || return 1', '    :')]),
  # T030o40 kill mutants
  ('M12-tally-seedless-fold', TALLY, [(LIB, TALLY_PRINT, OLD_FOLD % '$5 SUBSEP $2')]),
  ('M13-tally-id-only-fold', TALLY, [(LIB, TALLY_PRINT, OLD_FOLD % '$2')]),
  ('M14-no-downgrade-emit', TALLY, [(LIB, '      if (lowered) emit("downgrade",n,fid,cls,status,prior,sev,"","","","","")', '')]),
  ('M15-manifest-across-gates', TALLY, [(LIB, '  for manifest in "$spec/notes/verification/reports/$gate-findings-"*.md; do',
                                        '  for manifest in "$spec/notes/verification/reports/"*-findings-*.md; do')]),
  ('M16-no-multi-clause-refusal', GUIDE, [(TGC, '      if(body ~ /;;|;&/) fail()', '')]),
  # Equivalent by construction (expected to SURVIVE)
  ('E1-predicate-canonical-only', TALLY, [(LIB, LOWERED, LOWERED.replace('lowered = ((fid', 'lowered = (style=="canonical" && (fid'))]),
  ('E2-declared-calls-anchored', PROV, [(LIB, '''        vf_path_record "$repo" "${record#"$repo/"}" "$tmp/path-record" "$tmp" \'\' || return 3''',
                                        '        vf_path_record "$repo" "${record#"$repo/"}" "$tmp/path-record" "$tmp" "$own" "$fold" || return 3'),
                                       (LIB, '''    else vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" \'\' || return 3; fi''',
                                        '    else vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" "$own" "$fold" || return 3; fi')]),
  # Over-correction controls (must be KILLED by a positive)
  ('C1-refuse-every-declared-dir', PROV, [(LIB, REFUSAL_IF, '    if [[ -n "$real" ]] && { vf_bookkeeping_path "$real" "$own" "$fold" || [[ -d "$repo/$real" ]]; }; then')]),
  ('C2-refuse-other-spec-report', PROV, [(LIB, REFUSAL_IF, REFUSAL_IF.replace('{ vf_bookkeeping_path "$real" "$own" "$fold" ||',
      '{ vf_bookkeeping_path "$real" "$own" "$fold" || [[ "$real" == .specify/specs/*/notes/opponent.md ]] ||', 1))]),
  ('C3-count-resolved', TALLY, [(LIB, LOWERED, LOWERED.replace(' && status!="resolved")', ')'))]),
]
TABLE = {name: (target, edits) for name, target, edits in M}

def main():
    if sys.argv[1] == '--list':
        for name, target, _ in M:
            print(name, target)
        return
    name, root = sys.argv[1], sys.argv[2]
    _, edits = TABLE[name]
    for rel, old, new in edits:
        path = f'{root}/{rel}'
        text = open(path).read()
        n = text.count(old)
        if n != 1:
            print(f'mutation {name}: expected 1 occurrence in {rel}, found {n}', file=sys.stderr)
            sys.exit(2)
        open(path, 'w').write(text.replace(old, new))
    print(' '.join(sorted({rel for rel, _, _ in edits})))

if __name__ == '__main__':
    main()
