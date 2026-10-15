# T030o43 — the class-wide whitespace design for review 2 (option 1), NOT yet measured or adopted

Written 2026-09-28 at the end of session 7, as a working design for the next session. It is
NOT a decision: the next session measures it in a standalone copy, records the measured rule
in Decisions, and only then changes code. Every claim below is a claim to test.

## Why (the mechanism review 2 exposed)

Under the harness pin (`LC_ALL=C`) a byte >= 0x80 is in no character class. Before the pin, a
UTF-8 caller's macOS awk read U+00A0 as `[[:space:]]` (and grep also read U+3000). So every
harness parser that trims or separates with `[[:space:]]` changed meaning for non-ASCII
whitespace: fields no longer recognized (review 1 F1), emptiness tests reading a U+00A0-only
value as present (R2-F4), name tokens absorbing a U+00A0 (R2-F5). Site-by-site repairs keep
finding the next site. Measured this session: NO file in the kit's enumeration contains any
non-ASCII White_Space character, and no report or manifest has CRLF endings
(`t030o43-review2-verify.log` context; the grep over `git ls-files`), so normalizing them
changes no recorded parse or digest.

## The design

1. One shared awk function, `vf_ws(s)`: every UTF-8 encoding of a NON-ASCII Unicode White_Space
   character becomes one ASCII space, and a trailing CR is dropped (CRLF files). ASCII
   whitespace is left alone (tabs decide indented code in `vf_indented`/`vf_fence`, and the plan
   parser refuses tabs in table values). Set, as UTF-8: C2 85, C2 A0, E1 9A 80,
   E2 80 80–8A, E2 80 A8, E2 80 A9, E2 80 AF, E2 81 9F, E3 80 80 (19 code points). Regex tested
   under BSD awk: `\302[\205\240]|\341\232\200|\342\200[\200-\212\250\251\257]|\342\201\237|\343\200\200`.
   Define `_VF_AWK_WS='function vf_ws(s) {...}'` BEFORE `_VF_AWK_FENCE`, and after it
   `_VF_AWK_TEXT="$_VF_AWK_WS$_VF_AWK_FENCE"'{ $0 = vf_ws($0) }'`: the prelude every parser of
   author text prepends; the rule is its first main rule, so every later rule, and
   `vf_quoted`'s state, sees the normalized line.
2. Switch to `_VF_AWK_TEXT` every program that now prepends `_VF_AWK_FENCE` EXCEPT
   `vf_report_block` (`:2605` today), whose output is a sealed digest and must stay raw:
   `vf_config`'s tasks stage map (`:209`), `vf_bindings` plan (`:583`), inventory (`:771`) and
   tasks (`:807`) passes, the manifest pass (`:1087`), the main `vf_reports` pass (`:1117`), the
   waiver scanner (`:2653`), `vf_matrix_parse` (`:2891`), and the analyzer's three awk passes
   (`sdd-analyze.sh:204`, `:241`, `:281`; the AGENTLINE it prints is then normalized, which
   repairs the agent-path half of R2-F5). Programs without the fence that read author text
   prepend `_VF_AWK_WS` and the same rule: `vf_fm_value`, `vf_fm_count`, `vf_ac_catalog`, and
   `spec-evidence.sh`'s legacy records awk. Remove `vf_blank` and restore the section-body test
   `$0 !~ /^[[:space:]]*$/` (normalization covers it).
