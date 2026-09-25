#!/usr/bin/env bash
# Static schema/instruction assertions; runtime contracts add executable cases
# in their owning tasks. An ID in an example is never runtime proof.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

# --- O-010: the superseded fixed-environment membership -------------------------
#
# T030o25 made the environment record's membership EXACTLY the project
# declaration. An authoritative restatement of the superseded rule standing
# beside that replacement is the defect this guard exists to catch. Round 5
# bound it to one file handle; round 6 bound it to one 17-character ASCII
# literal over `*.md`/`*.sh`/`*.yml` under a `-name captures -prune`. Both were
# enumerations, and round 7 defeated the second with the shapes this repository
# own conventions produce.
#
# SCOPE is taken from the enumeration the input manifest itself uses --
# `vf_source_paths`, the very function vf_snapshot's path pass calls, filtered
# through `vf_bookkeeping_path`, the same predicate vf_snapshot applies --
# rather than restated as a find(1) filter or a second git command line, so it
# cannot drift when a new extension appears, a directory is named `captures`
# somewhere the anchored bookkeeping path does not cover, or git quotes a name.
# A tree that cannot be enumerated is an error, never an empty and therefore
# clean tree. That predicate excludes only the VERIFIED spec's generated
# records, and the scan anchors each path to the spec that CONTAINS it: a
# spec's generated gate records are historical copies whichever spec is being
# verified, while another spec's non-generated notes stay in scope. Measured
# 2026-09-23: anchored to 003 alone the live scan is clean, but with no anchor
# it reports 29 claims, all quotations inside 003's own sealed records -- and
# those records are ordinary source in every LATER spec's manifest, so a scope
# equal to one verified spec's manifest would fail the next spec on history.
# STATUS.md is the one further subtraction: its Decisions log is an
# append-only record of what was true when each entry was written.
#
# CONTENT is read the same way: each path passes through `vf_path_content`,
# the function vf_path_record itself calls to decide which bytes the identity
# hashes (a link's target as it is, a file through `vf_semantic_file`), and
# only that output is scanned. This guard runs inside reuse-checked commands, so its
# verdict must be a function of the input identity. Round 10 (O-015) showed the
# raw bytes are not: a sentence on a spec's Evidence line or `status:`/`updated:`
# line failed this suite while the identity -- and so every reusable PASS of
# it -- stayed unchanged.
#
# The NEEDLE matches the PROPOSITION. Each candidate is normalized to a single
# whitespace-collapsed stream with backticks and asterisks stripped, so a hard
# wrap, a code span or emphasis cannot hide the claim --
# the guard reads lines, the claim is a sentence, and this repository wraps
# sentences. A claim is then a MEMBERSHIP predicate governing any of the names,
# in any order and any subset, in either direction, with no negation in the
# connective between them: the same names under the opposite claim ("are
# dropped", "are no longer hashed", "No name is hashed because ...") state the
# CURRENT rule and are exactly what the replacement text says.
# No EXIT trap: the wrapper owns one private directory and removes it on every
# path (see copy_kit in helpers.sh for the trap-scope incident this avoids).
superseded_environment_scan() ( # root -> one line per surviving claim; exit 1, by name, when the tree cannot be read
  local work rc
  work="$(mktemp -d "${TMPDIR:-/tmp}/env-scan.XXXXXX")" || return 1
  superseded_environment_scan_in "$1" "$work"
  rc=$?
  rm -rf -- "$work"
  return "$rc"
)
superseded_environment_scan_in() ( # root work-dir
  local root path own second rest list="$2/list" content="$2/content" fold=0
  . "$SCRIPTS/lib.sh"
  . "$SCRIPTS/verification-lib.sh"
  root="$(cd "$1" && pwd -P)" || return 1
  vf_source_paths "$root" "$list" || { echo "superseded_environment_scan: cannot enumerate $1" >&2; return 1; }
  # Letter case folds exactly where the identity folds it: OPPONENT.md IS
  # opponent.md on a folding filesystem, so a case-variant spelling of a
  # spec's generated record is that record here too.
  ! vf_case_folds "$root" || fold=1
  while IFS= read -r -d '' path; do
    own=''
    [[ "$fold" != 1 ]] || shopt -s nocasematch
    case "$path" in
      .specify/specs/*/*) second="${path#*/}"; rest="${second#*/}"; own="${path%%/*}/${second%%/*}/${rest%%/*}";;
    esac
    shopt -u nocasematch
    vf_bookkeeping_path "$path" "$own" "$fold" && continue
    case "$path" in STATUS.md|*/STATUS.md) continue;; esac
    [[ -f "$root/$path" ]] || continue
    # The bytes the identity hashes for this path, from the function
    # vf_path_record itself calls: a link's target as it is, a file through
    # vf_semantic_file.
    vf_path_content "$root" "$path" "$content" || { echo "superseded_environment_scan: cannot read $path" >&2; return 1; }
    P="$path" LC_ALL=C awk '
      function negated(gap) {
        return gap ~ /(^| )(no|not|never|none|nothing|neither|nor|without)( |[.,;:])/ ||
               gap ~ /(no longer|instead of|rather than|superseded|dropped|removed|excluded)/
      }
      # The name arrives through the environment, not -v: -v rewrites
      # backslash escapes and BSD awk refuses a newline in its value.
      function report(claim) {printf "%s :: %s\n", ENVIRON["P"], claim}
      # Backticks and asterisks only. Underscores are NOT stripped: `LC_` is a
      # NAME this guard searches for, and deleting the underscore deletes the
      # needle -- measured, an `LC_*`-only claim escaped a normalizer that
      # stripped it. Emphasis never splits a variable name in this repository;
      # variable names contain underscores.
      {gsub(/[`*]/, ""); stream = stream " " $0}
      END {
        gsub(/[[:space:]]+/, " ", stream)
        rest = stream
        while (match(rest, /(PATH|SHELL|LANG|TMPDIR|LC_)/)) {
          at = RSTART; len = RLENGTH
          before = substr(rest, 1, at - 1); after = substr(rest, at + len)
          # Forward: "<predicate> <connective> <NAME>". The predicate must
          # GOVERN the name, so only a short connective may sit between them
          # and it may not cross a sentence boundary.
          tail = substr(before, length(before) - 59 < 1 ? 1 : length(before) - 59)
          if (match(tail, /(always includes|also includes|includes|include|hashes|hashed|plus)[^.]{0,25}$/)) {
            # The negation window reaches BEHIND the predicate as well as
            # between it and the name: English negates this proposition in
            # front of its verb ("no longer includes PATH"), so a window that
            # began at the predicate would read the replacement rule as the
            # superseded one.
            gap = substr(tail, RSTART > 20 ? RSTART - 20 : 1)
            if (!negated(gap)) {report(substr(tail, RSTART, RLENGTH) substr(rest, at, len)); rest = after; continue}
          }
          # Reverse: "<NAME> ... is/are hashed|included". The predicate must be
          # a PASSIVE VERB PHRASE, not a bare participle: this repository writes
          # "LC_CTYPE and LC_ALL included" meaning "among them", which is not a
          # membership claim at all. Same governing requirement as the forward
          # rule; a negation inside the connective is the opposite claim.
          head = substr(after, 1, 70)
          if (match(head, /^[^.]{0,40}(is|are|were|remain|remains) (always |still |also )?(hashed|included|part of the (snapshot|manifest|set))/)) {
            gap = substr(head, 1, RLENGTH)
            if (!negated(gap)) {report(substr(rest, at, len) gap); rest = substr(after, RLENGTH + 1); continue}
          }
          rest = after
        }
      }
    ' "$content" || { echo "superseded_environment_scan: cannot scan $path" >&2; return 1; }
  done < "$list"
)

superseded_environment_cases() {
  local tree name shape reported
  # The live tree carries the replacement text and must be clean. The scan's
  # exit is asserted as well as its output: a tree it cannot read prints
  # nothing, and nothing is exactly what a clean tree prints.
  reported="$(superseded_environment_scan "$KIT_DIR")" || t_fail 'AC-018: the superseded-rule scan could not read the live tree'
  assert_eq '' "$reported" \
    'AC-018: superseded fixed-environment membership survives in a current artifact'

  # A guard proven only on the tree it already passes proves nothing, so the
  # SAME expression runs against a tree built from every shape this class has
  # escaped through. Claim text is assembled from tokens at run time: this file
  # is itself in scope, and a fixture that spelled the claim out would make the
  # scanner report its own source — refused, because a guard that must exempt
  # the file it lives in cannot see a stale claim there.
  local n_path=PATH n_shell=SHELL n_lang=LANG n_tmp=TMPDIR
  local n_lc='LC_*' n_lc_prefix=LC_
  local v_plus=plus
  local v_inc='always includes'
  local v_inc2=includes
  tree="$SANDBOX/env-claim-tree"
  mkdir -p "$tree/captures" "$tree/.specify/specs/003-x/notes/captures" || t_fail 'fixture tree'
  fixture_git -C "$tree" init -q || fixture_build_failed scan-tree-1
  # 1-2: the verbatim claim, and the same sentence hard-wrapped mid-phrase.
  printf 'Snapshot membership is the declared list %s %s, %s, %s, %s and %s.\n' \
    "$v_plus" "$n_path" "$n_shell" "$n_lang" "$n_lc" "$n_tmp" > "$tree/verbatim.md"
  printf 'Snapshot membership is the declared list %s %s, %s,\n%s, %s and %s.\n' \
    "$v_plus" "$n_path" "$n_shell" "$n_lang" "$n_lc" "$n_tmp" > "$tree/hardwrapped.md"
  # 3: the names in code spans, the way this repository writes variable names.
  printf 'The snapshot %s `%s`, `%s`, `%s` and `%s`.\n' \
    "$v_inc" "$n_path" "$n_shell" "$n_lang" "$n_tmp" > "$tree/backticked.md"
  # 4: reordered. 5: a subset naming neither PATH nor SHELL, stated completely.
  printf 'The snapshot %s %s, %s, %s and %s.\n' \
    "$v_inc" "$n_shell" "$n_path" "$n_lang" "$n_tmp" > "$tree/reordered.md"
  printf 'The snapshot %s %s and every exported %s variable, so you need not declare them.\n' \
    "$v_inc" "$n_tmp" "$n_lc" > "$tree/subset.md"
  # 6: extensions the manifest hashes and the old find(1) filter could not see.
  printf 'Snapshot membership is the declared list %s %s and %s.\n' \
    "$v_plus" "$n_path" "$n_tmp" > "$tree/other-extension.txt"
  printf 'note: |\n  The snapshot %s %s and %s.\n' \
    "$v_inc" "$n_path" "$n_tmp" > "$tree/other-extension.yaml"
  # 7: a directory named captures anywhere, which the old -prune removed from
  # scope while the manifest excludes only the anchored bookkeeping path.
  printf 'The snapshot %s %s and %s.\n' \
    "$v_inc" "$n_path" "$n_tmp" > "$tree/captures/basename.md"
  # 8: the claim stated with the names first, which no forward rule would see.
  printf '%s, %s, %s and %s are always hashed by the snapshot.\n' \
    "$n_path" "$n_shell" "$n_lang" "$n_tmp" > "$tree/names-first.md"
  # 9: the family alone, naming no fixed variable. This states the superseded
  # rule completely, and it is the shape a normalizer that strips underscores
  # cannot see at all, because the underscore IS the needle.
  printf 'The snapshot %s every exported `%s` variable, so the project need not declare the locale categories.\n' \
    "$v_inc" "$n_lc" > "$tree/family-only.md"
  # D1: line joining alone does not normalize whitespace INSIDE a predicate.
  # Both a tab and repeated spaces are members of [[:space:]]+.
  printf '%s\tis\talways  hashed by the snapshot.\n' "$n_path" > "$tree/inner-whitespace.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  for shape in verbatim.md hardwrapped.md backticked.md reordered.md subset.md \
      other-extension.txt other-extension.yaml captures/basename.md names-first.md \
      family-only.md inner-whitespace.md; do
    assert_contains "$reported" "$shape" "AC-018: the superseded claim survived as $shape"
  done

  # Scope controls. The manifest excludes the anchored bookkeeping path, so the
  # same claim there is a sealed historical copy and is correctly invisible;
  # STATUS.md is the recorded log of what was true when it was written.
  printf 'The snapshot %s %s and %s.\n' "$v_inc" "$n_path" "$n_tmp" \
    > "$tree/.specify/specs/003-x/notes/captures/sealed.md"
  printf 'The snapshot %s %s and %s.\n' "$v_inc" "$n_path" "$n_tmp" > "$tree/STATUS.md"
  # O-013: each path is anchored to the spec that contains it, so ANOTHER
  # spec's generated gate record is a historical copy as well, while that
  # spec's other notes are current text and stay in scope.
  mkdir -p "$tree/.specify/specs/004-y/notes"
  printf 'The snapshot %s %s and %s.\n' "$v_inc" "$n_path" "$n_tmp" > "$tree/.specify/specs/004-y/notes/opponent.md"
  printf 'The snapshot %s %s and %s.\n' "$v_inc" "$n_path" "$n_tmp" > "$tree/.specify/specs/004-y/notes/history.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  assert_not_contains "$reported" 'notes/captures/sealed.md' \
    'AC-018: a sealed bookkeeping copy was treated as a current claim'
  assert_not_contains "$reported" 'STATUS.md' \
    'AC-018: the append-only Decisions log was treated as a current claim'
  assert_not_contains "$reported" '004-y/notes/opponent.md' \
    "AC-018: another spec's sealed gate record was treated as a current claim"
  assert_contains "$reported" '004-y/notes/history.md' \
    "AC-018: another spec's current notes escaped the superseded-rule scan"

  # The over-correction control, and the reason it is needed: a normalizing,
  # order-free matcher sees the same names in the sentences that state the
  # CURRENT rule. Each of these is real replacement text from this repository.
  rm -rf "$tree"; mkdir -p "$tree"; fixture_git -C "$tree" init -q || fixture_build_failed scan-tree-2
  printf -- '- T030o25 / O-010: environment-record membership is EXACTLY\n  `verification_environment:`; %s, %s, %s, %s and the %s family\n  are no longer hashed, with the reasoning recorded.\n' \
    "$n_path" "$n_shell" "$n_lang" "$n_tmp" "$n_lc" > "$tree/dossier.md"
  printf 'No name is hashed because the harness happens to run under it: `%s` is\nalready pinned by each declared tool, `%s` is never read, `%s` and the locale\ncategories are not read either, and `%s` decides where temporary files go.\n' \
    "$n_path" "$n_shell" "$n_lang" "$n_tmp" > "$tree/contract.md"
  printf 'A DECLARED variable still moves identity by presence and by value, with only the value hash reaching the manifest. `%s`, `%s`, `%s` and `%s` are dropped with the reason recorded.\n' \
    "$n_path" "$n_shell" "$n_lang" "$n_tmp" > "$tree/tasks.md"
  printf 'The snapshot environment set is exactly this declaration. Values are hashed; declared unset and present-empty values differ.\n' > "$tree/rule.md"
  # The same proposition negated in front of its verb, which is how English
  # states the replacement in the forward shape. Without a negation window that
  # reaches behind the predicate this reads as the superseded claim.
  printf 'The snapshot no longer %s `%s`, `%s`, `%s` or `%s`; membership is exactly the declaration.\n' \
    "$v_inc2" "$n_path" "$n_shell" "$n_lang" "$n_tmp" > "$tree/negated-forward.md"
  printf 'The snapshot no\tlonger %s %s.\n' "$v_inc2" "$n_path" > "$tree/negated-whitespace.md"
  # "included" as a post-modifier means "among them", not "in the hashed set".
  # This is real replacement text and the reason the reverse rule requires a
  # passive verb phrase rather than a bare participle.
  printf 'Any variable the project has not declared — `%sCTYPE` and `%sALL` included, the two most CI images export by default — leaves the source identity byte-identical.\n' \
    "$n_lc_prefix" "$n_lc_prefix" > "$tree/among-them.md"
  # A positive canary (review 5): one superseded claim that must be reported,
  # so the tree is shown to be scanned. Without it a scan that read nothing --
  # an enumeration a template's info/exclude empties, say -- satisfied this
  # control for every scan, over-correcting ones included.
  printf 'The snapshot %s %s, %s, %s and %s.\n' \
    "$v_inc" "$n_shell" "$n_path" "$n_lang" "$n_tmp" > "$tree/canary.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  assert_contains "$reported" 'canary.md :: ' \
    'AC-018: the control tree was not scanned: its superseded canary went unreported'
  assert_eq '' "$(printf '%s\n' "$reported" | grep -v '^canary\.md :: ' || true)" \
    'AC-018: the guard flagged a sentence stating the replacement rule'

  # O-015, round 10: the scan reads what the identity hashes, in both
  # directions. A claim on a spec's Evidence line or on a status:/updated:
  # frontmatter line is bookkeeping vf_semantic_file drops, so it is neither
  # reported nor visible to the identity; the same claim on a body line is
  # both. Visibility is asserted through the function vf_snapshot hashes.
  local spec_rel=.specify/specs/004-y claim f base quoted
  claim="$(printf 'the macOS job %s %s and %s shims for Bash 3.2' "$v_inc2" "$n_path" "$n_tmp")"
  rm -rf "$tree"; mkdir -p "$tree/$spec_rel" "$SANDBOX/env-base"; fixture_git -C "$tree" init -q || fixture_build_failed scan-tree-3
  printf -- '---\nstatus: shipped\nupdated: 2026-09-24\n---\n\n# Spec\n' > "$SANDBOX/env-base/spec.md"
  printf -- '---\nstatus: shipped\nupdated: 2026-09-24\n---\n\n# Plan\n' > "$SANDBOX/env-base/plan.md"
  printf -- '---\nstatus: in-progress\nupdated: 2026-09-24\n---\n\n- [x] **T001** — Task\n  - *Evidence:* hosted CI green (2026-09-24)\n' \
    > "$SANDBOX/env-base/tasks.md"
  printf -- '---\nstatus: shipped  # %s\nupdated: 2026-09-24\n---\n\n# Spec\n' "$claim" > "$tree/$spec_rel/spec.md"
  printf -- '---\nstatus: shipped\nupdated: 2026-09-24  # %s\n---\n\n# Plan\n' "$claim" > "$tree/$spec_rel/plan.md"
  printf -- '---\nstatus: in-progress\nupdated: 2026-09-24\n---\n\n- [x] **T001** — Task\n  - *Evidence:* hosted CI green; %s (2026-09-24)\n' \
    "$claim" > "$tree/$spec_rel/tasks.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  assert_eq '' "$reported" \
    'AC-020: a claim on a line the identity drops was scanned, so a reusable PASS of this suite could fail (O-015)'
  for f in spec.md plan.md tasks.md; do
    base="$(semantic_digest "$spec_rel/$f" "$SANDBOX/env-base/$f")"
    [[ -n "$base" && "$base" == "$(semantic_digest "$spec_rel/$f" "$tree/$spec_rel/$f")" ]] \
      || t_fail "AC-020: the identity saw the dropped-line claim in $f, so this fixture no longer isolates O-015"
  done
  printf '\n%s.\n' "$claim" >> "$tree/$spec_rel/tasks.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  assert_contains "$reported" "$spec_rel/tasks.md ::" 'AC-018: a claim on a spec body line escaped the scan'
  base="$(semantic_digest "$spec_rel/tasks.md" "$SANDBOX/env-base/tasks.md")"
  [[ -n "$base" && "$base" != "$(semantic_digest "$spec_rel/tasks.md" "$tree/$spec_rel/tasks.md")" ]] \
    || t_fail 'AC-020: a claim on a spec body line was invisible to the identity'

  # Names git quotes when it is not asked for NUL framing -- non-ASCII under
  # core.quotePath, a double quote, a control character -- are read like any
  # other name, because the enumeration is the identity's own.
  for quoted in "caf$(printf '\303\251').md" 'say"hi".md' "tab$(printf '\t')name.md"; do
    printf 'The snapshot %s %s.\n' "$v_inc2" "$n_path" > "$tree/$quoted"
  done
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  for quoted in "caf$(printf '\303\251').md" 'say"hi".md' "tab$(printf '\t')name.md"; do
    assert_contains "$reported" "$quoted ::" "AC-018: a claim in a file whose name git quotes escaped the scan: $quoted"
  done

  # A tree the enumeration cannot read fails by name. Before O-015 a git
  # failure printed nothing, and nothing is what a clean tree prints.
  mkdir -p "$SANDBOX/env-not-a-repo"
  printf 'The snapshot %s %s.\n' "$v_inc2" "$n_path" > "$SANDBOX/env-not-a-repo/claim.md"
  run_rc 1 superseded_environment_scan "$SANDBOX/env-not-a-repo"
  assert_contains "$OUT" 'superseded_environment_scan: cannot enumerate' \
    'AC-018: a tree outside any repository was read as clean'
  # A failing git fails the scan by name. (A GIT_DIR exported at a missing
  # directory no longer makes git fail here: the kernel names a repository by
  # its path alone, exactly as the identity does -- second review, F4.)
  mkdir -p "$SANDBOX/failing-git"
  printf '#!/bin/sh\necho "git: simulated failure" >&2\nexit 128\n' > "$SANDBOX/failing-git/git"
  chmod +x "$SANDBOX/failing-git/git"
  PATH="$SANDBOX/failing-git:$PATH" run_rc 1 superseded_environment_scan "$tree"
  assert_contains "$OUT" 'superseded_environment_scan: cannot enumerate' \
    'AC-018: a failing git was read as an empty, clean tree'
  # Parity: with a hook's GIT_DIR exported, the scan reads the tree the
  # identity hashes, and still reports the claim on the spec body line.
  export GIT_DIR="$SANDBOX/no-such-git-dir"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: an exported GIT_DIR stopped the scan, although the identity ignores it'
  unset GIT_DIR
  assert_contains "$reported" "$spec_rel/tasks.md ::" 'AC-018: an exported GIT_DIR hid a claim the identity hashes'
  # A subdirectory is not the manifest's root, so git succeeding there is not
  # enough: its listing would silently narrow the scope to one directory.
  run_rc 1 superseded_environment_scan "$tree/$spec_rel"
  assert_contains "$OUT" 'superseded_environment_scan: cannot enumerate' \
    'AC-018: a repository subdirectory was scanned as if it were the whole source'

  # Round-10 review (B1): letter case folds exactly where the identity folds
  # it. On a folding filesystem NOTES/Opponent.md IS the spec's generated
  # notes/opponent.md, which the identity excludes; elsewhere it is an
  # ordinary file and an input.
  mkdir -p "$tree/$spec_rel/NOTES"
  printf 'The snapshot %s %s.\n' "$v_inc2" "$n_path" > "$tree/$spec_rel/NOTES/Opponent.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: the scan could not read its fixture tree'
  if bash -c '. "$1"; vf_case_folds "$2"' _ "$SCRIPTS/verification-lib.sh" "$tree"; then
    assert_not_contains "$reported" 'NOTES/Opponent.md' \
      "AC-020: a case-variant spelling of a spec's generated record was scanned on a folding filesystem"
  else
    assert_contains "$reported" 'NOTES/Opponent.md ::' \
      'AC-018: a distinct case-variant file escaped the scan on a case-sensitive filesystem'
  fi
  rm -rf "$tree/$spec_rel/NOTES"

  # Round-10 review (B4, B5): every name the identity hashes is read, and a
  # link is read as the identity reads it -- its target as it is, whatever the
  # link is named. A name beginning with "-", one holding a newline and one
  # holding a backslash are reported verbatim; a healthy "-" file is no error.
  local nl; nl="$(printf '\nx')"; nl="${nl%x}"
  printf 'Nothing superseded here.\n' > "$tree/-plain.md"
  for quoted in '-notes.md' "new${nl}line.md" 'back\slash.md'; do
    printf 'The snapshot %s %s.\n' "$v_inc2" "$n_path" > "$tree/$quoted"
  done
  mkdir -p "$SANDBOX/env-outside" "$tree/.specify/specs/005-z"
  printf -- '- [x] **T001** — Task\n  - *Evidence:* %s\n' "$claim" > "$SANDBOX/env-outside/tasks.md"
  ln -s "$SANDBOX/env-outside/tasks.md" "$tree/.specify/specs/005-z/tasks.md"
  reported="$(superseded_environment_scan "$tree")" || t_fail 'AC-018: a healthy tree with unusual names failed the scan'
  for quoted in '-notes.md' "new${nl}line.md" 'back\slash.md'; do
    assert_contains "$reported" "$quoted ::" "AC-018: a claim in a file named $quoted escaped the scan"
  done
  assert_contains "$reported" '.specify/specs/005-z/tasks.md ::' \
    "AC-018: a claim the identity hashes through a link's target escaped the scan"

  # A listed file that cannot be read fails by name (skipped where the test
  # runs with privileges that read a mode-000 file anyway).
  printf 'The snapshot %s %s.\n' "$v_inc2" "$n_path" > "$tree/locked.md"
  chmod 000 "$tree/locked.md"
  if [[ ! -r "$tree/locked.md" ]]; then
    run_rc 1 superseded_environment_scan "$tree"
    assert_contains "$OUT" 'superseded_environment_scan: cannot read locked.md' \
      'AC-018: an unreadable listed file was skipped instead of failing the scan'
  fi
  chmod 600 "$tree/locked.md"; rm -f "$tree/locked.md"
}

semantic_digest() { # <repo-relative path> <file> -> digest of the bytes vf_snapshot hashes for it
  bash -c '. "$1/lib.sh"; . "$1/verification-lib.sh"; vf_semantic_file "$2" "$3" "$4" && vf_hash "$4"' \
    _ "$SCRIPTS" "$1" "$2" "$SANDBOX/semantic-digest"
}

test_instruction_contracts() {
  local contract spec plan plan_skill tasks_skill
  contract="$(cat "$KIT_DIR/templates/verification-contract.md")"
  spec="$(cat "$KIT_DIR/templates/spec-template.md")"
  plan="$(cat "$KIT_DIR/templates/plan-template.md")"
  plan_skill="$(cat "$KIT_DIR/skills/sdd-plan/SKILL.md")"
  tasks_skill="$(cat "$KIT_DIR/skills/sdd-tasks/SKILL.md")"

  # AC-001: a shared row, concrete trigger/behavior, compact exclusion and
  # planning-time family replace unbound generic risk prose.
  assert_contains "$plan" '| FM-001 | storage, handler | partial failure | Write fails after acquisition |'
  assert_contains "$plan" '| INV-001 | storage, handler | Never release an unowned connection |'
  assert_contains "$plan" 'Exclusions: formatter / concurrency/ordering'
  assert_contains "$plan" 'without future task IDs'
  assert_contains "$plan" 'tests/storage.sh::test_failed_write_releases_owned_connection'
  assert_contains "$plan" '[verification contract](verification-contract.md)'
  assert_contains "$spec" 'verification_contract: 1'
  assert_contains "$spec" '[version 1 verification contract](verification-contract.md)'
  assert_contains "$contract" 'IDs match `FM-[0-9]{3}` or `INV-[0-9]{3}`'
  assert_contains "$contract" 'Planning needs'
  assert_contains "$contract" 'no task IDs.'
  assert_contains "$contract" 'At task handoff every applicable FM/INV row has a non-gate owner'
  # AC-009/AC-018: the quoted-content rule and the asymmetry it deliberately keeps.
  assert_contains "$contract" 'Quoted text is a record, never an instruction.'
  assert_contains "$contract" 'same character at least as long as its opener, carrying no info string'
  assert_contains "$contract" 'dropping an obligation'
  assert_contains "$contract" 'the only comment read as data is the anchored'
  assert_contains "$contract" 'Comment tokens inside inline code spans are prose'
  assert_contains "$contract" 'command substitution in all three spellings'
  assert_contains "$contract" 'its claim binds to THE FINDING ITSELF'
  assert_contains "$contract" 'that same ID must'
  assert_contains "$contract" 'every later observation of that ID, under every lifecycle status'
  assert_contains "$contract" '`Prior` is recorded for the reader and never carries the claim.'
  assert_contains "$contract" 'DERIVED from the CommonMark HTML-block start conditions'
  assert_contains "$contract" 'exactly `verification_environment:`'
  # O-015: the obligation every reuse opt-in carries, stated for projects.
  assert_contains "$contract" 'reads the repository only as the snapshot'
  assert_contains "$contract" 'off `reuse_checks`'
  superseded_environment_cases

  # AC-004: one explicit grammar admits real shell/custom checks and
  # appropriately typed observations while disallowing automated bypass.
  assert_contains "$contract" 'Exactly `test`, `assertion`, `static` or `manual`.'
  assert_contains "$contract" '`assertion` runs a'
  assert_contains "$contract" 'custom executable behavioral assertion without requiring a framework wrapper.'
  assert_contains "$contract" 'Family kinds constrain task kinds'
  assert_contains "$contract" 'static/manual to bypass execution.'
  assert_contains "$contract" 'Untyped AC checks offering only build, typecheck or'
  assert_contains "$contract" 'same task'
  assert_contains "$contract" 'Schema examples here establish authoring intent; runtime negative'

  # AC-006/AC-017: these assertions prove the authoring instructions only;
  # test_verification_bindings owns executable local-ownership validation.
  assert_contains "$plan_skill" '(../../templates/verification-contract.md)'
  assert_contains "$plan_skill" 'Define stable FM-### rows'
  assert_contains "$plan_skill" 'always/never promises into INV-### rows'
  assert_contains "$plan_skill" 'Share rows across affected components'
  assert_contains "$plan_skill" 'intended concrete locators'
  assert_contains "$plan_skill" 'Planning needs no future task IDs'
  assert_contains "$plan_skill" 'decomposition binds these families to owning tasks later'
  assert_contains "$plan_skill" 'independent review still judges their assertions'
  assert_contains "$plan_skill" '--phase plan'
  assert_contains "$tasks_skill" '(../../templates/verification-contract.md)'
  assert_contains "$tasks_skill" 'every applicable planned FM/INV row to a non-gate task through Refs'
  assert_contains "$tasks_skill" 'concrete locators from the plan'
  assert_contains "$tasks_skill" 'adds or extends its covering tests in the same task'
  assert_contains "$tasks_skill" 'and commit'
  assert_contains "$tasks_skill" 'extending an existing test family is valid'
  assert_contains "$tasks_skill" 'never an excuse to'
  assert_contains "$tasks_skill" 'defer local tests'
  assert_contains "$tasks_skill" 'Tests (integration spanning tasks or stacks only)'
  assert_contains "$tasks_skill" 'behavioral follow-ups under Reality Check or Ship still need these bindings'
  assert_contains "$tasks_skill" 'Bindings do not establish semantic coverage'
  assert_contains "$tasks_skill" '--phase tasks'
  assert_contains "$tasks_skill" 'warnings at a new task handoff'
  assert_not_contains "$tasks_skill" 'Tests (happy + error per AC)'
  public_workflow_cases
  metrics_instruction_cases
  invoker_instruction_cases
  # Both phases refer to the same schema rather than repeating its tables.
  assert_not_contains "$plan_skill" '| ID | Components | Category | Trigger |'
  assert_not_contains "$tasks_skill" '| ID | Components | Category | Trigger |'
}

# AC-002: each shipped default gives concrete stack scenarios, exclusions and
# distinct optional checkpoint / mandatory full-suite guidance.
defaults_contract() {
  local name text
  for name in "$@"; do
    text="$(cat "$KIT_DIR/templates/stack-overlays/$name.md")"
    assert_contains "$text" '## Failure-mode and checkpoint defaults'
    assert_contains "$text" 'explicit exclusions'
    assert_contains "$text" 'Required `gate_checks` separately cover the full suite'
    assert_contains "$text" 'Optional `checkpoints` use exact authored task-stage names'
    assert_eq 3 "$(printf '%s\n' "$text" | sed -n '/## Failure-mode and checkpoint defaults/,$p' | awk '/^- / {n++} END {print n+0}')" "$name scenario prompts"
  done
}

test_defaults_t006() { defaults_contract rust rust-aws-lambda nextjs aws-cdk-lambda-ts; }

test_defaults_t007() { defaults_contract javascript react bun-monorepo loopback4; }

test_defaults_t008() { defaults_contract expo-rn firebase-rtk-codegen python aws; }

test_defaults_t009() { defaults_contract monorepo troposphere; }

# The overlays and personas are the enumerated ones (kit_files), never a glob
# that would also judge an ignored local file: this suite is reuse-checked
# (O-015 review).
test_all_overlay_defaults() {
  local file list="$SANDBOX/overlays"
  kit_files templates/stack-overlays '*.md' > "$list" || t_fail 'AC-002: cannot enumerate the stack overlays'
  [[ -s "$list" ]] || t_fail 'AC-002: no stack overlay was enumerated'
  while IFS= read -r -d '' file; do
    defaults_contract "$(basename "$file" .md)"
  done < "$list"
}

# AC-014: mode instructions retain planning judgment and bound implementation
# context without removing independent gate access or higher-priority rules.
brief_contract() {
  local file text
  for file in "$@"; do
    text="$(cat "$file")"
    assert_contains "$text" '**Planning consultation:**'
    assert_contains "$text" '**Implementation:**'
    assert_contains "$text" 'Source revision:'
    assert_contains "$text" 'required FM/INV'
    assert_contains "$text" 'missing slice; only a new decision changes the plan'
    assert_contains "$text" 'Higher-priority instructions and project-local rules prevail'
    assert_contains "$text" '--from-task --no-tick --summary'
    assert_contains "$text" 'workers never tick tasks'
    assert_not_contains "$text" "Read the task's spec/plan refs, then"
  done
}

test_briefs_t010() {
  brief_contract "$KIT_DIR/agents/rust-expert.md" "$KIT_DIR/agents/rust-aws-lambda-expert.md" "$KIT_DIR/agents/aws-cdk-lambda-ts-expert.md" "$KIT_DIR/agents/nextjs-expert.md"
}

test_briefs_t011() {
  brief_contract "$KIT_DIR/agents/javascript-expert.md" "$KIT_DIR/agents/react-expert.md" "$KIT_DIR/agents/bun-monorepo-expert.md" "$KIT_DIR/agents/loopback4-expert.md"
}

test_briefs_t012() {
  brief_contract "$KIT_DIR/agents/aws-expert.md" "$KIT_DIR/agents/python-expert.md" "$KIT_DIR/agents/expo-rn-expert.md" "$KIT_DIR/agents/firebase-rtk-codegen-expert.md"
}

test_briefs_t013() {
  brief_contract "$KIT_DIR/agents/test-engineer.md"
}

test_all_brief_modes() {
  local file list="$SANDBOX/personas" personas=()
  kit_files agents '*-expert.md' > "$list" || t_fail 'AC-014: cannot enumerate the expert personas'
  while IFS= read -r -d '' file; do personas+=("$KIT_DIR/$file"); done < "$list"
  (( ${#personas[@]} > 0 )) || t_fail 'AC-014: no expert persona was enumerated'
  brief_contract ${personas[@]+"${personas[@]}"} "$KIT_DIR/agents/test-engineer.md"
}

# O-015 sibling: an ignored local overlay or persona in a developer's kit is
# not part of the kit, and must not decide the two checks above.
test_ignored_local_overlays_and_personas_do_not_decide_the_checks() {
  local host="$SANDBOX/host-kit"
  make_host_kit "$host" || t_fail 'AC-002: cannot build the host kit'
  printf 'templates/stack-overlays/zz-local.md\nagents/zz-local-expert.md\n' >> "$host/.git/info/exclude"
  printf '# local notes, no defaults section\n' > "$host/templates/stack-overlays/zz-local.md"
  printf '# local persona, no brief modes\n' > "$host/agents/zz-local-expert.md"
  on_host_kit "$host" test_all_overlay_defaults
  on_host_kit "$host" test_all_brief_modes
}

# AC-010/AC-017: shipped 002's recorded history, read as the input identity
# hashes it: an enumerated copy of its notes/ (copy_kit's directory selector),
# never the directories in place, where an empty FLOOR-* or CAP-* left behind
# is invisible to the identity yet walked by the tally (O-015 review).
shipped_002_tally_case() {
  local rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs copy="$SANDBOX/tally-002"
  rm -rf "$copy"
  copy_kit "$KIT_DIR" "$copy" "$rel/notes" || t_fail 'AC-010: cannot copy shipped 002 records as the identity hashes them'
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$copy/$rel"
  assert_contains "$OUT" 'opponent rounds=5'
  assert_contains "$OUT" 'reality-check rounds=1'
  assert_contains "$OUT" 'blocking=6 minor=0'
  assert_contains "$OUT" 'unclassified=6'
  assert_contains "$OUT" 'finding-observations=6 distinct-finding-ids=6 reopened=0'
  # AC-017: 002 shipped before sealed execution records existed. Every cost
  # field reports zero and usage stays unknown; no saving is inferred from its
  # five rounds.
  assert_contains "$OUT" 'execution-observations=0 check-executions=0 cache-hits=0 captures=0 full-log-bytes=0 returned-summary-bytes=0 usage=unknown baseline-usage=unknown'
}

# O-015 sibling: an empty directory under shipped 002's records -- a FLOOR-*
# or CAP-* left by an interrupted run -- holds no file the identity hashes, and
# must not decide the 002 tally check.
test_empty_record_directories_do_not_decide_the_002_tally() {
  local host="$SANDBOX/host-002" rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs
  mkdir -p "$host"; fixture_git -C "$host" init -q || fixture_build_failed tally-host
  copy_kit "$KIT_DIR" "$host" "$rel/notes" || t_fail 'AC-010: cannot build the host tree'
  mkdir -p "$host/$rel/notes/verification/floors/FLOOR-zz" "$host/$rel/notes/captures/CAP-9-zz"
  KIT_DIR="$host" shipped_002_tally_case
}

report_fixture() {
  local n="$1" status="$2" verdict="$3" blocks="$4"
  cat <<EOF
## Round $n
**Round:** $n
**Timestamp:** 2026-09-06T12:00:0${n}Z
**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
**Floor:** FLOOR-fixture
**Verdict:** $verdict
**Blocking:** $blocks · **Minor:** 0
### What I attacked
Shared lock lifecycle and both release call sites; unexamined: the CLI wrappers.
### Finding O-001
- **Class:** lock-lifecycle
- **Status:** $status
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** failed acquisition followed by cleanup
- **Where:** scripts/run.sh:4, scripts/cancel.sh:8
- **Reproduced:** concrete trigger at listed sites
- **Root cause:** implementation-error
- **Blocks:** AC-022
- **Wrong behavior:** cleanup releases a connection the run never acquired
- **Class-wide fix:** guard release on recorded ownership at both sites
### Held up / follow-up tasks
- T001o1 — sweep the shared release path and cover both sites.
<!-- gate-round-end: opponent:$n -->
EOF
}

# A canonical round carrying exactly one finding. Pass a verdict override to
# build a round whose verdict is deliberately chosen. By DEFAULT a round whose
# only finding is `resolved` is NON-CLEARING (opponent BLOCKED), because a
# clearing verdict resting on a resolved observation of a finding this gate
# recorded open is refused by design -- O-004 round 7. These cases exercise the
# prior/class binding, not clearance; the clearance rule has its own negatives.
finding_round_fixture() { # gate n id class status prior [verdict-override]
  local gate="$1" n="$2" id="$3" class="$4" status="$5" prior="$6" override="${7:-}" blockers verdict
  if [[ "$status" == resolved ]]; then blockers=0; else blockers=1; fi
  if [[ -n "$override" ]]; then verdict="$override"
  elif [[ "$gate" == opponent ]]; then
    if (( blockers )); then verdict=CHALLENGED; else verdict=BLOCKED; fi
  else
    verdict='NEEDS WORK'
  fi
  printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n' "$n" "$n" "$n"
  printf '**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
  printf '**Floor:** FLOOR-fixture\n**Verdict:** %s\n' "$verdict"
  if [[ "$gate" == opponent ]]; then
    printf '**Blocking:** %s · **Minor:** 0\n### What I attacked\nPrior-binding behavior and its class boundary.\n' "$blockers"
  else
    printf '### Summary\nPrior-binding fixture.\n'
  fi
  printf '### Finding %s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** %s\n' "$id" "$class" "$status" "$prior"
  printf -- '- **Severity:** data-loss\n- **Scenario:** rows vanish after a copied prior ID\n'
  printf -- '- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
  printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n'
  printf -- '- **Wrong behavior:** a new finding is hidden as resolved\n- **Class-wide fix:** bind the prior ID to its recorded class\n'
  if [[ "$gate" == opponent ]]; then
    printf '### Held up / follow-up tasks\nFixture disposition recorded.\n'
  else
    printf '### Constitution check\nFixture only.\n### Re-run conditions\nFixture only.\n### AC matrix\nFixture row.\n'
  fi
  printf '<!-- gate-round-end: %s:%s -->\n' "$gate" "$n"
}

# A canonical opponent round with an arbitrary finding list, each given as
# "id:class:status:severity". Totals and verdict are DERIVED from the findings
# so a fixture can never silently disagree with itself; pass a verdict override
# only to build a report that is deliberately inconsistent.
tier_round_fixture() { # n verdict-override finding...
  local n="$1" verdict_override="$2"; shift 2
  local f id class status sev blockers=0 minors=0 verdict body=''
  for f in "$@"; do
    IFS=: read -r id class status sev <<< "$f"
    if [[ "$status" != resolved ]]; then
      case "$sev" in minor|degraded) minors=$((minors+1));; *) blockers=$((blockers+1));; esac
    fi
    body+="$(printf '### Finding %s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** bind the tier the way Class is bound' "$id" "$class" "$status" "$sev")"$'\n'
  done
  if [[ -n "$verdict_override" ]]; then verdict="$verdict_override"
  elif (( blockers )); then verdict=CHALLENGED; else verdict=CLEARED; fi
  printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n' "$n" "$n" "$n"
  printf '**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
  printf '**Floor:** FLOOR-fixture\n**Verdict:** %s\n' "$verdict"
  printf '**Blocking:** %s · **Minor:** %s\n' "$blockers" "$minors"
  printf '### What I attacked\nSeverity tier binding across rounds of one gate.\n'
  printf '%s' "$body"
  printf '### Held up / follow-up tasks\nFixture disposition recorded.\n'
  printf '<!-- gate-round-end: opponent:%s -->\n' "$n"
}

report_severity_tier_cases() {
  local spec report
  spec="$SANDBOX/tier-opponent"; mkdir -p "$spec/notes"; report="$spec/notes/opponent.md"

  # O-004 round 6. Round 5 bound Class, which the tally never reads. Severity is
  # the token the count DOES read, and it stayed free to drop a tier for an ID
  # the gate already knows -- so a still-open data-loss defect is tallied as a
  # minor and CLEARED passes on blockers==0. Round 5's outcome, reached through
  # the sibling field in the same statement.
  { tier_round_fixture 1 '' G-042:tier-binding:new:data-loss; echo
    tier_round_fixture 2 '' G-042:tier-binding:reopened:degraded; } > "$report"
  run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-attack.nul" "$spec"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-012: a CLEARED round rested on a lowered severity tier'

  # The control that makes the rule right rather than merely strict, and the
  # reason the tier is NOT bound outright: round 6 of this very gate records
  # O-002 at degraded after five rounds at wrong-result -- an honest
  # re-characterisation of the next member of a class. A non-clearing round may
  # do that. Only a CLEARING verdict may not rest on it. Binding the tier
  # outright would have rejected the report that reported the defect.
  { tier_round_fixture 1 '' G-042:tier-binding:new:data-loss; echo
    tier_round_fixture 2 '' G-042:tier-binding:reopened:degraded G-099:other-class:new:wrong-result; } > "$report"
  run_rc 0 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-challenged.nul" "$spec"

  # O-004 round 7. This was a shipped POSITIVE asserting the attack at rc=0:
  # round 2 re-recording G-042 as `resolved` at the same data-loss tier under
  # CLEARED, byte-for-byte the shape of the attack and distinguished from it
  # only by a comment calling it "a genuine fix". Nothing in the report tells
  # the two apart, which is the point -- `Status: resolved` asserts a repair no
  # data available to vf_reports can corroborate, and at :1013 it suppresses
  # the count the clearance check at :1080 reads. Negative now.
  { tier_round_fixture 1 '' G-042:tier-binding:new:data-loss; echo
    tier_round_fixture 2 '' G-042:tier-binding:resolved:data-loss; } > "$report"
  run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-resolved.nul" "$spec"
  assert_contains "$OUT" 'clearing verdict rests on resolved findings this gate recorded open: G-042' \
    'AC-012: a resolved claim for a known-open finding still cleared the gate'

  # The control that keeps the rule from refusing resolutions in general: the
  # same resolution recorded in a NON-clearing round is legitimate, which is
  # the shape every resolution in this spec real history actually has.
  { tier_round_fixture 1 '' G-042:tier-binding:new:data-loss; echo
    tier_round_fixture 2 BLOCKED G-042:tier-binding:resolved:data-loss; } > "$report"
  run_rc 0 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-resolved-open.nul" "$spec"

  # Raising a tier is never the attack.
  { tier_round_fixture 1 '' G-042:tier-binding:new:degraded; echo
    tier_round_fixture 2 '' G-042:tier-binding:reopened:wrong-result; } > "$report"
  run_rc 0 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-raised.nul" "$spec"

  # The escalation above is the setup half of O-004. History must retain its
  # strictest tier even when the first observation was only degraded.
  tier_round_fixture 3 '' G-042:tier-binding:reopened:degraded >> "$report"
  run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/tier-walkback.nul" "$spec"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-012: escalation followed by a downgrade cleared'

  local low high status
  for low in minor degraded; do
    for high in data-loss wrong-result regression crash; do
      for status in new open reopened; do
        { tier_round_fixture 1 '' "G-042:tier-binding:new:$low"
          tier_round_fixture 2 '' "G-042:tier-binding:open:$high"
          tier_round_fixture 3 '' "G-042:tier-binding:$status:$low"; } > "$report"
        run_rc 3 bash -c '. "$1"; vf_reports "$2" opponent "$3" "$4"' _ \
          "$SCRIPTS/verification-lib.sh" "$report" "$SANDBOX/tier-order.nul" "$spec"
        assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
          "AC-012: $low/$high/$status tier fold"
      done
      # Re-characterisation in a non-clearing round is legal and observable.
      # Two successive low observations distinguish sticky-max from last-wins.
      { tier_round_fixture 1 '' "G-042:tier-binding:new:$low"
        tier_round_fixture 2 '' "G-042:tier-binding:open:$high"
        tier_round_fixture 3 BLOCKED "G-042:tier-binding:open:$low"
        tier_round_fixture 4 BLOCKED "G-042:tier-binding:reopened:$low"; } > "$report"
      run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
      assert_contains "$OUT" 'severity-downgrades=2' 'AC-017: sticky tier lost repeated downgrades'
    done
  done
  # Neither a minor-only history nor changes within the blocking tier are
  # downgrades. This prevents a strictness mutation from manufacturing counts.
  { tier_round_fixture 1 '' G-042:tier-binding:new:minor
    tier_round_fixture 2 '' G-042:tier-binding:open:degraded
    tier_round_fixture 3 '' G-042:tier-binding:open:crash
    tier_round_fixture 4 '' G-042:tier-binding:open:regression
    tier_round_fixture 5 BLOCKED G-042:tier-binding:resolved:minor; } > "$report"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'severity-downgrades=0' 'AC-017: non-downgrades were counted'

  # The manifest fold and the round fold share the strictest-tier rule. A
  # minor round must not overwrite a blocking manifest observation either.
  mkdir -p "$spec/notes/verification/reports"
  local manifest_sev
  for manifest_sev in degraded wrong-result; do
    printf '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** %s\n' "$manifest_sev" \
      > "$spec/notes/verification/reports/opponent-findings-$manifest_sev.md"
  done
  { tier_round_fixture 1 BLOCKED G-042:tier-binding:new:minor
    tier_round_fixture 2 '' G-042:tier-binding:open:degraded; } > "$report"
  run_rc 3 bash -c '. "$1"; vf_reports "$2" opponent "$3" "$4"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" "$SANDBOX/tier-manifest.nul" "$spec"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-012: round observation weakened the strictest manifest tier'

  # O-014: the metric is the guard's own computation, so the manifest seed the
  # guard judged against is in the count too. The same observation a CLEARED
  # round may not rest on is legal under CHALLENGED, and still counted.
  tier_round_fixture 1 '' G-042:tier-binding:reopened:minor G-043:tier-binding:new:wrong-result > "$report"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'severity-downgrades=1' \
    'AC-017: the tally missed a lowered tier the guard counted from a prior-review manifest'

  # Per gate by construction. The same ID recorded open at a blocking tier by
  # one gate -- in a manifest and in a round -- is no history for the other
  # gate, so neither an ID-only fold nor a manifest read across gates counts it.
  spec="$SANDBOX/tier-cross"; mkdir -p "$spec/notes/verification/reports"
  printf '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** wrong-result\n' \
    > "$spec/notes/verification/reports/opponent-findings-cross.md"
  finding_round_fixture opponent 1 G-042 tier-binding open none > "$spec/notes/opponent.md"
  finding_round_fixture reality-check 1 G-042 tier-binding open none \
    | sed 's/^- \*\*Severity:\*\* data-loss$/- **Severity:** degraded/' > "$spec/notes/reality-check.md"
  assert_eq 1 "$(grep -c -x -F -- '- **Severity:** degraded' "$spec/notes/reality-check.md")" 'fixture: reality-check tier'
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'severity-downgrades=0' \
    'AC-017: one gate lowered the tier of the same finding ID recorded by the other gate'
}

report_duplicate_totals_cases() {
  local spec report
  spec="$SANDBOX/totals-opponent"; mkdir -p "$spec/notes"; report="$spec/notes/opponent.md"
  tier_round_fixture 1 '' G-042:tier-binding:new:data-loss > "$report"
  run_rc 0 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report" opponent "$SANDBOX/totals-single.nul" "$spec"

  # O-011 round 6: every per-round singleton must refuse a second occurrence
  # rather than let the last write win. The identity fields carry that guard;
  # the totals line did not, so a second totals line further down the round
  # silently replaced the one the reader sees above the findings.
  awk '/^<!-- gate-round-end:/ {print "**Blocking:** 0 · **Minor:** 0"} {print}' "$report" > "$report.dup"
  run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
    "$SCRIPTS/verification-lib.sh" "$report.dup" opponent "$SANDBOX/totals-dup.nul" "$spec"
  assert_contains "$OUT" 'duplicate totals field' \
    'AC-012: a second totals line in one round silently replaced the first'
}

report_prior_binding_cases() {
  local spec gate report status clearing
  for gate in opponent reality-check; do
    spec="$SANDBOX/prior-$gate"
    mkdir -p "$spec/notes"
    report="$spec/notes/$gate.md"
    finding_round_fixture "$gate" 1 G-001 unrelated-class new none > "$report"
    finding_round_fixture "$gate" 2 G-042 silent-data-loss resolved G-001 >> "$report"
    run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
      "$SCRIPTS/verification-lib.sh" "$report" "$gate" "$SANDBOX/$gate-unrelated.nul" "$spec"
    assert_contains "$OUT" 'resolved finding G-042 has no earlier round of this gate and no declared prior-review record' \
      "AC-012: $gate accepted a real unrelated Prior"

    # O-004 round 4: this was a THIRD shipped positive certifying the attack --
    # a brand-new G-042 neutralized by a real prior ID of the same Class. Class
    # is a field this report also writes, so it binds the claim to nothing the
    # author does not control. Negative now, on both gates.
    finding_round_fixture "$gate" 1 G-001 silent-data-loss new none > "$report"
    finding_round_fixture "$gate" 2 G-042 silent-data-loss resolved G-001 >> "$report"
    run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
      "$SCRIPTS/verification-lib.sh" "$report" "$gate" "$SANDBOX/$gate-same-class.nul" "$spec"
    assert_contains "$OUT" 'resolved finding G-042 has no earlier round of this gate and no declared prior-review record' \
      "AC-012: $gate accepted a same-class Prior for a brand-new finding"

    # The same-ID lifecycle stays legitimate: round 2 may record the repair of
    # a finding round 1 opened, as long as that round does not also clear.
    finding_round_fixture "$gate" 1 G-042 silent-data-loss new none > "$report"
    finding_round_fixture "$gate" 2 G-042 silent-data-loss resolved none >> "$report"
    run_rc 0 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
      "$SCRIPTS/verification-lib.sh" "$report" "$gate" "$SANDBOX/$gate-same-id.nul" "$spec"

    # O-004 round 7: the round that ANNOUNCES a repair may not also clear the
    # gate. `Status: resolved` is the one finding token no data available to
    # this validator can corroborate, and at verification-lib.sh:1013 it
    # suppresses the very count the clearance check reads -- so the suppression
    # may not be worth a clearing verdict. Both gates, because clearing is
    # gate-relative (CLEARED / READY) and nothing in the derivation is not.
    case "$gate" in opponent) clearing=CLEARED;; *) clearing=READY;; esac
    finding_round_fixture "$gate" 1 G-042 silent-data-loss new none > "$report"
    finding_round_fixture "$gate" 2 G-042 silent-data-loss resolved none "$clearing" >> "$report"
    run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
      "$SCRIPTS/verification-lib.sh" "$report" "$gate" "$SANDBOX/$gate-resolved-clears.nul" "$spec"
    assert_contains "$OUT" 'clearing verdict rests on resolved findings this gate recorded open: G-042' \
      "AC-012: $gate cleared on an uncorroborable resolution of a finding it recorded open"

    # O-004 round 5: an ID is the stable subject only while its first Class is
    # stable too. Class drift is refused for every lifecycle status, on both
    # report schemas; resolved is not a special escape hatch.
    for status in new open resolved reopened; do
      finding_round_fixture "$gate" 1 G-042 return-envelope-parsing new none > "$report"
      finding_round_fixture "$gate" 2 G-042 silent-data-loss "$status" none >> "$report"
      run_rc 3 bash -c '. "$1"; vf_reports "$2" "$3" "$4" "$5"' _ \
        "$SCRIPTS/verification-lib.sh" "$report" "$gate" "$SANDBOX/$gate-class-drift-$status.nul" "$spec"
      assert_contains "$OUT" 'finding G-042 changes Class from return-envelope-parsing to silent-data-loss' \
        "AC-012: $gate accepted $status Class drift for a reused finding ID"
    done
  done

  spec="$SANDBOX/prior-tally"
  mkdir -p "$spec/notes"
  finding_round_fixture opponent 1 G-042 return-envelope-parsing new none > "$spec/notes/opponent.md"
  finding_round_fixture opponent 2 G-042 silent-data-loss resolved none >> "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'finding G-042 changes Class from return-envelope-parsing to silent-data-loss' \
    'AC-012: tally accepted Class drift for a reused finding ID'
}

raw_html_close_cases() {
  local opener closer flags
  . "$SCRIPTS/verification-lib.sh"
  # O-002 round 5: CommonMark condition-1 blocks end on their corresponding
  # close tag. Exercise every mismatched pair against the one shared tracker.
  for opener in script style textarea pre; do
    for closer in script style textarea pre; do
      [[ "$closer" != "$opener" ]] || continue
      flags="$(printf '<%s>\nhidden-one\n</%s>\nhidden-two\n</%s>\nvisible\n' \
        "$opener" "$closer" "$opener" | awk "$_VF_AWK_FENCE"'{printf "%s ", vf_quoted($0)}')"
      assert_eq '1 1 1 1 1 0 ' "$flags" "AC-009: </$closer> closed <$opener> raw HTML"
    done
  done
}

comment_extent_cases() {
  local spec="$SANDBOX/comment-extent" valid
  mkdir -p "$spec/notes"
  valid="$SANDBOX/comment-valid.md"
  report_fixture 1 new CHALLENGED 1 > "$valid"

  # AC-012/FM-016: four spaces make the opener an indented code block. It is
  # visible content, so it cannot start comment state and swallow the blocking
  # finding that follows it.
  awk '/^### Finding O-001$/ {print "    <!--"} {print}' \
    "$valid" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'blocking=1 minor=0' 'AC-012: indented opener swallowed a blocking finding'

  # A genuine comment still suppresses the finding in full. This control keeps
  # the indentation guard from turning every opener into visible report data.
  sed -e 's/^\*\*Verdict:\*\* CHALLENGED$/**Verdict:** CLEARED/' \
      -e 's/^\*\*Blocking:\*\* 1 · \*\*Minor:\*\* 0$/**Blocking:** 0 · **Minor:** 0/' \
      "$valid" > "$SANDBOX/comment-zero.md"
  awk '/^### Finding O-001$/ {print "<!--"; quoted=1}
       quoted && /^### Held up \/ follow-up tasks$/ {print "-->"; quoted=0}
       {print}' "$SANDBOX/comment-zero.md" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'blocking=0 minor=0' 'AC-012: genuinely commented finding was counted'

  # A mismatched condition-1 closer is content. The hidden blocker remains
  # hidden until the corresponding close tag arrives.
  awk '/^### Finding O-001$/ {print "<script>"; print "</style>"; quoted=1}
       quoted && /^### Held up \/ follow-up tasks$/ {print "</script>"; quoted=0}
       {print}' "$SANDBOX/comment-zero.md" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'blocking=0 minor=0' 'AC-012: mismatched HTML close exposed a hidden report finding'

  # Inside an HTML comment, backticks are raw text. A closer printed between
  # them still closes the comment, allowing the following real finding through.
  awk '/^### Finding O-001$/ {print "<!--"; print "`-->`"} {print}' \
    "$valid" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'blocking=1 minor=0' 'AC-012: raw comment closer left later findings suppressed'

  # An authored unclosed comment is malformed report input and must name the
  # actual extent error instead of silently dropping the remainder.
  awk '/^### Finding O-001$/ {print "<!--"}
       /^<!--[ ]*gate-round-end:/ {next}
       {print}' \
    "$valid" > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'unclosed HTML comment' 'AC-012: unclosed comment had no END diagnostic'
}

test_reports_and_tally() {
  matrix_runtime_cases
  cost_metric_cases
  report_prior_binding_cases
  report_severity_tier_cases
  report_duplicate_totals_cases
  raw_html_close_cases
  comment_extent_cases
  # AC-010/AC-012/AC-017: legacy counts stay unclassified; a new/open/resolved/
  # reopened sequence counts only the reopened class as a recurrence.
  local spec="$SANDBOX/spec" round insert
  mkdir -p "$spec/notes"
  shipped_002_tally_case
  # O-004 round 7. Round 3 was `resolved CLEARED 0` here: a shipped POSITIVE
  # asserting rc=0 for a lifecycle whose round 3 resolves O-001 and clears at
  # zero blockers, and whose round 4 then reopens the very same finding -- a
  # false resolution clearing a round, blessed as the expected lifecycle, so no
  # regression in this class could ever be caught. Round 3 is non-clearing now;
  # the CLEARED spelling is asserted as a negative immediately below.
  report_fixture 1 new CHALLENGED 1 > "$spec/notes/opponent.md"
  report_fixture 2 open CHALLENGED 1 >> "$spec/notes/opponent.md"
  report_fixture 3 resolved BLOCKED 0 >> "$spec/notes/opponent.md"
  report_fixture 4 reopened CHALLENGED 1 >> "$spec/notes/opponent.md"
  cp "$spec/notes/opponent.md" "$SANDBOX/lifecycle-open"
  sed 's/^\*\*Verdict:\*\* BLOCKED$/**Verdict:** CLEARED/' "$SANDBOX/lifecycle-open" > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'clearing verdict rests on resolved findings this gate recorded open: O-001' \
    'AC-012: a resolved round cleared and the next round reopened the same finding'
  cp "$SANDBOX/lifecycle-open" "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4'
  assert_contains "$OUT" 'locations=8'
  assert_contains "$OUT" 'class=lock-lifecycle findings=4 recurrences=1'
  # AC-017: one finding observed across four rounds is one identity, and only
  # its reopening counts — raw sites and repeat observations stay separate.
  assert_contains "$OUT" 'finding-observations=4 distinct-finding-ids=1 reopened=1'
  cp "$spec/notes/opponent.md" "$SANDBOX/valid"
  insert="$SANDBOX/quoted-rounds"
  printf '\140\140\140markdown\n## Round 99\n**Round:** 99\n\140\140\140\n> **Round:** 88\n' > "$insert"
  awk -v insert="$insert" '
    /^<!--[ ]*gate-round-end: opponent:4 -->$/ {
      while ((getline line < insert) > 0) print line
      close(insert)
    }
    {print}
  ' "$SANDBOX/valid" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4'
  # AC-010/FM-016: the same nested-fence grammar guards report parsing. An
  # inner shorter fence or another fence character inside a quoted example
  # must not expose its `## Round` heading as a real consumed round.
  printf '\140\140\140\140markdown\n\140\140\140text\n## Round 97\n**Round:** 97\n\140\140\140\n~~~text\n## Round 96\n~~~\n\140\140\140\140\n' > "$insert"
  awk -v insert="$insert" '
    /^<!--[ ]*gate-round-end: opponent:4 -->$/ {
      while ((getline line < insert) > 0) print line
      close(insert)
    }
    {print}
  ' "$spec/notes/opponent.md" > "$SANDBOX/nested-quoted-rounds"
  cp "$SANDBOX/nested-quoted-rounds" "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4' 'AC-010: a nested-fence heading was counted as a round'
  # Control: a real round recorded after the closed example is still counted,
  # so strict closing does not silently drop later rounds.
  report_fixture 5 open CHALLENGED 1 >> "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=5' 'AC-010: a real round after a closed example was suppressed'
  cp "$SANDBOX/valid" "$spec/notes/opponent.md"
  # AC-010/FM-016: an HTML-commented round block is quoted history, not a
  # consumed round. Every line of it is suppressed, including the heading that
  # would otherwise open a round. The example stays inside round 4, before its
  # completion marker; separate preamble fixtures cover content after a marker.
  printf '<!--\n## Round 95\n**Round:** 95\n-->\n' > "$insert"
  awk -v insert="$insert" '
    /^<!--[ ]*gate-round-end: opponent:4 -->$/ {
      while ((getline line < insert) > 0) print line
      close(insert)
    }
    {print}
  ' "$SANDBOX/valid" > "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4' 'AC-010: a commented round heading was counted'
  # Control: a round whose prose quotes the comment tokens inside inline code
  # spans still parses. This kit's own round-2 report does exactly that, and a
  # scanner that counted those tokens would suppress the rest of the file.
  cp "$SANDBOX/valid" "$spec/notes/opponent.md"
  report_fixture 5 open CHALLENGED 1 > "$SANDBOX/round5"
  awk '/^### What I attacked$/ {
         print
         print "The `<!--` opener is named here, with no closer anywhere on this line."
         next
       } {print}' "$SANDBOX/round5" >> "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=5' 'AC-010: quoted comment tokens suppressed a real round'
  cp "$SANDBOX/valid" "$spec/notes/opponent.md"
  for round in '2026-02-30T12:00:01Z' '2026-09-06T25:00:01Z'; do
    sed "s/2026-09-06T12:00:01Z/$round/" "$SANDBOX/valid" > "$spec/notes/opponent.md"
    run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
    assert_contains "$OUT" 'invalid UTC'
  done
  sed '/gate-round-end: opponent:4/d' "$SANDBOX/valid" > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'incomplete canonical identity'
  report_fixture 1 new CLEARED 1 > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'verdict disagrees'
  report_schema_omission_cases
}

# AC-012: a canonical report is refused when it drops a required section or
# finding field, so a clearance cannot be canonized without the review record.
report_schema_omission_cases() {
  local spec omission expected valid gate cli reservation report before
  spec="$SANDBOX/schema"
  mkdir -p "$spec/notes"
  valid="$SANDBOX/schema-valid.md"
  report_fixture 1 new CHALLENGED 1 > "$valid"
  cp "$valid" "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=1'
  for omission in attacked followup wrong classfix; do
    case "$omission" in
      attacked)  expected='missing required report section: what i attacked'
                 sed '/^### What I attacked$/d' "$valid" > "$spec/notes/opponent.md";;
      followup)  expected='missing required report section: held up / follow-up tasks'
                 sed '/^### Held up \/ follow-up tasks$/d' "$valid" > "$spec/notes/opponent.md";;
      wrong)     expected='incomplete finding O-001'
                 sed '/^- \*\*Wrong behavior:\*\*/d' "$valid" > "$spec/notes/opponent.md";;
      classfix)  expected='incomplete finding O-001'
                 sed '/^- \*\*Class-wide fix:\*\*/d' "$valid" > "$spec/notes/opponent.md";;
    esac
    run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
    assert_contains "$OUT" "$expected" "AC-012: $omission omission was canonized"
  done
  # AC-012: a heading alone is not a record. Deleting each section body must
  # be refused just like deleting the heading.
  for omission in attacked-body followup-body; do
    case "$omission" in
      attacked-body) expected='empty required report section: what i attacked'
                     sed '/^Shared lock lifecycle and both release call sites/d' "$valid" > "$spec/notes/opponent.md";;
      followup-body) expected='empty required report section: held up / follow-up tasks'
                     sed '/^- T001o1 — sweep the shared release path/d' "$valid" > "$spec/notes/opponent.md";;
    esac
    run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
    assert_contains "$OUT" "$expected" "AC-012: $omission was canonized"
  done
  # AC-012/REQ-011: a brand-new blocking finding cannot be neutralized by
  # calling it resolved, which would keep its text and tally zero blockers.
  {
    printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n'
    printf '**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
    printf '**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 0\n'
    printf '### What I attacked\nEverything, allegedly.\n'
    printf '### Finding O-042\n- **Class:** silent-data-loss\n- **Status:** resolved\n- **Prior:** none\n'
    printf -- '- **Severity:** data-loss\n- **Scenario:** rows vanish on retry\n'
    printf -- '- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-022\n'
    printf -- '- **Wrong behavior:** committed rows disappear\n- **Class-wide fix:** guard the retry path\n'
    printf '### Held up / follow-up tasks\nNothing, allegedly.\n'
    printf '<!-- gate-round-end: opponent:1 -->\n'
  } > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record'
  # AC-012/REQ-011: a well-formed but invented Prior is the same attack one
  # character wider, and naming a REAL prior finding is the same attack one
  # token wider again. The claim is bound to the subject it asserts -- this
  # finding own ID -- so no value of Prior can carry it.
  sed 's/^- \*\*Prior:\*\* none$/- **Prior:** O-041/' "$spec/notes/opponent.md" > "$SANDBOX/schema-prior.md"
  cp "$SANDBOX/schema-prior.md" "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: a fabricated Prior neutralized a blocking finding'
  # A gate's first round can only reference review that predates any round, so
  # a declared <gate>-findings-*.md manifest beside the canonical reports is a
  # real source — and the canonical report itself deliberately is not, or a
  # report would vouch for the IDs it invented.
  mkdir -p "$spec/notes/verification/reports"
  cp "$spec/notes/opponent.md" "$spec/notes/verification/reports/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: a copy of the report vouched for its own IDs'
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** unrelated-class\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: an unrelated manifest Prior neutralized a blocking finding'
  # O-004 round 4: the manifest entry carrying the SAME Class as the finding is
  # the attack that survived three repairs -- Class is a field this report also
  # writes, so matching it binds the claim to nothing the author does not
  # control. Only the finding own ID counts, so a same-class Prior is refused.
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: a same-class manifest Prior neutralized a brand-new data-loss finding'
  # The same-ID manifest positive: this is the shape round 1 O-006 actually
  # has, and it must keep working or the canonical record stops parsing.
  printf '# Provisional review\n\n## Finding O-042\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  # The prior manifest is authored Markdown too. A same-class entry quoted in
  # a fence or HTML comment is a record of discarded prose, not trusted prior
  # review, and cannot authorize a resolved claim.
  printf '\140\140\140markdown\n## Finding O-042\n- **Class:** silent-data-loss\n\140\140\140\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: fenced manifest entry authorized a resolved claim'
  printf '<!--\n## Finding O-042\n- **Class:** silent-data-loss\n-->\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: commented manifest entry authorized a resolved claim'
  # O-002 round 4: condition-1 raw HTML renders nothing, so a manifest entry
  # hidden inside it is not a record a reader can see either.
  printf '<script>\n## Finding O-042\n- **Class:** silent-data-loss\n</script>\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: script-hidden manifest entry authorized a resolved claim'
  # The indentation rule is shared here too: only the opener line is code, so
  # the live manifest entry following it remains visible.
  printf '    <!--\n## Finding O-042\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-2026-09-09.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'blocking=0 minor=0'
  rm -rf "$spec/notes/verification/reports"
  # The same validator gates round --complete, which is where a scope-less
  # clearance would actually be canonized.
  load_gate_fixtures
  spec="$(make_verification_git_dir schema_round)"
  mkdir -p "$spec/notes/verification/reports"
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"
  report="$SANDBOX/schema-round-report.md"
  round_report "$spec" opponent "$reservation" "$report"
  sed '/^### What I attacked$/d' "$report" > "$SANDBOX/schema-round-no-scope.md"
  before=''
  [[ ! -f "$spec/notes/opponent.md" ]] || before="$(cat "$spec/notes/opponent.md")"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/schema-round-no-scope.md"
  assert_contains "$OUT" 'missing required report section: what i attacked'
  if [[ -f "$spec/notes/opponent.md" ]]; then
    assert_eq "$before" "$(cat "$spec/notes/opponent.md")" 'AC-012: refused report was canonized anyway'
  fi
  # O-004 round 4: this shape was a shipped POSITIVE asserting `round completed`
  # at rc=0 -- a brand-new data-loss finding neutralized by naming a real prior
  # ID of the same class. The fixture certified the attack, so no regression
  # here could ever be caught. It is a negative now.
  # One-token -v only: BSD awk rejects a newline inside a -v assignment, so the
  # block is printed line by line rather than interpolated.
  inject() { # src id prior dest
    awk -v id="$2" -v prior="$3" '/^### Held up \/ follow-up tasks$/ {
           print "### Finding " id
           print "- **Class:** silent-data-loss"
           print "- **Status:** resolved"
           print "- **Prior:** " prior
           print "- **Severity:** data-loss"
           print "- **Scenario:** rows vanish on retry"
           print "- **Where:** scripts/run.sh:9"
           print "- **Reproduced:** concrete trigger at that site"
           print "- **Root cause:** implementation-error"
           print "- **Blocks:** AC-012"
           print "- **Wrong behavior:** committed rows disappear"
           print "- **Class-wide fix:** guard the retry path"
         }
         {print}' "$1" > "$4"
  }
  inject "$report" O-042 O-041 "$SANDBOX/schema-round-resolved.md"
  before=''
  [[ ! -f "$spec/notes/opponent.md" ]] || before="$(cat "$spec/notes/opponent.md")"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/schema-round-resolved.md"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: a same-class Prior canonized a brand-new data-loss finding'
  if [[ -f "$spec/notes/opponent.md" ]]; then
    assert_eq "$before" "$(cat "$spec/notes/opponent.md")" 'AC-012: refused resolved claim was canonized anyway'
  fi
  # O-004 round 5: completion must bind the same ID to the Class established
  # by prior review, rather than letting the returned report redefine it.
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** return-envelope-parsing\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  inject "$report" O-041 O-041 "$SANDBOX/schema-round-class-drift.md"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/schema-round-class-drift.md"
  assert_contains "$OUT" 'finding O-041 changes Class from return-envelope-parsing to silent-data-loss' \
    'AC-012: round completion accepted Class drift for a manifest finding ID'
  if [[ -f "$spec/notes/opponent.md" ]]; then
    assert_eq "$before" "$(cat "$spec/notes/opponent.md")" 'AC-012: Class-drift completion changed the canonical report'
  fi
  # The same-ID manifest positive still seals, on the same temporary
  # combined.md path -- which is what T030o22 exists to keep working.
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  inject "$report" O-041 O-041 "$SANDBOX/schema-round-ownid.md"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$SANDBOX/schema-round-ownid.md"
  assert_contains "$OUT" 'round completed'

  # Reconciliation validates the same temporary combined.md path. A BLOCKED
  # report may seal after source drift, and its sole resolved finding still
  # resolves through the manifest anchored at the spec directory.
  spec="$(make_verification_git_dir schema_reconcile)"
  mkdir -p "$spec/notes/verification/reports"
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"
  report="$SANDBOX/schema-reconcile-report.md"
  round_report "$spec" opponent "$reservation" "$SANDBOX/schema-reconcile-base.md"
  blocked_with() { # id prior dest
    awk -v id="$1" -v prior="$2" '/^\*\*Verdict:\*\*/ {print "**Verdict:** BLOCKED"; next}
       /^### Held up \/ follow-up tasks$/ {
           print "### Finding " id
           print "- **Class:** silent-data-loss"
           print "- **Status:** resolved"
           print "- **Prior:** " prior
           print "- **Severity:** data-loss"
           print "- **Scenario:** rows vanish on retry"
           print "- **Where:** scripts/run.sh:9"
           print "- **Reproduced:** concrete trigger at that site"
           print "- **Root cause:** implementation-error"
           print "- **Blocks:** AC-012"
           print "- **Wrong behavior:** committed rows disappear"
           print "- **Class-wide fix:** guard the retry path"
         }
       {print}' "$SANDBOX/schema-reconcile-base.md" > "$3"
  }
  # The reconciliation path validated the identical combined.md and carried the
  # identical shipped positive, so it certified the attack twice.
  blocked_with O-042 O-041 "$report"
  printf '\n# drift after reservation\n' >> "$(cd "$spec/../../.." && pwd -P)/src/parser.sh"
  run_rc 3 bash "$cli" round "$spec" opponent --reconcile "$report"
  assert_contains "$OUT" 'resolved finding O-042 has no earlier round of this gate and no declared prior-review record' 'AC-012: reconcile canonized a same-class Prior attack'
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** return-envelope-parsing\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  blocked_with O-041 O-041 "$report"
  run_rc 3 bash "$cli" round "$spec" opponent --reconcile "$report"
  assert_contains "$OUT" 'finding O-041 changes Class from return-envelope-parsing to silent-data-loss' \
    'AC-012: reconciliation accepted Class drift for a manifest finding ID'
  printf '# Provisional review\n\n## Finding O-041\n\n- **Class:** silent-data-loss\n' \
    > "$spec/notes/verification/reports/opponent-findings-fixture.md"
  blocked_with O-041 O-041 "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$report"
  assert_contains "$OUT" 'round completed'
}

