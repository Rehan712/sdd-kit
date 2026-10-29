#!/usr/bin/env python3
# Session 25 (2026-10-17): T031a4o3, round 22's O-029 with O-033, test files only, no kernel change, as the user chose
# after round 22 ("Fix the issue then continue": the reviewer's recipe). In tests/test-spec-gate.sh
# round_legacy_reconcile_cases: the record is reconciled first on the history's own date at 2026-07-20T15:17:43Z, with
# waivers one second before (refused, exact diagnostic) and one second after (authorized), then again on a later day
# at 2026-07-21T06:17:43Z with a waiver one second before (refused, exact diagnostic); and the bad-record loop gets a
# record with an impossible time and one stamped later today (O-033). Starts from opponent-round22.md and the
# reviewer's prototype (r22-opp-workdir; /private/tmp/opp22/proto/test-spec-gate.sh).
# Usage: python3 -I <this> <root>   (root: the worktree, or a standalone copy of it)
# Refuses unless the file hashes as after T031a4o2 (r22-edits/post-apply.sha256) and every anchor occurs exactly
# once; prints the new sha256.
import hashlib, os, sys
root = sys.argv[1]
G = 'tests/test-spec-gate.sh'
b = open(os.path.join(root, G), 'rb').read()
assert hashlib.sha256(b).hexdigest() == 'bf297cb17efa680525d2d917de68af6278a7642f803f90ba0f37333c179e831e', \
    'refusing: %s does not hash as the frozen source' % G
text = b.decode('utf-8')

def once(old, new):
    global text
    n = text.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    text = text.replace(old, new)

once(r'''# end of day), and a record stamped in the future is refused as well.
round_legacy_reconcile_cases() {
''', r'''# end of day), and a record stamped in the future is refused as well.
# T031a4o3 (round 22, O-029 and O-033): both regions the guard admits are
# pinned at non-round times, each one second either side: first the history's
# own date (15:17:43Z), then a later day (06:17:43Z); and records with an
# impossible time or stamped later today are refused like the other wrong ones.
round_legacy_reconcile_cases() {
''')
once(r'''  for bad in digest round early future; do
    case "$bad" in
''', r'''  for bad in digest round early future invalid soon; do
    # A record later today needs a minute's margin before midnight.
    [[ "$bad" != soon || "$(date -u +%H:%M)" < 23:59 ]] || continue
    case "$bad" in
''')
once(r'''      future) what='a future timestamp'; printf '%s\0' round 5 timestamp 2099-01-01T00:00:00Z report_digest "$digest";;
''', r'''      future) what='a future timestamp'; printf '%s\0' round 5 timestamp 2099-01-01T00:00:00Z report_digest "$digest";;
      invalid) what='an impossible time'; printf '%s\0' round 5 timestamp 2026-07-20T25:00:00Z report_digest "$digest";;
      soon) what='a timestamp later today'; printf '%s\0' round 5 timestamp "$(date -u +%Y-%m-%d)T23:59:59Z" report_digest "$digest";;
''')
once(r'''  # A later day than the history's date (2026-07-20), so only the record yields this time.
  printf '%s\0' round 5 timestamp 2026-07-21T06:00:00Z report_digest "$digest" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-21T06:00:00Z'
  # After every reading of the history's date, before the reconciled time: only the record decides.
  printf '\n## Decisions log\n%s\n' '- 2026-07-21T05:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=dated before the reconciled completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-21T06:00:00Z' \
''', r'''  # The history's own date (2026-07-20) first, at a time no coarser reading of
  # the record or the date yields; only the record decides either second.
  printf '%s\0' round 5 timestamp 2026-07-20T15:17:43Z report_digest "$digest" > "$SANDBOX/legacy-same.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-same.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T15:17:43Z' \
    "AC-009: a record on the history's own date was not reconciled"
  printf '\n## Decisions log\n%s\n' '- 2026-07-20T15:17:42Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=one second before the same-day completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-20T15:17:43Z' \
    'AC-009: a same-day waiver one second before the reconciled completion authorized the next round'
  printf '%s\n' '- 2026-07-20T15:17:44Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=one second after the same-day completion' >> "$spec/STATUS.md"
  run_rc 0 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'authorized: opponent round 6' \
    'AC-009: a same-day waiver one second after the reconciled completion was not authorized'
  # Then a later day, by a second reconciliation, again at a non-round time.
  printf '%s\0' round 5 timestamp 2026-07-21T06:17:43Z report_digest "$digest" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-21T06:17:43Z'
  printf '%s\n' '- 2026-07-21T06:17:42Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=one second before the later-day completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-21T06:17:43Z' \
''')

out = text.encode('utf-8')
open(os.path.join(root, G), 'wb').write(out)
print('%s  %s' % (hashlib.sha256(out).hexdigest(), G))
