#!/usr/bin/env bash
# Mutation-isolate the repair's new guards in the private copy. Rows: <id> <diag> <test file> <case> <file> <old> <new>
set -uo pipefail
B=/private/tmp/rev2-t030o43; C=$B/kit; w=$B/work/mut; mkdir -p $w; export TMPDIR=$B/tmp
EDITED=(scripts/verification-lib.sh scripts/spec-evidence.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh tests/test-verification.sh tests/test-sdd-analyze.sh)
mkdir -p $w/pristine; for f in "${EDITED[@]}"; do mkdir -p "$w/pristine/$(dirname $f)"; cp "$C/$f" "$w/pristine/$f"; done
replace() { perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$C/$1" "$2" "$3"; }
judge() { ( cd "$C" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.one-$1" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$1" "$2" ) > "$w/judge.out" 2>&1; }
restore() { ( cd "$C" && git checkout -q -- . && rm -f tests/.one-*.sh ) || return 1
  local f; for f in "${EDITED[@]}"; do cmp -s "$C/$f" "$w/pristine/$f" || echo "RESTORE NOT BYTE-IDENTICAL: $f"; done
  [[ -z "$(cd $C && git status --porcelain --ignored)" ]] || { echo "COPY NOT CLEAN:"; (cd $C && git status --porcelain --ignored); }; }
base() { local s=$SECONDS; judge "$1" "$2"; local rc=$?; echo "BASE $2 rc=$rc ($((SECONDS-s))s)"; grep -E 'assert' "$w/judge.out" | head -3 | sed 's/^/   | /'; cp "$w/judge.out" "$w/base-$2.out"; restore; }
row() { local id="$1" diag="$2" tf="$3" case="$4" s=$SECONDS rc; shift 4
  while (( $# )); do replace "$1" "$2" "$3"; rc=$?; [[ $rc == 0 ]] || { echo "ROW $id: literal did not apply once in $1 (rc=$rc)"; restore; return; }; shift 3; done
  judge "$tf" "$case"; rc=$?
  local hit; hit=$(grep -c -F -- "$diag" "$w/judge.out")
  echo "ROW $id judge rc=$rc diag-hits=$hit ($((SECONDS-s))s) -> $([[ $rc != 0 && $hit -gt 0 ]] && echo KILLED-EXACT || echo NOT-KILLED-EXACT)"
  grep -E 'assert' "$w/judge.out" | head -3 | sed 's/^/   | /'
  cp "$w/judge.out" "$w/row-$id.out"; restore; }