test_review_scope_contracts() {
  local opponent reality
  opponent="$(cat "$KIT_DIR/agents/opponent.agent.md")"
  reality="$(cat "$KIT_DIR/agents/reality-check.agent.md")"
  assert_contains "$opponent" 'attack covered and omitted cases'
  assert_contains "$opponent" 'defect on unchanged code'
  assert_contains "$opponent" 'every established blocker'
  assert_contains "$opponent" '**Reproduced:**'
  assert_contains "$opponent" '**Class:**'
  assert_contains "$opponent" '**Blocking:**'
  assert_contains "$opponent" 'severity to meet a cost/round target'
  assert_contains "$reality" 'Every round includes every AC'
  assert_contains "$reality" 'Same filenames never suffice'
}

# Load production-CLI fixture helpers without executing their separate suite.
# Each test already runs in its own subshell, so the definitions stay local.
load_gate_fixtures() {
  sed '/^\. .*helpers.sh/d; /^t_run_all$/d' "$KIT_DIR/tests/test-spec-gate.sh" > "$SANDBOX/gate-fixtures.sh"
  . "$SANDBOX/gate-fixtures.sh"
}

# AC-017: cost fields are summed from sealed records and measured capture
# bytes, never estimated. Spend has no source the kit can read, so it stays
# unknown even when executions and reuses are real.
cost_metric_cases() {
  local spec repo gate dir captures=0 bytes=0 summary=0
  load_gate_fixtures
  spec="$(make_verification_git_dir cost)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  gate="$(floor_fixture "$spec")"
  sed 's/^reuse_checks: \[\]/reuse_checks:\n  - '\''bash tests\/check.sh'\''/' "$repo/.specify/stack.yml" > "$SANDBOX/cost-stack"
  cp "$SANDBOX/cost-stack" "$repo/.specify/stack.yml"
  run_rc 0 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'executed=5 cache-hits=0'
  run_rc 0 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'executed=4 cache-hits=1'
  for dir in "$spec"/notes/captures/CAP-*; do
    [[ -d "$dir" ]] || continue
    captures=$((captures+1))
    bytes=$((bytes+$(wc -c < "$dir/output.log")))
    summary=$((summary+$(wc -c < "$dir/summary.txt")))
  done
  (( captures > 0 )) || t_fail 'no captures to measure'
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'execution-observations=2 check-executions=9 cache-hits=1'
  assert_contains "$OUT" "captures=$captures full-log-bytes=$bytes returned-summary-bytes=$summary"
  assert_contains "$OUT" 'usage=unknown baseline-usage=unknown'
}

