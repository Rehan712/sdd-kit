#!/usr/bin/env python3
# Session 24 (2026-10-16): the round-20 repair, test files only, no kernel change, as the user chose on 2026-10-16
# (fix O-029 on the PR branch before merge; O-030 and O-031 with it). Each case starts from round 20's report
# (opponent-round20.md) and the reproduction r20-repro-o029.sh.
#   T031a4o1 (O-029, AC-009/REQ-012): tests/test-spec-gate.sh round_legacy_reconcile_cases, called by test_rounds.
#   T031a1o1 (O-030, AC-022): tests/test-spec-gate.sh acceptance_named_cases, called by test_acceptance.
#   T031a3o1 (O-031, AC-010): tests/test-gate-contracts.sh shipped_002_tally_case and tally_class_cases, called by
#            test_reports_and_tally.
# Usage: python3 -I <this> <root>   (root: the worktree, or a standalone copy of it)
# Refuses unless both files hash as at HEAD 2049f65 and every anchor occurs exactly once; prints the new sha256 of
# each file.
import hashlib, os, sys
root = sys.argv[1]
pre = {
    'tests/test-spec-gate.sh': 'a5c7a0d0bcd16de00816974842fe52556c4bcc002ab8a528960b8c8f3dc96ea6',
    'tests/test-gate-contracts.sh': 'f927e872de6b5256111191a4472321fc0e03f540b1eec3aa91aa31aff7cb1962',
}
text = {}
for p, h in pre.items():
    b = open(os.path.join(root, p), 'rb').read()
    assert hashlib.sha256(b).hexdigest() == h, 'refusing: %s does not hash as the frozen source' % p
    text[p] = b.decode('utf-8')

def once(p, old, new):
    n = text[p].count(old)
    assert n == 1, '%s: anchor count %d: %r' % (p, n, old[:90])
    text[p] = text[p].replace(old, new)

G = 'tests/test-spec-gate.sh'
# T031a1o1 (O-030): the empty-header refusal that gives the explicit none its meaning.
once(G, '''# rows is accepted with an explicit `Failure modes: none`.
acceptance_named_cases() {''', '''# rows is accepted with an explicit `Failure modes: none`, and only with it: an
# empty `Failure modes:` header for that task is refused first (T031a1o1,
# round 20's O-030).
acceptance_named_cases() {''')
once(G, '''  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T006 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\\([^ ]*\\).*/\\1/p')"
  { printf 'Verification-Return: 1\\nTask: T006\\nCaptures: %s\\nSummary: ' "$cap"
''', '''  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T006 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\\([^ ]*\\).*/\\1/p')"
  before="$(cat "$spec/tasks.md")"
  { printf 'Verification-Return: 1\\nTask: T006\\nCaptures: %s\\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes:\\n'; } > "$SANDBOX/named-empty"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T006 "$SANDBOX/named-empty"
  assert_contains "$OUT" 'empty required set must explicitly be none' \\
    'AC-022: an empty Failure modes header was accepted for a task owing no rows'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: an empty Failure modes header changed tasks bytes'
  { printf 'Verification-Return: 1\\nTask: T006\\nCaptures: %s\\nSummary: ' "$cap"
''')

# T031a4o1 (O-029): the refusals only the reconciled record can decide.
once(G, '''# authorizes round 6, which reserves on a fresh floor.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp
''', '''# authorizes round 6, which reserves on a fresh floor.
# T031a4o1 (round 20, O-029): the refusals only the reconciled record decides.
# A record naming a wrong digest, a wrong round or a timestamp before the
# history's date exits 3, writes no legacy-time.nul and leaves the next round
# refused as date-only; a waiver after the history's date but before the
# reconciled time is refused; and an edit of the history after reconciling
# unbinds the record, so neither waiver nor round authorizes or reserves. The
# kernel names none of the exit-3 refusals (O-032), so the cases assert state.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp digest bad legacy
''')
once(G, '''  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-6" ]] || t_fail 'AC-009: a refused legacy round reserved round 6'
  printf '%s\\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$(shasum -a 256 < "$spec/notes/opponent.md" | awk '{print $1}')" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T23:59:59Z'
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '\\n## Decisions log\\n- %s — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=order after the reconciled legacy history\\n' "$stamp" >> "$spec/STATUS.md"
  run_rc 0 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'authorized: opponent round 6' 'AC-009: an exact waiver after reconciliation was not authorized'
  run_rc 0 bash "$cli" floor "$spec"
''', '''  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-6" ]] || t_fail 'AC-009: a refused legacy round reserved round 6'
  legacy="$spec/notes/verification/rounds/opponent/legacy-time.nul"
  digest="$(shasum -a 256 < "$spec/notes/opponent.md" | awk '{print $1}')"
  for bad in digest round timestamp; do
    case "$bad" in
      digest) printf '%s\\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$(printf '%064d' 0)";;
      round) printf '%s\\0' round 4 timestamp 2026-07-20T23:59:59Z report_digest "$digest";;
      timestamp) printf '%s\\0' round 5 timestamp 2026-07-19T23:59:59Z report_digest "$digest";;
    esac > "$SANDBOX/legacy-wrong-$bad.nul"
    run_rc 3 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-wrong-$bad.nul"
    [[ ! -e "$legacy" ]] || t_fail "AC-009: a reconcile record with a wrong $bad wrote legacy-time.nul"
    run_rc 4 bash "$cli" round "$spec" opponent
    assert_contains "$OUT" 'date-only history needs timestamped digest reconciliation' \\
      "AC-009: a reconcile record with a wrong $bad left the history able to order an authorization"
    # Each wrong record is judged alone, even where a regression wrote one.
    rm -f "$legacy"
  done
  printf '%s\\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$digest" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T23:59:59Z'
  # After the history's date, before the reconciled time: only the record decides.
  printf '\\n## Decisions log\\n%s\\n' '- 2026-07-20T12:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=dated before the reconciled completion' >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'not after the previous round completion at 2026-07-20T23:59:59Z' \\
    'AC-009: a waiver dated before the reconciled completion authorized the next round'
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\\n' "- $stamp — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=order after the reconciled legacy history" >> "$spec/STATUS.md"
  run_rc 0 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'authorized: opponent round 6' 'AC-009: an exact waiver after reconciliation was not authorized'
  # An edit of the history unbinds the record: the floor is current for the
  # edited history, so only the binding refuses the round.
  cp "$spec/notes/opponent.md" "$SANDBOX/legacy-history"
  printf 'Edited after reconciliation.\\n' >> "$spec/notes/opponent.md"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 3 bash "$cli" waiver "$spec" opponent 6
  assert_not_contains "$OUT" 'authorized' 'AC-009: a reconcile record outlived an edit of its history and authorized round 6'
  run_rc 3 bash "$cli" round "$spec" opponent
  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-6" ]] || t_fail 'AC-009: a reconcile record outlived an edit of its history and reserved round 6'
  cp "$SANDBOX/legacy-history" "$spec/notes/opponent.md"
  run_rc 0 bash "$cli" floor "$spec"
''')

