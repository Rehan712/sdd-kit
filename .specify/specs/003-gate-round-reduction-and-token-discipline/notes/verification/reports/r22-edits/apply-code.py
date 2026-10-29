#!/usr/bin/env python3
# Session 24 (2026-10-16): T031a4o2, round 21's O-029, test files only, no kernel change, as the user chose after
# round 21 ("Repair now": the reviewer's recipe). In tests/test-spec-gate.sh round_legacy_reconcile_cases: the valid
# record is reconciled to 2026-07-21T06:00:00Z, a time no reading of the history's date (its midnight or its end)
# yields; a waiver dated 2026-07-21T05:00:00Z is refused with the exact diagnostic; and a future-stamped record is
# refused before the valid one, like the other wrong records. Starts from opponent-round21.md and r21-repro-o029.sh.
# Usage: python3 -I <this> <root>   (root: the worktree, or a standalone copy of it)
# Refuses unless the file hashes as after T031a4o1 (r21-edits/post-apply.sha256) and every anchor occurs exactly
# once; prints the new sha256.
import hashlib, os, sys
root = sys.argv[1]
G = 'tests/test-spec-gate.sh'
b = open(os.path.join(root, G), 'rb').read()
assert hashlib.sha256(b).hexdigest() == 'b94c7dfaaf34f9ff4ee178f916e6491fec30135c61f35f230bcb51923bf199cb', \
    'refusing: %s does not hash as the frozen source' % G
text = b.decode('utf-8')

def once(old, new):
    global text
    n = text.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    text = text.replace(old, new)

once(r'''# kernel names none of the exit-3 refusals (O-032), so the cases assert state.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp digest bad legacy
''', r'''# kernel names none of the exit-3 refusals (O-032), so the cases assert state.
# T031a4o2 (round 21, O-029): the record is reconciled to a time on a later day,
# which no reading of the history's date yields (neither its midnight nor its
# end of day), and a record stamped in the future is refused as well.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp digest bad what legacy
''')
once(r'''  for bad in digest round timestamp; do
    case "$bad" in
      digest) printf '%s\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$(printf '%064d' 0)";;
      round) printf '%s\0' round 4 timestamp 2026-07-20T23:59:59Z report_digest "$digest";;
      timestamp) printf '%s\0' round 5 timestamp 2026-07-19T23:59:59Z report_digest "$digest";;
    esac > "$SANDBOX/legacy-wrong-$bad.nul"
    run_rc 3 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-wrong-$bad.nul"
    [[ ! -e "$legacy" ]] || t_fail "AC-009: a reconcile record with a wrong $bad wrote legacy-time.nul"
    run_rc 4 bash "$cli" round "$spec" opponent
    assert_contains "$OUT" 'date-only history needs timestamped digest reconciliation' \
      "AC-009: a reconcile record with a wrong $bad left the history able to order an authorization"
''', r'''  for bad in digest round early future; do
    case "$bad" in
      digest) what='a wrong digest'; printf '%s\0' round 5 timestamp 2026-07-21T06:00:00Z report_digest "$(printf '%064d' 0)";;
      round) what='a wrong round'; printf '%s\0' round 4 timestamp 2026-07-21T06:00:00Z report_digest "$digest";;
      early) what="a timestamp before the history's date"; printf '%s\0' round 5 timestamp 2026-07-19T23:59:59Z report_digest "$digest";;
      future) what='a future timestamp'; printf '%s\0' round 5 timestamp 2099-01-01T00:00:00Z report_digest "$digest";;
    esac > "$SANDBOX/legacy-wrong-$bad.nul"
    run_rc 3 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-wrong-$bad.nul"
    [[ ! -e "$legacy" ]] || t_fail "AC-009: a reconcile record with $what wrote legacy-time.nul"
    run_rc 4 bash "$cli" round "$spec" opponent
    assert_contains "$OUT" 'date-only history needs timestamped digest reconciliation' \
      "AC-009: a reconcile record with $what left the history able to order an authorization"
''')
once(r'''  printf '%s\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$digest" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T23:59:59Z'
  # After the history's date, before the reconciled time: only the record decides.
  printf '\n## Decisions log\n%s\n' '- 2026-07-20T12:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=dated before the reconciled completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-20T23:59:59Z' \
''', r'''  # A later day than the history's date (2026-07-20), so only the record yields this time.
  printf '%s\0' round 5 timestamp 2026-07-21T06:00:00Z report_digest "$digest" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-21T06:00:00Z'
  # After every reading of the history's date, before the reconciled time: only the record decides.
  printf '\n## Decisions log\n%s\n' '- 2026-07-21T05:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=dated before the reconciled completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-21T06:00:00Z' \
''')

out = text.encode('utf-8')
open(os.path.join(root, G), 'wb').write(out)
print('%s  %s' % (hashlib.sha256(out).hexdigest(), G))