# AC-013: execute evidence validation, then carry only a completed, unchanged PASS.
matrix_runtime_cases() {
  local spec repo cap source id text digest tmp evidence
  spec="$(make_verification_git_dir matrix)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  mkdir -p "$spec/notes/verification/rounds/reality-check/ROUND-1"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  source=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  tmp="$SANDBOX/matrix-rows"
  mkdir "$tmp"
  # No semantic PASS is inferred: this reviewer fixture supplies its claim.
  evidence="$cap; review: fixture checks the parser's good-value behavior"
  . "$SCRIPTS/verification-lib.sh"
  vf_ac_catalog "$spec" "$tmp/acs" || t_fail 'AC catalog'
  for round in 1 2; do
    {
      printf '## Round %s\n**Verdict:** READY\n' "$round"
      while IFS= read -r -d '' id && IFS= read -r -d '' text && IFS= read -r -d '' digest; do
        if [[ "$round" == 1 ]]; then status=PASS; else status='carried (round 1)'; fi
        printf '| %s | %s; sha256:%s | %s | %s | %s |\n' "$id" "$text" "$digest" "$evidence" "$source" "$status"
      done < "$tmp/acs"
    } > "$tmp/round-$round"
  done
  vf_report_block "$tmp/round-1" 1 > "$tmp/block"
  vf_hash "$tmp/block" > "$spec/notes/verification/rounds/reality-check/ROUND-1/report.sha256"
  cat "$tmp/round-1" "$tmp/round-2" > "$tmp/report"
  run_rc 0 vf_reality_matrix "$spec" "$tmp/report" 2 "$source" READY
  # AC-013/FM-016: a matrix row reproduced inside a nested example fence is
  # quoted text. Deleting the real AC-002 row and supplying it that way must
  # not satisfy the every-AC requirement.
  sed '/^| AC-002 /d' "$tmp/report" > "$tmp/quoted-row"
  {
    printf '\140\140\140\140markdown\n\140\140\140text\n'
    grep '^| AC-002 ' "$tmp/report"
    printf '\140\140\140\n\140\140\140\140\n'
  } >> "$tmp/quoted-row"
  run_rc 3 vf_reality_matrix "$spec" "$tmp/quoted-row" 2 "$source" READY
  # AC-013/FM-016: the same row supplied inside an HTML comment is quoted too.
  sed '/^| AC-002 /d' "$tmp/report" > "$tmp/commented-row"
  {
    printf -- '<!--\n'
    grep '^| AC-002 ' "$tmp/report"
    printf -- '-->\n'
  } >> "$tmp/commented-row"
  run_rc 3 vf_reality_matrix "$spec" "$tmp/commented-row" 2 "$source" READY
  # AC-013/FM-019 — O-012, round-record-reparse-divergence. The verdict is a
  # PARAMETER carrying the value vf_reports validated and emitted, so this
  # function's behavior cannot depend on how the report text spells its
  # **Verdict:** line. Isolated in BOTH directions over a report carrying a
  # MISSING row, because a one-directional case still passes under a parser
  # that reads the text. Text NEEDS WORK + catalog READY must refuse; text
  # READY + catalog NEEDS WORK must permit. The deleted second parser inverted
  # both. Spacing variants are covered end to end in tests/test-spec-gate.sh,
  # where the catalog value is produced by vf_reports rather than by a caller.
  sed 's/carried (round 1)/MISSING/g' "$tmp/report" > "$tmp/missing-row"
  sed '/^## Round 2$/,$ s/^\*\*Verdict:\*\* READY$/**Verdict:** NEEDS WORK/' "$tmp/missing-row" > "$tmp/text-needs-work"
  run_rc 3 vf_reality_matrix "$spec" "$tmp/text-needs-work" 2 "$source" READY
  assert_contains "$OUT" 'matrix: READY contains unsupported row' \
    'AC-013: the READY guard read the report text instead of the catalog verdict'
  run_rc 0 vf_reality_matrix "$spec" "$tmp/missing-row" 2 "$source" 'NEEDS WORK'
  # Fail closed on a caller that supplies no catalog value: an unrecognized
  # verdict must never reach the row check as "not READY" and permit the row.
  run_rc 3 vf_reality_matrix "$spec" "$tmp/missing-row" 2 "$source" ''
  assert_contains "$OUT" 'matrix: caller supplied no validated round verdict' \
    'AC-013: an unvalidated verdict stood the READY guard down'
  for mutation in missing criterion impact fail corrupt source; do
    cp "$tmp/report" "$tmp/bad"
    case "$mutation" in
      missing) sed '/^| AC-002 /d' "$tmp/report" > "$tmp/bad";;
      criterion) sed 's/sha256:/changed sha256:/g' "$tmp/report" > "$tmp/bad";;
      impact) sed "s/$source/unknown/g" "$tmp/report" > "$tmp/bad";;
      fail) sed 's/carried (round 1)/MISSING/g' "$tmp/report" > "$tmp/bad";;
      corrupt) cp "$spec/notes/captures/$cap/output.log" "$tmp/log"; printf tampered >> "$spec/notes/captures/$cap/output.log";;
      source) printf '\n# dependency changed\n' >> "$repo/src/parser.sh";;
    esac
    run_rc 3 vf_reality_matrix "$spec" "$tmp/bad" 2 "$source" READY
    [[ "$mutation" != corrupt ]] || cp "$tmp/log" "$spec/notes/captures/$cap/output.log"
  done
}

