# Reality Check — 002-usage-limit-handling-for-dispatched-runs

**Date:** 2026-07-20
**Verdict:** READY
**Agent:** reality-check (hub default)

## Summary

All 11 ACs were re-verified by re-running the evidence, not by trusting the
recorded claims: `tests/run.sh limits` (25/25), `tests/run.sh model-policy`
(8/8), the full suite (12 suites, exit 0), `shellcheck -S warning -x
scripts/*.sh tests/*.sh` (clean), every classifier fixture re-classified
directly via `scripts/usage-limit.sh` (15 limit fixtures correct kind/reset; 4
ordinary fixtures x 3 CLIs all `none`), plus a fresh sandboxed park proving the
unparseable-reset `now+backoff` arithmetic that no suite assertion pins.
`spec-ac-coverage.sh` (all 11 ACs bound), `spec-evidence.sh` (12 ticked tasks
sound), and `sdd-analyze.sh` (consistent) all pass. The opponent's 6 fixed
findings (T013o1–o6) are covered by named tests I re-ran green.

## AC matrix

| AC | Criterion | Evidence (re-run 2026-07-20) | Verdict |
|----|-----------|------------------------------|---------|
| AC-001 | All-provider limit fixtures classify with correct kind; ≥4 ordinary-failure fixtures (incl. one mentioning "limit") classify no-limit | Re-ran classifier directly on all 15 limit fixtures (pipe-epoch→short/1749924000; Claude weekly/Opus incl. minute-less→long; Codex kind-per-horizon; Copilot allowance/quota→long, burst→short) and all 4 ordinary fixtures x 3 CLIs → `none` exit 1. Suite pins exact tuples: tests/test-usage-limits.sh:18-59. `tests/run.sh limits` 25/25 | PASS |
| AC-002 | Pipe-epoch exact; clock → future timestamp; unparseable → empty + caller applies backoff | Exact-epoch asserts tests/test-usage-limits.sh:20-49; `codex-unparseable` → `limit\tunknown\t<empty>` (re-run, exit 0); dispatch feeds `--backoff-minutes` from policy (scripts/spec-dispatch.sh:418-426); direct probe: park w/o reset, backoff=2, jitter=0 → `run_at_epoch = now+120`, one scheduler `add` | PASS |
| AC-003 | No `on_limit:` → exit 7 (not 6), prints kind/reset + copy-pasteable park/`--to` commands, registers nothing | test_AC_003_and_AC_007 (tests/test-usage-limits.sh:263-299): exit 7 asserted, `manual park:` + `spec-resume.sh park` + `--to claude`/`--to copilot` + shell-escaped argv asserted, seam log empty (`[[ ! -s $DISPATCH_LOG ]]`); ordinary failure keeps exit 6. Manual `--kind unknown` command verified accepted by spec-resume.sh (direct run) | PASS |
| AC-004 | `short: park` → unit with verbatim argv, exactly one scheduler entry at parsed reset (or now+backoff), STATUS via spec-status | tests/test-usage-limits.sh:397-448: `cmp` byte-compare of argv.nul/cwd.nul (spaces + `;` punctuation, cwd with spaces), `reset==run_at` at zero jitter, add-count==1, jobs==1, `parked resume unit <id>` in STATUS.md; now+backoff branch verified by direct probe (above) | PASS |
| AC-005 | `run` replays verbatim; success removes unit+entry; repeat limit re-parks; retry cap halts, unit failed; list/cancel | tests/test-usage-limits.sh:678-706 (adversarial argv incl. quote/glob/empty/newline byte-exact, remove-before-replay, unit removed, STATUS success event); :840-950 (generic failure → `state failed`; list/cancel reconcile; nested exit-7 re-park stops at three, no job left). o2/o3/o4/o5 lock-and-PATH recovery tests re-ran green | PASS |
| AC-006 | `long: delegate` → ordered ready fallback, limited CLI skipped, same verification; exhausted → park; failover in STATUS decisions | tests/test-usage-limits.sh:328-387: `Fallback skipped: codex (already attempted)`, unready claude skipped with reason, copilot selected via unchanged plan verifier (`plan.md updated:`), STATUS asserts `delegated role=plan kind=long from=codex to=copilot reset=`; 3-attempt cap + `resume park` on exhaustion; slice-scoped classification | PASS |
| AC-007 | Codex branch tees output to `$CAP`; Codex limit classifies | Same test: aggregate + per-attempt captures written, stdout+stderr present, `cmp -s` aggregate==attempt, classification after true exit 42 (`cli=codex kind=long`) | PASS |
| AC-008 | `model-policy.sh check` accepts valid block; rejects unknown action/CLI/backoff naming offender; getter defaults; set/unset round-trip | `tests/run.sh model-policy` 8/8 re-run; rejection messages name offenders (e.g. `unknown on_limit key`, `duplicate on_limit fallback CLI '<cli>'`, `invalid on_limit backoff_minutes '<v>'` — scripts/model-policy.sh:231-262); canonical round-trip asserted (tests/test-model-policy.sh:97-112) | PASS |
| AC-009 | Doctor flags invalid block, missing/adapter-less fallback, pending units, both orphan classes | tests/test-usage-limits.sh:952-999: `on_limit: long action 'launch'` named; fallback unavailable reasons (`missing plan adapter`, `binary not on PATH`); pending/failed units; unit-without-job and job-without-unit orphans; reconciliation without models.yml | PASS |
| AC-010 | README + models.example.yml + knowledge note exist and name the parser's exact keys | Grep-verified myself: `short`/`long`/`fallback`/`backoff_minutes` present in all three docs and in parser (scripts/model-policy.sh:231-232); example block commented out (models.example.yml:129-133); knowledge note has provenance, drift caveat, interactive recipe. test_AC_010 (tests/test-usage-limits.sh:1003-1026) asserts parity against `require_limit_key()` | PASS |
| AC-011 | shellcheck -S warning clean, executable bits, full suite green | Re-ran `shellcheck -S warning -x scripts/*.sh tests/*.sh` → exit 0; full `tests/run.sh` → exit 0 (12 suites, incl. test_AC_011_every_kit_script_is_executable) | PASS |

