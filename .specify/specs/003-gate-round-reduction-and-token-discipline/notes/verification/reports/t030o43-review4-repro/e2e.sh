# usage (from the kit copy): bash e2e.sh <label> <manifest %b body>
# first, in the kit copy: awk '$0 != "t_run_all"' tests/test-spec-gate.sh > tests/.one-test-spec-gate.sh
#   (and add tests/.one-*.sh to .git/info/exclude)
cd /private/tmp/rev4-t030o43/kit || exit 9
export TMPDIR=/private/tmp/rev4-t030o43/tmp
. tests/.one-test-spec-gate.sh
SANDBOX="$(mktemp -d "$TMPDIR/sddkit.XXXXXX")"; export SANDBOX
label="$1"; body="$2"
spec="$(make_verification_git_dir e2e)"; cli="$(floor_fixture "$spec")"
run_rc 0 bash "$cli" floor "$spec" >/dev/null; echo "floor: rc=$? $(printf '%s' "$OUT" | tail -1 | cut -c1-80)"
run_rc 0 bash "$cli" round "$spec" opponent >/dev/null; res="$OUT"
src="$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"; floor="$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"; stamp="$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
mkdir -p "$spec/notes/verification/reports"; printf '%b' "$body" > "$spec/notes/verification/reports/opponent-findings-review.md"
{ printf '## Round 1\n**Round:** 1\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n' "$stamp" "$src" "$floor"
  printf '**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nManifest tier binding.\n'
  printf '### Finding G-042\n- **Class:** tier-binding\n- **Status:** open\n- **Prior:** none\n- **Severity:** minor\n'
  printf -- '- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
  printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n'
  printf -- '- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n'
  printf '<!-- gate-round-end: opponent:1 -->\n'; } > "$SANDBOX/report.md"
out="$(bash "$cli" round "$spec" opponent --complete "$SANDBOX/report.md" 2>&1)"; rc=$?
printf '[%s] round --complete rc=%s %s\n' "$label" "$rc" "$(printf '%s' "$out" | tr '\n' '|' | cut -c1-200)"
rm -rf "$SANDBOX"