# AC-015 / AC-019: drive the invoker protocol against executable worker/gate
# stubs under the suite's actual platform Bash. The production-CLI probe below
# checks isolated capture, refusal, acceptance and gate state on each platform.
# The source assertions below bind this sequence to all four instruction entrypoints.
invoker_sequence() {
  local attempt=0 rc=0 op
  printf 'barrier\n' >> "$SANDBOX/trace"
  while :; do
    printf 'capture --from-task --no-tick --summary\n' >> "$SANDBOX/trace"
    bash "$SANDBOX/gate-stub" accept || rc=$?
    (( rc )) || break
    (( attempt == 0 )) || return "$rc"
    printf 'escalation\n' >> "$SANDBOX/trace"
    attempt=$((attempt+1)); rc=0
  done
  for op in checkpoint floor round; do
    bash "$SANDBOX/gate-stub" "$op" || return $?
  done
  printf 'dispatch-opponent\n' >> "$SANDBOX/trace"
  bash "$SANDBOX/gate-stub" complete || return $?
}
test_invoker_protocol() {
  probe_fixture_cases
  local failure text
  cat > "$SANDBOX/gate-stub" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$PROTOCOL_TRACE"
[[ "$1" != "$PROTOCOL_FAIL" ]] || exit "$PROTOCOL_EXIT"
STUB
  export PROTOCOL_TRACE="$SANDBOX/trace" PROTOCOL_FAIL='' PROTOCOL_EXIT=3
  run_rc 0 invoker_sequence
  text="$(cat "$SANDBOX/trace")"
  assert_contains "$text" 'barrier'
  assert_contains "$text" 'capture --from-task --no-tick --summary'
  assert_contains "$text" 'dispatch-opponent'
  for failure in accept checkpoint floor round; do
    : > "$SANDBOX/trace"
    export PROTOCOL_FAIL="$failure"
    if [[ "$failure" == round ]]; then export PROTOCOL_EXIT=4; else export PROTOCOL_EXIT=3; fi
    run_rc "$PROTOCOL_EXIT" invoker_sequence
    text="$(cat "$SANDBOX/trace")"
    assert_not_contains "$text" 'dispatch-opponent'
    if [[ "$failure" == accept ]]; then
      assert_eq 1 "$(grep -c '^escalation$' "$SANDBOX/trace")"
      assert_eq 2 "$(grep -c '^accept$' "$SANDBOX/trace")"
      assert_not_contains "$text" 'checkpoint'
    fi
  done
}
invoker_instruction_cases() {
  local file text field
  for file in agents/sdd-orchestrator.md skills/sdd-implement/SKILL.md skills/sdd-go/SKILL.md skills/sdd-review/SKILL.md; do
    text="$(cat "$KIT_DIR/$file")"
    assert_contains "$text" '--from-task --no-tick --summary'
    assert_contains "$text" 'spec-gate.sh" accept'
    assert_contains "$text" 'one escalation retry'
    assert_contains "$text" 'batch barrier'
    assert_contains "$text" 'spec-gate.sh" checkpoint'
    assert_contains "$text" 'spec-gate.sh" floor'
    assert_contains "$text" 'spec-gate.sh" round'
    assert_contains "$text" '--complete'
    # Returns and reports are spec bookkeeping: a file written beside the code
    # changes the input manifest and invalidates the capture it belongs to.
    assert_contains "$text" 'notes/verification/returns/T###.txt'
    assert_contains "$text" 'notes/verification/reports/$GATE.md'
    assert_not_contains "$text" 'accept "$SPEC" T### return.txt'
    assert_not_contains "$text" '--complete report.md'
    assert_contains "$text" 'exit 4'
    assert_contains "$text" 'Rounds 1–3'
    # AC-018 — O-002: the authoring-time checker belongs where the round cap is
    # explained. An operator cannot run a validator they have never seen, which
    # is why the second half of that class was open by documentation and not by
    # code — the round-6 waiver never parsed and cost a cold floor.
    assert_contains "$text" 'spec-gate.sh" waiver' \
      'AC-018: the round-cap paragraph does not name the authorization checker'
    assert_contains "$text" 'including unchanged code'
    assert_not_contains "$text" 'from round 3'
    assert_not_contains "$text" 'pasted command output is'
    assert_not_contains "$text" 'a reply without pasted output is a failed task'
    assert_not_contains "$text" 'done … --evidence'
    assert_not_contains "$text" 'ONE fix round'
    assert_contains "$text" 'Only its exit 0 accepts the task'
  done
  # Hand-ticking must not survive anywhere an invoker records work. Only the
  # implement skill may name the bookkeeping tool accept wraps, and only for
  # the gate/Ship administration tasks that own no test family.
  for file in agents/sdd-orchestrator.md skills/sdd-go/SKILL.md skills/sdd-review/SKILL.md; do
    assert_not_contains "$(cat "$KIT_DIR/$file")" 'spec-task.sh'
  done
  text="$(cat "$KIT_DIR/skills/sdd-implement/SKILL.md")"
  assert_contains "$text" 'the only path that ticks an implementation task'
  assert_contains "$text" 'Gate and Ship administration tasks'
  assert_not_contains "$text" 'via spec-task.sh'
  # Both /sdd:review fix paths — CI red and requested changes — accept the same way.
  assert_eq 2 "$(grep -c 'spec-gate.sh accept' "$KIT_DIR/skills/sdd-review/SKILL.md")"
  assert_not_contains "$(cat "$KIT_DIR/skills/sdd-review/SKILL.md")" 'evidence on tick'
  # AC-015 (FM-009): c/r follow-ups are behavior tasks the Ship exemption does
  # not reach, so the instructions must prescribe the binding the validator
  # requires. The executable end-to-end case lives in the acceptance family.
  text="$(cat "$KIT_DIR/skills/sdd-review/SKILL.md")"
  for field in '*Verify kind:*' '*Tests:*' '*Verify:*'; do
    assert_contains "$text" "$field" "AC-015: review follow-ups omit $field"
  done
  assert_contains "$text" 'the Ship exemption does not reach them'
  assert_contains "$text" 'registered in'
  assert_not_contains "$text" 'each with *Files:*, *Acceptance:* (the failing check'
  assert_not_contains "$text" 'tasks: Files/Acceptance/Refs'
}