3. `vf_semantic_file` (STATUS): recognize on a normalized copy, print raw. Start a hashed
   section at EVERY line whose normalized text begins `## Decisions log` (quoted or not), and
   end it only at an UNQUOTED `## ` line (prepend `_VF_AWK_FENCE`, track `vf_quoted` on the
   normalized copy). That is a superset of the pre-delta rule (start at each exact heading, end
   at any `## `), so the identity keeps more, never less; it repairs R2-F1 and the fenced
   `## Round 3` sibling. The waiver scanner keeps reading only the exact heading. Update the
   contract sentence at `templates/verification-contract.md` ~:330 ("exact heading, in both
   views") and note T030o17's "in step" rule is kept in the safe direction.
4. The manifest pass, restructured (repairs R2-F2 and R2-F3), after normalization:
   - line 1: strip a BOM (`\357\273\277`); `vf_quoted($0) {next}`; skip indented code
     (`vf_indented`, 4+ columns);
   - a heading is `^[ ]{0,3}#+[ ]`. Its first word, case-insensitive, `finding` with a second
     word matching `^[A-Z][A-Z0-9]*-[0-9]+$` opens a finding (trailing title text allowed, as
     the canonical parser reads `### Finding G-042 — title`); `finding` with an ID-shaped but
     ill-cased second word is an error by name; any other heading (including `## Findings` and
     `## Finding summary`) flushes the current finding and opens none;
   - a field is any line whose first word, after an optional list marker (`-`, `*`, `+`) and
     emphasis (`*`, `_`), is `class` or `severity` (any case) followed by optional emphasis and a
     colon. It must match `^[ ]{0,3}-[ ]+\*\*(Class|Severity):\*\*`; it must sit inside a
     finding; each may appear once per finding; the Class must match the Class grammar and the
     Severity the severity list. Everything else is prose and ignored (so a Scenario or a
     follow-up line that merely mentions `**Class:**` parses);
   - a finding with no readable Class is an error; at END an open fence, comment or raw-HTML
     block is an error; any error exits 3, which the status read refuses by name.
   Measure first against the real 003 manifest, the round-12 O-017 block verbatim, and every
   shipped fixture manifest (Class-only findings must still parse).
5. Emptiness (R2-F4): covered by 1–2 (canonical finding fields, `vf_bindings`' manual
   observation and plan placeholders, legacy Evidence). One U+00A0 fixture per member.
6. Artifact names (R2-F5, `spec-evidence.sh`): tokens come from the normalized Evidence text,
   so they split at a U+00A0. A token is accepted if it, or it with a leading run of non-ASCII
   bytes or ASCII wrapping punctuation (`"'` + "\`" + `([{<`) removed, exists — so a curly quote
   or a full-width colon glued to the front is tolerated, and a missing name still fails. Loop
   with globbing off (`set -f`), so `shots/*.png` is a name, not a pattern (review 2's
   out-of-scope observation).
7. R2-F6: one kernel helper `vf_contract <spec.md>` routing by KEY count: no key is legacy; one
   key with value 1 is current; anything else (an empty value, a duplicate) is refused by name.
   Used by `spec-run.sh`, `spec-task.sh`, `spec-evidence.sh` (replacing the three-way value test).
   With normalization, `verification_contract:<U+00A0>1` then reads as 1 (the pre-delta UTF-8
   reading), so the D4 fixture changes from "refused" to "the current-evidence check runs".
8. Fixtures (each with a matrix row): every one of the 19 code points as a manifest field
   separator, read in both locales (a mutant dropping one fails by diagnostic); every R2-F2
   spelling (lowercase or leading-space heading read; word before `finding`, unbolded or
   duplicated Severity, field outside a finding, unclosed fence refused); the R2-F3 shapes parse;
   the R2-F1 identity pairs (fenced heading, archived heading, duplicate section, fenced
   `## Round` inside the log) differ, and the waiver scanner and the identity agree on the
   waiver line; the four R2-F4 members; the R2-F5 artifact and agent-path cases; the empty
   contract value refused by the three scripts. R2-F7's gaps close with these.
9. Wording (R2-F8): the kernel comments, the contract, `t030o43-parser-classes.md` (replace
   the character-class section: the rule is normalization; `vf_report_block` deliberately raw;
   literal-space parsers such as `vf_config`'s stack.yml grammar and `vf_return_parse` never read
   U+00A0 as a space in any locale; bash glob ranges DO match non-ASCII under UTF-8, but the one
   harness glob range is re-checked by a regex), and the task block's Acceptance.

## Recorded, not in scope

A waiver with `by= ` or `by=<U+00A0>` authorizes (pre-existing). `system-map.sh` and
`sdd-doctor.sh` also parse under the pin (umbrella and diagnostic surfaces). A C1 control byte
in `stack.yml` (UTF-8 `[[:cntrl:]]`) is no longer rejected under the pin; it reaches only the
project's own command string. Invisible non-White_Space characters (U+200B, U+2060, U+FEFF
mid-line, U+00AD) remain content, as they were under UTF-8.

## Order for the next session

Measure this design in a standalone copy (the review-2 cases of `t030o43-review2-verify.sh` and
the review-1 cases give their intended results under C and en_US.UTF-8; tally for 001/002/003
and the snapshot, including every STATUS's semantic view, unchanged), record the measured rule
and any correction in Decisions, then implement, fixtures, matrix rows (rewrite S31–S40 for the
new code), dev runs (quick, full, full under en_US.UTF-8), one focused review 3, the matrix,
freeze, capture, return, accept, the floor on AC, round 13.
