#!/usr/bin/env python3
# Session 23 (2026-10-15): T031a1 to T031a4, the fixtures reality-check round 2 found missing (gaps 1 to 4 in STATUS
# Open questions), test files only, no kernel change, as the user chose on 2026-10-15 ("Add the tests"). Each case
# starts from the reviewer's probes (rc2-review-probes.txt, focused2.sh to focused4.sh).
#   T031a1 (AC-022): tests/test-spec-gate.sh acceptance_named_cases, called by test_acceptance.
#   T031a2 (AC-007, AC-020): reuse_floor_cases (test_floor) changes an opted-in gate_checks command string;
#          tests/test-verification.sh capture_validity_cases (test_capture_provenance) takes the floor's reuse path
#          (vf_gate_execute) with another argv.
#   T031a3 (AC-010): tests/test-gate-contracts.sh tally_class_cases, called by test_reports_and_tally.
#   T031a4 (AC-009): tests/test-spec-gate.sh round_legacy_reconcile_cases, called by test_rounds.
# Usage: python3 -I <this> <root>   (root: the worktree, or a standalone copy of it)
# Refuses unless the three files hash as at HEAD 0d55c62's live state and every anchor occurs exactly once; prints
# the new sha256 of each file.
import hashlib, os, sys
root = sys.argv[1]
pre = {
    'tests/test-spec-gate.sh': '4460312501d181e1bac0c2f4028af510afc47cae57ba202a360b7a108594c73c',
    'tests/test-verification.sh': 'bc62b027c1d65b8879aa56e91d4fb7a16c543032adf24abaa974c9f7eb49b749',
    'tests/test-gate-contracts.sh': '813f217995d6fc1b678723fdd74cceefd31380ecfb713cd2e216fd3a0539d8ae',
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
# T031a1 (AC-022): the named acceptance cases.
once(G, 'test_acceptance() {\n  acceptance_parse_fault_cases\n',
r'''# AC-022/FM-006/FM-010/INV-002 — T031a1, the cases reality-check round 2 found
# no fixture for. A return with no Failure modes block, a capture that does not
# exist, a capture of an unrelated command whose log names the test, a capture
# whose command exited nonzero and a manual return whose artifact is absent are
# each refused, leaving tasks.md byte-identical. A valid return ticks its own
# task and adds its Evidence line, and changes nothing else; a task owing no
# rows is accepted with an explicit `Failure modes: none`.
acceptance_named_cases() {
  local spec repo cap other failed before digest expected
  spec="$(make_verification_git_dir acceptnamed)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/named-good"
  before="$(cat "$spec/tasks.md")"
  sed '/^Failure modes:/,$d' "$SANDBOX/named-good" > "$SANDBOX/named-nofm"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-nofm"
  assert_contains "$OUT" 'incomplete verification return' 'AC-022: a return with no Failure modes block was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a return with no Failure modes block changed tasks bytes'
  sed "s/$cap/CAP-999-zzzzzz/g" "$SANDBOX/named-good" > "$SANDBOX/named-unknown"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-unknown"
  assert_contains "$OUT" 'capture integrity: missing COMPLETE or linked directory' 'AC-022: a nonexistent capture was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a nonexistent capture changed tasks bytes'
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --no-tick --summary -- bash -c 'echo test_ac_001_shared passed'
  other="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$other" "$SANDBOX/named-unrelated"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-unrelated"
  assert_contains "$OUT" 'do not prove this task Verify' 'AC-022: a log naming the test proved an unrelated command'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: an unrelated capture changed tasks bytes'
  cp "$repo/tests/check.sh" "$SANDBOX/named-check"
  printf 'exit 5\n' >> "$repo/tests/check.sh"
  run_rc 5 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  failed="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  cp "$SANDBOX/named-check" "$repo/tests/check.sh"
  accept_return "$spec" T001 "$failed" "$SANDBOX/named-failed"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-failed"
  assert_contains "$OUT" 'capture failed: exit 5' 'AC-022: a capture whose command exited nonzero was accepted'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a failed capture changed tasks bytes'
  mkdir -p "$repo/artifacts"
  printf observed-release > "$repo/artifacts/release.txt"
  digest="$(shasum -a 256 < "$repo/artifacts/release.txt" | awk '{print $1}')"
  rm "$repo/artifacts/release.txt"
  printf 'Verification-Return: 1\nTask: T004\nCaptures: none\nSummary: observed\nManual observation: release-observation, artifacts/release.txt, %s, fixture-observer, 2026-09-06T12:00:00Z, PASS: ok\nFailure modes:\nINV-001, release-observation, manual\n' "$digest" > "$SANDBOX/named-manual"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T004 "$SANDBOX/named-manual"
  assert_contains "$OUT" 'manual artifact missing or digest mismatch' 'AC-022: a manual return whose artifact is absent was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a manual return with no artifact changed tasks bytes'
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-good"
  digest="$(printf '%s' "$OUT" | sed -n 's/.* return=\([0-9a-f]*\).*/\1/p')"
  # The expected file: T001 ticked and its Evidence line added at the end of
  # its block; the frontmatter `updated:` stamp is the writer's own.
  expected="$(printf '%s\n' "$before" | awk -v ev="  - *Evidence:* $cap verified by spec-gate accept; return sha256:$digest" '
    /^- \[ \] \*\*T001\*\*/ {sub(/^- \[ \]/, "- [x]"); on=1; print; next}
    on && !/^  / {print ev; on=0}
    {print}')"
  assert_eq "$expected" "$(sed '/^updated: [0-9-]*$/d' "$spec/tasks.md")" \
    'AC-022: a valid acceptance changed more than its own checkbox and Evidence line'
  cat > "$SANDBOX/named-t006" <<'EOF'
- [ ] **T006** — Cover the shell check with no failure-mode rows
  - *Files:* `src/parser.sh`, `tests/check.sh`
  - *Acceptance:* the shell family passes
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
  - *Refs:* REQ-001, AC-001

EOF
  awk -v insert="$SANDBOX/named-t006" '
    /^## Reality Check/ {while ((getline line < insert) > 0) print line; close(insert)}
    {print}' "$spec/tasks.md" > "$SANDBOX/named-tasks"
  cp "$SANDBOX/named-tasks" "$spec/tasks.md"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T006 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  { printf 'Verification-Return: 1\nTask: T006\nCaptures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes: none\n'; } > "$SANDBOX/named-none"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T006 "$SANDBOX/named-none"
  assert_contains "$OUT" 'accept accepted' 'AC-022: a task owing no rows was refused with an explicit Failure modes: none'
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T006**'
}

test_acceptance() {
  acceptance_parse_fault_cases
''')
once(G, '  narrative_return_cases\n  followup_binding_cases\n}\n',
        '  narrative_return_cases\n  followup_binding_cases\n  acceptance_named_cases\n}\n')
# T031a2 (AC-007, AC-020): a changed opted-in command string executes again.
once(G, '''  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xxx "$(cat "$SANDBOX/suite-count")"
}
''', r'''  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xxx "$(cat "$SANDBOX/suite-count")"
  # AC-007/AC-020 — T031a2. A changed command string is another check: the
  # same suite opted in as `bash ./tests/check.sh` runs again and reuses
  # nothing (capture_validity_cases holds the inputs fixed and varies the argv
  # alone).
  sed "s#'bash tests/check.sh'#'bash ./tests/check.sh'#" "$repo/.specify/stack.yml" > "$SANDBOX/reuse-stack"
  cp "$SANDBOX/reuse-stack" "$repo/.specify/stack.yml"
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xxxx "$(cat "$SANDBOX/suite-count")" 'AC-007: a changed gate_checks command string reused the old success'
  assert_contains "$OUT" 'cache-hits=0' 'AC-007: a changed gate_checks command string counted a cache hit'
}
''')
# T031a4 (AC-009): legacy date-only history needs explicit timestamp reconciliation.
once(G, 'test_rounds() {\n  round_locale_cases\n',
r'''# AC-009/FM-016/INV-004 — T031a4, the case reality-check round 2 found no
# fixture for. A copy of shipped 002's date-only opponent history (five rounds
# with dates and no times) cannot order an authorization, so the next round is
# refused at exit 4 until `round --reconcile` records an explicit timestamp
# bound to the history's digest; an exact waiver written after it then
# authorizes round 6, which reserves on a fresh floor.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp
  spec="$(make_verification_git_dir legacyround)"
  cli="$(floor_fixture "$spec")"
  copy_kit "$KIT_DIR" "$SANDBOX/legacy-002" "$rel/notes" || t_fail 'AC-009: cannot copy shipped 002 records as the identity hashes them'
  mkdir -p "$spec/notes"
  cp "$SANDBOX/legacy-002/$rel/notes/opponent.md" "$spec/notes/opponent.md"
  run_rc 4 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'date-only history needs timestamped digest reconciliation' \
    'AC-009: date-only history ordered an authorization without reconciliation'
  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-6" ]] || t_fail 'AC-009: a refused legacy round reserved round 6'
  printf '%s\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$(shasum -a 256 < "$spec/notes/opponent.md" | awk '{print $1}')" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T23:59:59Z'
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '\n## Decisions log\n- %s — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=order after the reconciled legacy history\n' "$stamp" >> "$spec/STATUS.md"
  run_rc 0 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'authorized: opponent round 6' 'AC-009: an exact waiver after reconciliation was not authorized'
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'round=6 gate=opponent' 'AC-009: an exact waiver after reconciliation did not reserve the next round'
}

test_rounds() {
  round_locale_cases
''')
once(G, '  round_preamble_cases\n  round_verdict_source_cases\n  local spec gate cli n reservation stamp report\n',
        '  round_preamble_cases\n  round_verdict_source_cases\n  round_legacy_reconcile_cases\n  local spec gate cli n reservation stamp report\n')

V = 'tests/test-verification.sh'
# T031a2 (AC-020, AC-007): the floor's reuse path does not reuse a capture for another argv.
once(V, '''capture_check_fixture() {
  bash -c '. "$1"; vf_capture_check "$2" "$3" "$4" "$5"' _ "$SCRIPTS/verification-lib.sh" "$@"
}
''', r'''capture_check_fixture() {
  bash -c '. "$1"; vf_capture_check "$2" "$3" "$4" "$5"' _ "$SCRIPTS/verification-lib.sh" "$@"
}

# gate_execute_fixture <spec> <capture> <repo> <command> — the floor's reuse
# path (vf_gate_execute) for a task:T001 record under local policy, with the
# capture's own bindings as the catalog; one record per call is appended to
# $SANDBOX/gate-records.
gate_execute_fixture() {
  bash -c '. "$1"; VF_GATE_FRESH="$2"; vf_gate_execute "$3" "$3/notes/captures/$4/bindings.nul" "$5" local "$6" task:T001 -- "$(command -v bash)" -o pipefail -c "$7"' \
    _ "$SCRIPTS/verification-lib.sh" "$SANDBOX/gate-fresh" "$1" "$2" "$3" "$SANDBOX/gate-records" "$4"
}
''')
once(V, '''  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 0 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  for file in output.log COMPLETE argv.nul inputs.nul bindings.nul meta.nul; do
''', r'''  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 0 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  # AC-020/AC-007 — T031a2. Reuse is keyed on the exact argv: with the inputs
  # unchanged, the passing capture serves its own command and is not reused
  # for another command string that runs the same test.
  : > "$SANDBOX/gate-records"
  run_rc 0 gate_execute_fixture "$spec" "$cap" "$repo" 'bash tests/check.sh'
  run_rc 0 gate_execute_fixture "$spec" "$cap" "$repo" 'bash ./tests/check.sh'
  local rcap cached got=''
  while IFS= read -r -d '' _ && IFS= read -r -d '' _ && IFS= read -r -d '' _ && IFS= read -r -d '' _ \
      && IFS= read -r -d '' rcap && IFS= read -r -d '' cached; do
    if [[ "$rcap" == "$cap" ]]; then got+="old:$cached "; else got+="new:$cached "; fi
  done < "$SANDBOX/gate-records"
  assert_eq 'old:1 new:0 ' "$got" 'AC-020: a passing capture was reused for another argv, or not reused for its own'
  for file in output.log COMPLETE argv.nul inputs.nul bindings.nul meta.nul; do
''')

C = 'tests/test-gate-contracts.sh'
# T031a3 (AC-010): class recurrence across files and root causes; an annotated 002 copy.
once(C, 'test_reports_and_tally() {\n',
r'''# annotate_002 — shipped 002's legacy opponent history on stdin, as canonical
# rounds on stdout. Each legacy finding keeps its round, severity, Root cause
# and first location and gains the stable Class the table gives its
# round.number: the two clock findings share one, the three lock findings
# another. Legacy rounds themselves carry no Class (AC-010).
annotate_002() {
  awk -v classes='1.1=clock-reset-grammar 2.1=resume-unit-lock 3.1=resume-unit-lock 4.1=scheduler-environment 4.2=resume-unit-lock 4.3=clock-reset-grammar' '
    BEGIN {n = split(classes, pairs, " "); for (i = 1; i <= n; i++) {split(pairs[i], kv, "="); cls[kv[1]] = kv[2]}}
    /^\*\*Verdict:\*\* / {verdict = $2}
    /^\*\*Round:\*\* [0-9]+$/ {r = $2; rv[r] = verdict; if (r > last) last = r; next}
    /^[0-9]+\. .*severity:/ {
      k = $1; sub(/\.$/, "", k); f++; fr[f] = r; fk[f] = k
      s = $0; sub(/^.*severity:\*[ ]*/, "", s); fs[f] = s; inwhere = 0; next
    }
    /^[ ]*- \*\*Where:\*\*/ {inwhere = 1}
    /^[ ]*- \*\*/ && !/^[ ]*- \*\*Where:\*\*/ {inwhere = 0}
    inwhere && f && fl[f] == "" && match($0, /scripts\/[A-Za-z0-9._-]+:[0-9]+/) {fl[f] = substr($0, RSTART, RLENGTH)}
    f && /^[ ]*- \*\*Root cause:\*\* / {c = $0; sub(/^[ ]*- \*\*Root cause:\*\* /, "", c); sub(/[^a-z-].*$/, "", c); fc[f] = c}
    END {
      for (r = 1; r <= last; r++) {
        b = 0; for (i = 1; i <= f; i++) if (fr[i] == r) b++
        printf "## Round %d\n**Round:** %d\n**Timestamp:** 2026-07-20T12:00:0%dZ\n", r, r, r
        printf "**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n", rv[r]
        printf "**Blocking:** %d · **Minor:** 0\n### What I attacked\nShipped 002 round %d, annotated with stable classes.\n", b, r
        for (i = 1; i <= f; i++) if (fr[i] == r) {
          printf "### Finding O-%03d\n- **Class:** %s\n- **Status:** new\n- **Prior:** none\n- **Severity:** %s\n", i, cls[r "." fk[i]], fs[i]
          printf "- **Scenario:** shipped 002 round %d finding %d\n- **Where:** %s\n- **Reproduced:** as recorded in shipped 002\n", r, fk[i], fl[i]
          printf "- **Root cause:** %s\n- **Blocks:** AC-010\n- **Wrong behavior:** as recorded in shipped 002\n- **Class-wide fix:** as recorded in shipped 002\n", fc[i]
        }
        printf "### Held up / follow-up tasks\nAnnotated fixture.\n<!-- gate-round-end: opponent:%d -->\n", r
      }
    }'
}

# AC-010/FM-019/INV-006 — T031a3, the cases reality-check round 2 found no
# fixture for. Recurrence is keyed by Class alone: two findings of one Class at
# different files with different Root causes are one recurrence, and two
# Classes sharing a file and a Root cause are none. An annotated copy of
# shipped 002 detects both its clock and its lock recurrence, and neither the
# copy nor the shipped notes change.
tally_class_cases() {
  local spec="$SANDBOX/class-spec" rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/annotate-002" shipped
  mkdir -p "$spec/notes" "$SANDBOX/annotated/notes"
  { tier_round_fixture 1 '' O-001:clock-parse:new:wrong-result O-002:lock-a:new:wrong-result O-003:lock-b:new:wrong-result
    tier_round_fixture 2 '' O-004:clock-parse:new:wrong-result \
      | sed -e 's#^- \*\*Where:\*\* .*#- **Where:** scripts/cancel.sh:4#' -e 's#^- \*\*Root cause:\*\* .*#- **Root cause:** plan-gap#'
  } > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'class=clock-parse findings=2 recurrences=1' \
    'AC-010: one Class at different files with different Root causes was not one recurrence'
  assert_contains "$OUT" 'class=lock-a findings=1 recurrences=0' 'AC-010: Classes sharing a file and Root cause counted a recurrence'
  assert_contains "$OUT" 'class=lock-b findings=1 recurrences=0' 'AC-010: Classes sharing a file and Root cause counted a recurrence'
  shipped="$(shasum -a 256 < "$KIT_DIR/$rel/notes/opponent.md")"
  copy_kit "$KIT_DIR" "$copy" "$rel/notes" || t_fail 'AC-010: cannot copy shipped 002 records as the identity hashes them'
  annotate_002 < "$copy/$rel/notes/opponent.md" > "$SANDBOX/annotated/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$SANDBOX/annotated"
  assert_contains "$OUT" 'opponent rounds=5'
  assert_contains "$OUT" 'blocking=6 minor=0 locations=6 unclassified=0'
  assert_contains "$OUT" 'class=clock-reset-grammar findings=2 recurrences=1' 'AC-010: the annotated 002 copy missed its clock recurrence'
  assert_contains "$OUT" 'class=resume-unit-lock findings=3 recurrences=2' 'AC-010: the annotated 002 copy missed its lock recurrence'
  assert_eq "$shipped" "$(shasum -a 256 < "$copy/$rel/notes/opponent.md")" 'AC-010: annotating changed the 002 copy'
  assert_eq "$shipped" "$(shasum -a 256 < "$KIT_DIR/$rel/notes/opponent.md")" 'AC-010: the shipped 002 notes changed'
}

test_reports_and_tally() {
''')
once(C, '  mkdir -p "$spec/notes"\n  shipped_002_tally_case\n',
        '  mkdir -p "$spec/notes"\n  shipped_002_tally_case\n  tally_class_cases\n')

for p, t in text.items():
    open(os.path.join(root, p), 'wb').write(t.encode('utf-8'))
    print('%s  %s' % (hashlib.sha256(t.encode('utf-8')).hexdigest(), p))