gate_dispatch_verbs() {
  # A finite literal subset of Bash help case's clause production. Inspect
  # EVERY line in the dispatcher; unsupported syntax is an error, never an
  # absent verb. This intentionally refuses globs, expansions, quoted patterns
  # and multiline/nested bodies instead of pretending to parse arbitrary Bash.
  LC_ALL=C awk '
    function trim(s) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s}
    function fail() {
      printf "AC-018: unclassifiable spec-gate.sh dispatcher clause at line %d: %s\n", NR, $0 > "/dev/stderr"
      bad=1; exit 3
    }
    /^[[:space:]]*case "\$command_name" in[[:space:]]*(#.*)?$/ {
      if(seen++) fail(); on=1; next
    }
    on {
      line=trim($0)
      if(line ~ /^(#|$)/) next
      if(line ~ /^esac([[:space:]]+#.*)?$/) {on=0; closed=1; next}
      if(catchall) fail()
      sub(/^\([[:space:]]*/, "", line)
      pos=index(line, ")"); if(!pos) fail()
      patterns=trim(substr(line, 1, pos-1)); body=trim(substr(line, pos+1))
      if(body !~ /;;$/) fail()
      sub(/;;$/, "", body)
      if(body ~ /;;|;&/) fail()
      if(patterns=="*") {
        # The only nonliteral clause is the known usage refusal. A catch-all
        # executing a new operation would otherwise erase the finite boundary.
        if(body != "echo '\''unknown or unavailable gate operation'\'' >&2; exit 2") fail()
        catchall=1; next
      }
      count=split(patterns, alternatives, /\|/)
      for(i=1; i<=count; i++) {
        verb=trim(alternatives[i])
        if(verb !~ /^[A-Za-z0-9_.\/:+@%=-]+$/ || verbs[verb]++) fail()
        result=result verb "\n"
      }
    }
    END {
      if(bad) exit 3
      if(seen!=1 || on || !closed || !catchall || result=="") fail()
      printf "%s", result
    }' "$1"
}

gate_documentation_check() {
  local cli="$1" readme_file="$2" verb verbs derived synopsis readme OUT _t_fail=0
  verbs="$(gate_dispatch_verbs "$cli")" || return 3
  [[ -n "$verbs" ]] || { t_fail 'AC-018: no spec-gate.sh subcommands were derived from the dispatcher'; return 1; }
  run_rc 0 bash "$cli" --help
  # shellcheck disable=SC2086
  derived="$(printf '%s\n' $verbs | LC_ALL=C sort | tr '\n' ' ')"
  synopsis="$(printf '%s\n' "$OUT" | sed -n 's/^Usage: spec-gate.sh <\([^>]*\)>.*/\1/p' | tr '|' '\n' | LC_ALL=C sort | tr '\n' ' ')"
  assert_eq "$derived" "$synopsis" 'AC-018: the --help synopsis and the dispatcher disagree on the subcommand set'
  readme="$(cat "$readme_file")"
  for verb in $verbs; do
    assert_contains "$OUT" "  $verb <spec-dir>" "AC-018: spec-gate.sh $verb has no --help detail line"
    assert_contains "$readme" "spec-gate.sh $verb " \
      "AC-018: spec-gate.sh $verb appears in no operator-facing document"
  done
  return "$_t_fail"
}

gate_dispatch_grammar_cases() {
  local kit cli clause verb
  kit="$SANDBOX/dispatch-kit"; mkdir -p "$kit/scripts" "$kit/spec"
  # The kit's scripts as the input identity enumerates them (copy_kit's
  # directory selector), never a glob of the live scripts/: an ignored entry
  # there -- a stray script, a FIFO -- would otherwise arrive (O-015 review 3).
  copy_kit "$KIT_DIR" "$kit" scripts || { t_fail 'AC-018: cannot stage the kit scripts for the dispatch grammar'; return; }
  cli="$kit/scripts/spec-gate.sh"
  # Bash help case defines optional ( and | alternatives, not one line prefix.
  # Each mutant really executes before its three documentation failures count.
  for clause in '  probe)' '  (probe)' '  probe2)' $'\t(probe_2 | probe-alias)'; do
    awk -v clause="$clause" '/^  \*\)/ {print clause " exit 0;;"} {print}' \
      "$SCRIPTS/spec-gate.sh" > "$cli"
    case "$clause" in *probe_2*) verb=probe_2;; *probe2*) verb=probe2;; *) verb=probe;; esac
    run_rc 0 bash "$cli" "$verb" "$kit/spec"
    run_rc 1 gate_documentation_check "$cli" "$KIT_DIR/README.md"
    assert_contains "$OUT" 'AC-018: the --help synopsis and the dispatcher disagree on the subcommand set'
    assert_contains "$OUT" "AC-018: spec-gate.sh $verb has no --help detail line"
    assert_contains "$OUT" "AC-018: spec-gate.sh $verb appears in no operator-facing document"
    if [[ "$verb" == probe_2 ]]; then
      assert_contains "$OUT" 'AC-018: spec-gate.sh probe-alias has no --help detail line'
      assert_contains "$OUT" 'AC-018: spec-gate.sh probe-alias appears in no operator-facing document'
    fi
  done
  # Equivalent spellings of documented clauses must continue to pass.
  sed -E 's/^  ([a-z-]+)\)/\t(\1)/' "$SCRIPTS/spec-gate.sh" > "$cli"
  run_rc 0 gate_documentation_check "$cli" "$KIT_DIR/README.md"
  # Two clauses on one line are two verbs to bash, and the second really
  # executes. The body check must refuse the line: without it the reader
  # classifies only `probe` and the second verb silently leaves the
  # documentation obligation (round 9, Held up).
  awk -v clause='  probe) :;; probe3) echo probe3; exit 0;;' '/^  \*\)/ {print clause} {print}' \
    "$SCRIPTS/spec-gate.sh" > "$cli"
  run_rc 0 bash "$cli" probe3 "$kit/spec"
  assert_contains "$OUT" 'probe3' 'AC-018: the two-clause fixture line is not a second executable verb'
  run_rc 3 gate_dispatch_verbs "$cli"
  assert_contains "$OUT" 'AC-018: unclassifiable spec-gate.sh dispatcher clause' \
    'AC-018: a clause line hiding a second verb was classified'
  # Patterns outside the finite literal subset must be diagnosed, not dropped.
  for clause in '  probe*) :;;' '  "probe") :;;' '  [pq]robe) :;;' '  $verb) :;;' '  probe) : ;&' '  probe)'; do
    awk -v clause="$clause" '/^  \*\)/ {print clause} {print}' "$SCRIPTS/spec-gate.sh" > "$cli"
    run_rc 3 gate_dispatch_verbs "$cli"
    assert_contains "$OUT" 'AC-018: unclassifiable spec-gate.sh dispatcher clause'
  done
  # A catch-all that executes an operation no longer denotes a finite verb set.
  awk '/^  \*\)/ {print "  *) exit 0;;"; next} {print}' "$SCRIPTS/spec-gate.sh" > "$cli"
  run_rc 3 gate_dispatch_verbs "$cli"
  assert_contains "$OUT" 'AC-018: unclassifiable spec-gate.sh dispatcher clause'
}

public_workflow_cases() {
  local script spec document text
  # AC-018: both public entry documents distinguish the required floor from
  # optional stage commands; neither presence nor a legacy capture means fresh.
  for document in README.md constitution.md; do
    text="$(tr '\n' ' ' < "$KIT_DIR/$document")"
    assert_contains "$text" 'Required `gate_checks`'
    assert_contains "$text" 'Optional `checkpoints`'
    # Each entry document explains the whole contract, not only the required
    # floor: opt-in, integrity versus freshness, the no-tick/summary capture,
    # class IDs, scope-aware review, the round cap and who still decides.
    for topic in verification_contract integrity freshness --no-tick --summary \
        Class unexamined 'Rounds 1–3' 'security-review authority'; do
      assert_contains "$text" "$topic"
    done
  done
  for script in spec-run spec-task spec-evidence spec-ac-coverage spec-gate; do
    run_rc 0 bash "$SCRIPTS/$script.sh" --help
    [[ -n "$OUT" ]] || t_fail "empty help: $script"
    assert_contains "$OUT" "$script.sh"
  done
  # AC-018 — O-002, second half. The verb set is DERIVED from the dispatcher in
  # spec-gate.sh rather than restated here, so a new subcommand inherits the
  # obligation instead of needing to be added to a list. This guard enumerated
  # five verbs, which is exactly how `spec-gate.sh waiver` shipped with its own
  # --help line and no mention in any document an operator reads — a validator
  # nobody can discover validates nothing, and the round-6 waiver defect cost a
  # cold floor for want of it. Three obligations per verb: the dispatcher, the
  # --help synopsis and the --help detail lines must agree, and the operator
  # entry document must name it.
  run_rc 0 gate_documentation_check "$SCRIPTS/spec-gate.sh" "$KIT_DIR/README.md"
  gate_dispatch_grammar_cases
  documented_example_cases
  spec="$(make_spec_dir)"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=0'
  # The documented reservation is a mutation guarded by a real floor.
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" round "$spec" opponent
  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-1" ]] || t_fail 'documented round bypassed floor'
  assert_contains "$(cat "$KIT_DIR/README.md")" 'spec-gate.sh accept'
  assert_contains "$(cat "$KIT_DIR/templates/verification-contract.md")" 'Verification-Return: 1'
}
# AC-018: the published workflow is executable, not illustrative. Every command
# line in the README block runs here, in order, against a real fixture kit — the
# way a reader would run it from the worktree root. A documented example that
# cannot run (a return file written beside the code makes its own capture stale)
# is a defect this fixture reports instead of the reader discovering it.
documented_example_cases() {
  local spec repo prev line cap ran=0
  load_gate_fixtures
  prev="$PWD"
  spec="$(make_verification_git_dir documented)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  floor_fixture "$spec" > /dev/null
  # The kit's scripts as the input identity enumerates them (copy_kit's
  # directory selector): an ignored entry under a developer's scripts/ -- a
  # directory link, a nested clone -- would otherwise become an input of this
  # fixture repository's own identity (O-015 second review).
  copy_kit "$KIT_DIR" "$repo" scripts || { t_fail 'documented fixture: cannot copy the kit scripts'; return; }
  awk '/^### Versioned verification workflow/ {on=1}
       on && /^```bash$/ {block=1; next}
       block && /^```$/ {exit}
       block {print}' "$KIT_DIR/README.md" > "$SANDBOX/readme-block"
  [[ -s "$SANDBOX/readme-block" ]] || { t_fail 'README documents no runnable workflow'; return; }
  export SPEC="$spec" TASK=T001 STAGE=Backend
  cd "$repo" || { t_fail "documented fixture repo missing: $repo"; return; }
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue;; esac
    ran=$((ran+1))
    case "$line" in
      'bash scripts/'*) run_rc 0 eval "$line";;
      # Reader setup (paths, directories) runs in this shell so later lines see it.
      *) eval "$line" || t_fail "documented setup failed: $line";;
    esac
    case "$line" in
      *spec-run.sh*)
        cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
        [[ -n "$cap" ]] || t_fail 'documented capture command returned no capture ID'
        accept_return "$spec" T001 "$cap" "$spec/notes/verification/returns/T001.txt";;
      *'spec-gate.sh round '*)
        [[ "$line" == *--complete* ]] ||
          round_report "$spec" opponent "$OUT" "$spec/notes/verification/reports/opponent.md";;
    esac
  done < "$SANDBOX/readme-block"
  assert_eq 9 "$ran" 'documented workflow commands executed'
  assert_contains "$OUT" 'opponent rounds=1'
  # The reader exported the documented names, so a checker that rewrote one of
  # them would disagree with every capture and report valid proof as stale.
  run_rc 0 bash "$repo/scripts/spec-evidence.sh" "$spec"
  assert_contains "$OUT" 'all completed task checks have valid current captures'
  cd "$prev" || t_fail "cannot restore $prev"
  # The documented paths keep returns and reports out of the verified source.
  [[ ! -e "$repo/return.txt" && ! -e "$repo/report.md" ]] ||
    t_fail 'documented workflow left a return/report file in the worktree'
}

