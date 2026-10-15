#!/usr/bin/env bash
# T030o43: rebuild the pre-delta versions of every file the repair edits, by
# reversing each literal edit in reverse order of application, and prove each
# byte-exact against the `path` records of the inputs manifest taken when the
# Decisions batch was recorded (source 70c71885…, r13-auth-state.txt), before
# any code changed. Read-only against the live worktree.
# Usage: bash t030o43-pre-rebuild.sh <worktree> <output dir>
set -uo pipefail
WT="$1"; OUT="$2"; E="$WT/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o43-edits"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
rev() { # <file> <pairs...>: apply each pairs file reversed (NEW -> OLD), in the order given
  local f="$1" p; shift
  for p in "$@"; do
    perl -0pe 's/\@\@OLD\n(.*?)\n\@\@NEW\n(.*?)\n\@\@END\n/\@\@OLD\n$2\n\@\@NEW\n$1\n\@\@END\n/sg' "$E/$p" > "$OUT/.rev"
    perl "$E/lit.pl" "$OUT/$f" "$OUT/.rev" > /dev/null || { say "FAIL reverse $p on $f"; fails=$((fails+1)); }
  done
}
subst() { # <perl s/// expression[; exit(...)]> <file>: exactly one substitution, the file rewritten
  perl -e 'local $/; my ($e, $f) = @ARGV; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    $e =~ s/; exit\(.*\)$//s; my $n = eval "\$t =~ $e"; die $@ if $@; exit 4 if $n != 1;
    open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$1" "$2"
}
rm -rf "$OUT"; mkdir -p "$OUT"
files=(scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh scripts/spec-evidence.sh
  scripts/spec-ac-coverage.sh scripts/sdd-analyze.sh templates/verification-contract.md tests/helpers.sh
  tests/test-gate-contracts.sh tests/test-verification.sh tests/test-spec-gate.sh tests/test-sdd-analyze.sh "$s/tasks.md")
for f in "${files[@]}"; do mkdir -p "$OUT/$(dirname "$f")"; cp -p "$WT/$f" "$OUT/$f"; done
# The kernel: reversed pairs, then the edits made by hand, then the inserted block.
rev scripts/verification-lib.sh kernel-3.pairs kernel-2.pairs
# custom-kernel.pairs is written old-to-new already (NEW is the pre-delta text), so it applies forward.
perl "$E/lit.pl" "$OUT/scripts/verification-lib.sh" "$E/custom-kernel.pairs" > /dev/null || { say 'FAIL custom-kernel.pairs'; fails=$((fails+1)); }
subst 's/fi\n\n# The harness\x27s own parsing runs under the C locale \(O-017, round 12\)\..*?  printf \x27%s\\n\x27 "\$out" \| LC_ALL=C sort -u\n\)\n/fi\n/s; exit($n == 1 ? 0 : 4)' "$OUT/scripts/verification-lib.sh" || { say 'FAIL delete the kernel block'; fails=$((fails+1)); }
for f in spec-run spec-task spec-evidence spec-ac-coverage sdd-analyze; do rev "scripts/$f.sh" "$f.pairs"; done
rev templates/verification-contract.md o010-2.pairs vc.pairs
rev tests/test-gate-contracts.sh tgc.pairs
subst 's/  # The marker names the file by its prefix: the full name beside PATH on the\n  # next line would read to the O-010 scan as a membership claim.\n  fault_bin "\$SANDBOX\/fault-extra" sort \x27\/extra-h\x27\n/  fault_bin "\$SANDBOX\/fault-extra" sort \x27extra-hashes\x27\n/; exit($n == 1 ? 0 : 4)' "$OUT/tests/test-verification.sh" || { say 'FAIL reverse the marker edit'; fails=$((fails+1)); }
rev tests/test-verification.sh o010-3.pairs tv2.pairs tv.pairs
rev tests/test-spec-gate.sh o010-4.pairs tsg.pairs
rev tests/test-sdd-analyze.sh tsa.pairs
subst 's/  return "\$rc"\n\}\n\n# in_locale <LANG> .*?\n\}\n\n# --- runner/  return "\$rc"\n}\n\n# --- runner/s; exit($n == 1 ? 0 : 4)' "$OUT/tests/helpers.sh" || { say 'FAIL delete the helpers block'; fails=$((fails+1)); }
rev "$s/tasks.md" tasks-fix.pairs
rm -f "$OUT/.rev"
# Proof: each rebuilt file hashes, through vf_semantic_file, to its path record at 70c71885.
for f in "${files[@]}"; do
  want="$(tr '\0' '\n' < "$E/source-70c71885-inputs.nul" | paste - - - - - - | awk -F '\t' -v p="$f" '$1=="path" && $2==p {print $5}')"
  got="$(bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file "$2" "$3" "$4" && vf_hash "$4"' _ "$WT" "$f" "$OUT/$f" "$OUT/.sem")"
  if [[ -n "$want" && "$want" == "$got" ]]; then say "PASS rebuilt $f equals its 70c71885 record"; else say "FAIL rebuilt $f: want=$want got=$got"; fails=$((fails+1)); fi
done
rm -f "$OUT/.sem"
say "t030o43-pre-rebuild failures=$fails"
(( fails == 0 ))