C = 'tests/test-gate-contracts.sh'
# T031a3o1 (O-031): hash what tally reads before and after the run.
once(C, '''# is invisible to the identity yet walked by the tally (O-015 review).
shipped_002_tally_case() {
  local rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/tally-002"
  rm -rf "$copy"
  copy_kit "$KIT_DIR" "$copy" "$rel/notes" || t_fail 'AC-010: cannot copy shipped 002 records as the identity hashes them'
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$copy/$rel"
''', '''# is invisible to the identity yet walked by the tally (O-015 review). The
# records the tally reads are hashed before and after it (T031a3o1, O-031).
shipped_002_tally_case() {
  local rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/tally-002" before
  rm -rf "$copy"
  copy_kit "$KIT_DIR" "$copy" "$rel/notes" || t_fail 'AC-010: cannot copy shipped 002 records as the identity hashes them'
  before="$(records_digest "$copy/$rel")"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$copy/$rel"
  assert_eq "$before" "$(records_digest "$copy/$rel")" 'AC-010: the tally rewrote the shipped 002 records it read'
''')
once(C, '''# annotate_002 — shipped 002's legacy opponent history on stdin, as canonical
''', '''# records_digest <dir> — one digest over the name and bytes of every file under
# <dir>, so a reader that writes anything it reads is caught (O-031).
records_digest() {
  (cd "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s\\n' "$f"; shasum -a 256 < "$f"; done) | shasum -a 256
}

# annotate_002 — shipped 002's legacy opponent history on stdin, as canonical
''')
once(C, '''# shipped 002 detects both its clock and its lock recurrence, and neither the
# copy nor the shipped notes change.
tally_class_cases() {
  local spec="$SANDBOX/class-spec" rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/annotate-002" shipped
''', '''# shipped 002 detects both its clock and its lock recurrence. Each history the
# tally reads is hashed before and after it (T031a3o1, O-031); the copy check
# proves only that copy_kit is faithful.
tally_class_cases() {
  local spec="$SANDBOX/class-spec" rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/annotate-002" shipped before
''')
once(C, '''  } > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'class=clock-parse findings=2 recurrences=1' \\
''', '''  } > "$spec/notes/opponent.md"
  before="$(records_digest "$spec")"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_eq "$before" "$(records_digest "$spec")" 'AC-010: the tally rewrote the synthetic history it read'
  assert_contains "$OUT" 'class=clock-parse findings=2 recurrences=1' \\
''')
once(C, '''  annotate_002 < "$copy/$rel/notes/opponent.md" > "$SANDBOX/annotated/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$SANDBOX/annotated"
''', '''  annotate_002 < "$copy/$rel/notes/opponent.md" > "$SANDBOX/annotated/notes/opponent.md"
  before="$(records_digest "$SANDBOX/annotated")"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$SANDBOX/annotated"
  assert_eq "$before" "$(records_digest "$SANDBOX/annotated")" 'AC-010: the tally rewrote the annotated 002 history it read'
''')
once(C, '''  assert_eq "$shipped" "$(shasum -a 256 < "$copy/$rel/notes/opponent.md")" 'AC-010: annotating changed the 002 copy'
  assert_eq "$shipped" "$(shasum -a 256 < "$KIT_DIR/$rel/notes/opponent.md")" 'AC-010: the shipped 002 notes changed'
''', '''  assert_eq "$shipped" "$(shasum -a 256 < "$copy/$rel/notes/opponent.md")" 'AC-010: copy_kit did not copy the shipped 002 notes faithfully'
  assert_eq "$shipped" "$(shasum -a 256 < "$KIT_DIR/$rel/notes/opponent.md")" 'AC-010: the shipped 002 notes changed during the case'
''')

for p in pre:
    b = text[p].encode('utf-8')
    open(os.path.join(root, p), 'wb').write(b)
    print('%s  %s' % (hashlib.sha256(b).hexdigest(), p))