# O-015 second review: an ignored entry under a developer's scripts/ -- a
# directory link, a nested clone -- is not kit content. Copied into the
# documented workflow's fixture repository it became an untracked input there,
# which that repository's identity refuses, and the workflow failed while the
# kit's own identity stayed unchanged.
test_ignored_local_scripts_do_not_reach_the_documented_workflow() {
  local host="$SANDBOX/host-kit"
  make_host_kit "$host" || t_fail 'cannot build the host kit'
  printf 'scripts/zz-dir\nscripts/zz-tool/\n' >> "$host/.git/info/exclude"
  mkdir -p "$SANDBOX/outside-dir" "$host/scripts/zz-tool"
  printf 'outside\n' > "$SANDBOX/outside-dir/note.md"
  ln -s "$SANDBOX/outside-dir" "$host/scripts/zz-dir"
  fixture_git -C "$host/scripts/zz-tool" init -q || fixture_build_failed nested-clone
  on_host_kit "$host" documented_example_cases
}

# O-015 review 3: the dispatch-grammar fixture globbed the live scripts/, the
# sixth copy of live-kit content outside copy_kit. An ignored script in a
# developer's kit must not reach its dispatch kit.
test_ignored_local_scripts_do_not_reach_the_dispatch_grammar_kit() {
  local host="$SANDBOX/host-kit"
  make_host_kit "$host" || t_fail 'AC-018: cannot build the host kit'
  printf 'scripts/zz-local.sh\n' >> "$host/.git/info/exclude"
  printf 'echo local\n' > "$host/scripts/zz-local.sh"
  on_host_kit "$host" gate_dispatch_grammar_cases
  [[ -f "$SANDBOX/dispatch-kit/scripts/verification-lib.sh" ]] \
    || t_fail 'AC-018: the dispatch-grammar fixture did not stage an enumerated script'
  [[ ! -e "$SANDBOX/dispatch-kit/scripts/zz-local.sh" ]] \
    || t_fail "AC-018: the dispatch-grammar fixture staged the host kit's ignored script"
}

