#!/usr/bin/env bash
# Invoker verification of the T030o42 review's findings, 2026-09-27, BEFORE any
# change. Usage: bash t030o42-review-verify.sh <scratchpad> <worktree>
# Read-only against the live worktree: a standalone copy is built from its
# enumeration. Every exit is captured from the command itself.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/t030o42-rv"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
say() { printf '%s\n' "$*"; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - )
( cd "$C" && git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base ) || { say 'FAIL copy'; exit 2; }
cd "$C" || exit 2
snap() { # <tag> <env...>
  local tag="$1"; shift
  env "$@" bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/$tag.nul" > "$w/$tag.out" 2> "$w/$tag.err"
  printf 'snapshot %-22s rc=%s digest=%s err=%s\n' "$tag" "$?" "$(head -c 16 "$w/$tag.out")" "$(head -1 "$w/$tag.err" | cut -c1-110)"
}
say '== F1a: the harness under locales (clean tree)'
snap C LC_ALL=C; snap C.UTF-8 LC_ALL=C.UTF-8; snap en_US.UTF-8 -u LC_CTYPE LC_ALL=en_US.UTF-8; snap ISO8859-1 LC_ALL=en_US.ISO8859-1; snap SJIS LC_ALL=ja_JP.SJIS
say '== F1b: one invalid UTF-8 byte in the T030o42 subject line'
cp -p "$s/tasks.md" "$w/tasks.orig"
perl -pi -e 's/(\*\*T030o42\*\* — Pin)/$1\xff/' "$s/tasks.md"
say "  | byte planted: $(grep -c -a $'\xff' "$s/tasks.md") line(s)"
snap bad-C LC_ALL=C; snap bad-C.UTF-8 LC_ALL=C.UTF-8; snap bad-en_US.UTF-8 -u LC_CTYPE LC_ALL=en_US.UTF-8
for l in C en_US.UTF-8; do
  env -u LC_CTYPE LC_ALL="$l" bash scripts/sdd-analyze.sh "$s" > "$w/an-$l.out" 2>&1
  say "  | analyzer with the byte under $l: rc=$? $(tail -1 "$w/an-$l.out")"
done
cp -p "$w/tasks.orig" "$s/tasks.md"
say "  | tasks.md restored: $(git diff --quiet -- "$s/tasks.md" && echo clean || echo DIRTY)"
say '== F1c: glob order under collation'
mkdir -p "$w/g" && ( cd "$w/g" && touch CAP-10-a CAP-9-b CAP-1-Z CAP-1-a B a _x -- -y )
for l in C C.UTF-8 en_US.UTF-8; do say "  | $l: $(cd "$w/g" && env -u LC_CTYPE LC_ALL="$l" bash -c 'echo *')"; done
say '== F2: every suite loads helpers.sh first (the first non-comment line after set -u)'
for f in tests/test-*.sh; do
  first="$(awk '!/^#/ && !/^[[:space:]]*$/ && $0 != "set -u" {print; exit}' "$f")"
  case "$first" in *'/helpers.sh"') ;; *) say "  | $f first line: $first";; esac
done
say "  | suites checked: $(ls tests/test-*.sh | wc -l | tr -d ' ')"
say '== F3: date(1) ENVIRONMENT section'
MANPAGER=cat man date 2>/dev/null | col -b | awk '/^ENVIRONMENT/{f=1} f && /^EXIT STATUS/{exit} f' | sed 's/^/  | /' | head -6
say "  | the census regex required names of three or more characters: $(printf 'TZ\n' | grep -c -o -E '\b[A-Z][A-Z0-9_]{2,}\b') match(es) for TZ"
cd "$SP" && rm -rf "$R"