## Constitution / non-goals check

- **CON-001 (bash 3.2 + BSD, no deps):** suite runs on macOS BSD userland; `bash -n` asserted; scheduler behind `SDD_RESUME_SCHEDULER` seam — my probe never touched real launchd/cron. PASS
- **CON-002 (inert without opt-in):** AC-003 tests assert empty seam log for absent policy and explicit `fail`; example block commented out. PASS
- **CON-003 (byte-identical replay, no new grant):** NUL-record `cmp` assertions; opponent Round 5 verified only PATH travels to the replay. PASS
- **CON-004 (bounded, never hot-loop):** `kind=unknown` takes the side-effect-free manual path even with policy configured (scripts/spec-dispatch.sh:465); retry cap of 3 enforced with unit marked failed and no residual job. PASS
- **Non-goal (gates/review untouched):** diff touches only dispatch/resume/scheduler/doctor/policy/docs/tests; role guard still restricts dispatch to plan|tasks|implement|retro (scripts/spec-dispatch.sh:95-99). PASS
- **CON-005 (repo parity):** post-merge concern, owned by T016. Deferred to Ship.

## Claim-vs-evidence gaps

None gating. All 12 ticked tasks trace to real captures (`spec-evidence.sh` sound); the final capture (25/25, sha256:33cb85bff8b7) reproduces exactly on re-run.

## Out-of-scope observations (non-gating)

1. No suite assertion numerically pins `run_at == now + backoff*60` for the reset-less park (scripts/spec-resume.sh:175). I verified it by direct run; a one-line assertion in the park test would lock it permanently. Polish, not a gap.
2. AC-001's "generic crash" ordinary-fixture slot is filled by the generic request-failure fixture that mentions "limit" (tests/fixtures/usage-limits/ordinary-limit-word.txt); corpus purpose (MET-002) is proven. A literal crash-trace fixture would be a nice extra.
3. STATUS.md narrative sections ("Where things stand", "Open questions", "Next action") still describe the Round-3 arbitration state, contradicting the frontmatter's `opponent: CLEARED (Round 5)`. Refresh before the PR (T015 hygiene).
4. Opponent's carried-over minor list (past-epoch launchd floor, powered-off-night caveat, `flatten` inline-comment on `on_limit:`, `active_tool` after delegation) remains optional polish — candidates for the retro.

## Deferred to post-deploy

- **MET-001** (next real usage-limit event ends in auto-resume/delegation): observable only at a real limit event. Pre-deploy half is fully evidenced (classifier + park + delegate paths); post-deploy observation is explicitly owned by T016 (records MET-001 owner + check-back in STATUS) and T017 (retro records the result). Ship stage inherits this.

## Re-run conditions

Re-invoke this agent if any implementation file under `scripts/` or `tests/` changes on this branch before merge, or if T015/T016 surface CI failures that require code changes.