metrics_instruction_cases() {
  local file text lower
  for file in templates/retro-template.md skills/sdd-retro/SKILL.md; do
    text="$(cat "$KIT_DIR/$file")"
    assert_contains "$text" 'Class'
    assert_contains "$text" 'Root cause'
    assert_contains "$text" 'raw'
    assert_contains "$text" 'reopened'
    assert_contains "$text" 'unknown'
    assert_contains "$text" '14-day'
    assert_contains "$text" 'check-back date'
    assert_contains "$text" 'three measurement'
    assert_contains "$text" 'usage'
    # AC-017: the proxies the tally can actually measure are named alongside
    # the spend it cannot, so neither half is quietly dropped from the retro.
    lower="$(printf '%s' "$text" | tr 'A-Z' 'a-z')"
    assert_contains "$lower" 'cache hits'
    assert_contains "$lower" 'log bytes'
    assert_contains "$lower" 'summary bytes'
  done
}

probe_fixture_cases() {
  local spec repo cli cap report reservation kit rejection events
  load_gate_fixtures
  spec="$(make_verification_git_dir probe)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  cli="$(floor_fixture "$spec")"
  kit="${cli%/scripts/spec-gate.sh}"
  mkdir "$kit/tests"; cp "$KIT_DIR/tests/probe-gate-contract.sh" "$kit/tests/"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  run_rc 0 bash "$kit/scripts/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/intact"
  sed '/^FM-001,/d' "$SANDBOX/intact" > "$SANDBOX/incomplete"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/incomplete"
  run_rc 0 bash "$cli" accept "$spec" T001 "$SANDBOX/intact"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"; report="$SANDBOX/opponent-report"
  round_report "$spec" opponent "$reservation" "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'reality-check current reservation'
  run_rc 0 bash "$cli" round "$spec" reality-check
  run_rc 0 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'live wiring PASS'
  # Only a rejection recorded BEFORE the acceptance is a genuine control: one
  # recorded afterwards carries the post-tick task digest and a later stamp, so
  # re-running the incomplete return cannot manufacture the observation.
  rejection="$(printf '%s' "$OUT" | sed -n 's/.* rejection=\([^ ]*\).*/\1/p')"
  events="$spec/notes/verification/accept-events"
  mv "$events/$rejection" "$SANDBOX/genuine-rejection"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'rejected-copy/intact-acceptance control missing'
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/incomplete"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'rejected-copy/intact-acceptance control missing'
  mv "$SANDBOX/genuine-rejection" "$events/$rejection"
  run_rc 0 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  cp "$spec/notes/captures/$cap/output.log" "$SANDBOX/probe-log"
  printf tampered >> "$spec/notes/captures/$cap/output.log"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  cp "$SANDBOX/probe-log" "$spec/notes/captures/$cap/output.log"
  printf '\n# source changed\n' >> "$repo/src/parser.sh"
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  probe_rejection_class_cases
}

# AC-016: the required control is the deliberately incomplete FM/INV copy.
# Rejections of other classes, recorded before the acceptance and otherwise
# indistinguishable to the probe, must not certify the observation.
probe_rejection_class_cases() {
  local spec repo cli kit ncap saved reservation report event class found=0
  spec="$(make_verification_git_dir probeclass)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  cli="$(floor_fixture "$spec")"
  kit="${cli%/scripts/spec-gate.sh}"
  mkdir "$kit/tests"; cp "$KIT_DIR/tests/probe-gate-contract.sh" "$kit/tests/"
  run_rc 0 bash "$kit/scripts/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  ncap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$ncap" "$SANDBOX/class-intact"
  # Three rejections that are NOT the required control, all before acceptance.
  sed 's/^Summary:.*/Summary: all passed/' "$SANDBOX/class-intact" > "$SANDBOX/class-forged"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/class-forged"
  sed 's/^Task:.*/Task: T002/' "$SANDBOX/class-intact" > "$SANDBOX/class-wrongtask"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/class-wrongtask"
  # A truncated envelope carries a COMPLETE row set that the parser dropped,
  # so it must be typed apart from a genuine missing row (O-003).
  {
    printf 'Verification-Return: 1\nTask: T001\nCaptures: %s\nSummary: ' "$ncap"
    cat "$spec/notes/captures/$ncap/summary.txt"
    printf 'Failure modes:\nThe rows below map every required row.\n'
    printf 'FM-001, tests/check.sh::test_ac_001_shared, %s\n' "$ncap"
  } > "$SANDBOX/class-truncated"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/class-truncated"
  assert_contains "$OUT" 'Failure modes section ended at narrative'
  cp "$repo/src/parser.sh" "$SANDBOX/class-parser"
  printf '\n# temporarily changed\n' >> "$repo/src/parser.sh"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/class-intact"
  cp "$SANDBOX/class-parser" "$repo/src/parser.sh"
  run_rc 0 bash "$cli" accept "$spec" T001 "$SANDBOX/class-intact"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"; report="$SANDBOX/class-report"
  round_report "$spec" opponent "$reservation" "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  run_rc 0 bash "$cli" round "$spec" reality-check
  # Every gate identity the probe needs is present; only the control is wrong.
  run_rc 3 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'rejected-copy/intact-acceptance control missing' \
    'AC-016: an arbitrary rejection class certified the live control'
  # The classes really were recorded, so the refusal is discrimination and not
  # a missing event.
  . "$SCRIPTS/verification-lib.sh"
  for event in "$spec"/notes/verification/accept-events/ACCEPT-*; do
    vf_meta_load "$event/meta.nul" 'version task return_digest outcome reason class before after timestamp' || t_fail 'accept event metadata'
    [[ "$(vf_meta_get outcome)" == rejected ]] || continue
    class="$(vf_meta_get class)"
    case "$class" in
      forged-summary|wrong-task|stale-capture|truncated-envelope) found=$((found+1));;
      binding-mismatch) t_fail 'AC-016: a non-control rejection was typed as the control';;
    esac
  done
  assert_eq 4 "$found" 'AC-016: the four non-control rejections were not typed'
  # Now record the real control before a second acceptance and let it pass.
  sed '/^FM-001,/d' "$SANDBOX/class-intact" > "$SANDBOX/class-incomplete"
  saved="$spec/tasks.md"
  sed 's/^- \[x\] \*\*T001\*\*/- [ ] **T001**/' "$saved" > "$SANDBOX/class-untick"
  cp "$SANDBOX/class-untick" "$saved"
  run_rc 3 bash "$cli" accept "$spec" T001 "$SANDBOX/class-incomplete"
  run_rc 0 bash "$cli" accept "$spec" T001 "$SANDBOX/class-intact"
  run_rc 0 bash "$kit/tests/probe-gate-contract.sh" "$spec" --task T001
  assert_contains "$OUT" 'class=binding-mismatch'
}

t_run_all
