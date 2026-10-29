# Resuming direct implementation

> **Latest stop: [2026-09-11-pregate-stop.md](2026-09-11-pregate-stop.md) —
> Backend/API/Tests/Observability checkpointed; stopped before Docs at the user's
> request. No fresh AC-016 control or floor, dossier still stale, round 2 still
> unreserved. A local O-002 bypass remains reproducible after T030o7; its runnable
> proof is in [round2-self-attack/README.md](round2-self-attack/README.md).
> Read the new stop point first; "How verification actually decides" below
> remains current.**

Earlier stop: **2026-09-09, T029 accepted — implementation complete, gates open.**
Read [How verification actually decides](#how-verification-actually-decides) before
touching verification-lib.sh; it is the part that is not written down anywhere else
and it cost a session to derive. Older stop points are kept below, newest last.

Run from the existing spec worktree. Read STATUS.md and tasks.md first.
These are invocation helpers, not public kit scripts or fake proof generators.

**Mode, still in force:** direct implementation in the session — no /sdd:implement,
no /sdd:go, no dispatched implementation agents. Only the independent opponent and
reality-check gates get an agent. **Preserve history:** T001–T029 carry authentic
acceptance receipts; stale proof is refreshed by re-running verification, never by
unticking a task or reopening its implementation.

- `bash notes/verification/handoff/verify-task.sh T###`: run exact Verify through spec-run with --from-task --no-tick --summary, then submit the authentic return to spec-gate accept. It stops on failure.
- `bash notes/verification/handoff/return.sh T### CAP-id`: build exact required FM/INV mappings from the current catalog and submit a previously captured, still-current command. The deterministic accept command decides validity. `--prepare` as the third argument writes the return without accepting it.
- `bash notes/verification/handoff/control-t029.sh CAP-id`: perform the deliberately incomplete T029-copy rejection, assert unchanged task digest, then accept the intact return. **This ran for real on 2026-09-09** and rejected on the correct reason (missing FM/INV binding).
- `bash notes/verification/handoff/finish-remaining-macos.sh`: the earlier pipeline for T028/T029. Superseded by the next entry for gate work.
- `bash notes/verification/handoff/finish-pregate-20260910.sh`: **the current pre-gate sequence** — Backend/API/Tests/Observability/Docs checkpoints, the AC-016 control, then a floor. Run this before reserving any round; nothing is warm.
- `bash notes/verification/handoff/run-one-test.sh tests/<suite>.sh <test_fn>...`: run named test functions instead of a whole suite. See the harness note below for why this is necessary.

## How verification actually decides

Derived the hard way on 2026-09-09; none of it is documented in the scripts.

**The input manifest is the whole game.** `vf_snapshot`
(`scripts/verification-lib.sh:1003`) hashes the git index, untracked files,
declared inputs, resolved tool binaries, the harness scripts, the four spec
documents — *and every exported environment variable*. A capture is "current"
only while that digest is unchanged (`vf_capture_check:1202`). Consequences:

- **A different tool or session invalidates every capture** even when the source
  is byte-identical, because `CLAUDE_*`/`CODEX_*` variables differ. The Codex
  receipts (`4562dfc2…`) and the Claude ones (`a16a5388…`) differ in `environment`
  records only. Budget a full Backend re-execution (~68 min) on any switch. Do not
  try to normalize the environment; it is deliberate (spec §"environment identity").
- **A script that assigns a caller-exported name breaks freshness.**
  `spec-evidence.sh` and `spec-ac-coverage.sh` used to do `SPEC="$SPEC_DIR/spec.md"`,
  so a reader following the documented `$SPEC` got "current evidence missing/stale"
  on valid proof. Fixed by suffixing to `SPEC_FILE`. Keep new top-level names
  suffixed — the documented variables are `$SPEC`, `$TASK`, `$STAGE`, `$GATE`.
- **A stray file in the worktree makes its own capture stale.** Returns and reports
  must live under `notes/verification/{returns,reports}/`; those paths are
  bookkeeping-excluded by `vf_bookkeeping_path:963`, a worktree `return.txt` is not.

**What is deliberately excluded** (`vf_bookkeeping_path:963`, `vf_semantic_file:969`):
`notes/captures/*`, `notes/verification/*`, `notes/evidence.md`, `notes/opponent.md`,
`notes/reality-check.md`; in tasks.md the checkbox state and every `*Evidence:*`
line; in STATUS.md **everything except the `## Decisions log` section**. So a tick
is manifest-neutral, and STATUS frontmatter / "Where things stand" / "Handoff note"
/ "Next action" are safe to edit mid-run — but **one Decisions line invalidates a
sealed floor.** Write Decisions before a run, prose after.

**Never edit tracked source while a capture, checkpoint or floor is running.**
`vf_gate_floor:1579` re-snapshots at the end and fails with "floor stale: source
inputs changed during verification".

## Test-harness pitfalls

- `t_run_all` enumerates every `test_*` function in scope. Suites that borrow
  another suite's fixtures (`load_gate_fixtures` in test-gate-contracts.sh sources
  a stripped test-spec-gate.sh) therefore define that suite's tests too — a naive
  driver runs both. Use `run-one-test.sh`.
- Each test runs in its own subshell with a fresh `$SANDBOX`, so `t_fail` inside a
  *nested* subshell is lost. Never write a fixture helper as `name() ( ... )`.
- `$SANDBOX/<name>` collides with `make_verification_git_dir <name>`, which creates
  a project directory of that name. Pick distinct names.
- `run_rc` assigns the global `$OUT` — a documented example that also uses a
  variable named `OUT` will be clobbered between commands.

## Measured timings (macOS, 2026-09-09)

| Work | Time |
|---|---|
| `bash tests/run.sh` | 11–16 min |
| `bash tests/run.sh && shellcheck -S warning -x scripts/*.sh tests/*.sh` | ~13 min |
| One reuse validation (snapshot only, no execution) | ~10 s |
| Backend checkpoint, fresh environment (12 executed / 14 reused) | 68 min |
| Backend/API/Tests/Observability/Docs + floor, warm | ~50 min |

Reuse saves the *execution*, never the fingerprinting — a 27-command all-cache
stage still costs ~5 minutes.

Snapshot cost is now the dominant time sink. An untested optimization draft is
parked at `snapshot-cache-draft.py` (rescued from /tmp, where it would not have
survived a reboot). It is NOT applied and NOT tested — review it before trusting
it, and remember that anything changing `vf_snapshot` changes every digest.

## Where the open findings live

**Superseded on 2026-09-10.** The 2026-09-09 provisional classes in
`../reports/opponent-findings-2026-09-09.md` were fixed as T030o1-T030o6, and
counted opponent round 1 then reopened five of them and added one more. The
authoritative findings are now `../reports/opponent.md` (round 1, CHALLENGED,
digest 1ac95178…), all six fixed as T030o7-T030o11. One round of three is
consumed. The table below is kept only as the original finding-to-function map.
Starting points:

| Finding | Class | Code |
|---|---|---|
| O-001 | return-envelope parsing rejects trailing prose | `vf_return_parse:1293`, consumer `vf_return_check:1317` |
| O-002 | round authorization accepts any line prefix | `vf_round_authorized:1854` |
| O-003 | AC-016 probe accepts any rejection reason | `tests/probe-gate-contract.sh` (62 lines) |
| O-004 | gate-report schema misses required sections/fields | `vf_reports:749`, called from `round --complete` |
| O-005 | config interpolation guard misses `$1`, `$?`, `$$`, … | `vf_config:34` |
| O-006 | `c`/`r` follow-ups prescribed without typed bindings | `skills/sdd-review/SKILL.md:29-46`, validator `verification-lib.sh:631` |

Four of the six are in one shared kernel, so fix them as class sweeps with
negatives, not one-line patches.

## Stop point — 2026-09-09 (T025/T026 accepted; Backend + API checkpointed)

T001–T026 plus T003f1 are accepted. T025 used CAP-25-YLM9sI (`bash
tests/test-gate-contracts.sh`, 14/14 passed, exit 0), accepted return
`0f374e981fae0459e64f6d37160f1481388730ee7863f6b28e48dfddfec3abc7`. T026 reused
the same capture — identical Verify, unchanged source — accepted return
`e6e4eefbd752292e0b7fcd9c7c482916cd5300ffe66ecdd8f84845e99d54f57e`.

What T025/T026 changed beyond the prepared edits is in `../../history.md` under
"T025 / T026 — 2026-09-08": three residual legacy-tick contradictions in
/sdd:review and /sdd:implement, plus the probe's missing
rejection-precedes-acceptance negative (mutation-tested).

**Both stage checkpoints now have COMPLETE receipts** — the first this spec has
produced. Backend CHECKPOINT-Q71sAv (exit 0, executed=12, cache-hits=14, ~90
min) and API CHECKPOINT-S7Zswo (exit 0, executed=0, cache-hits=27, seconds),
both on source c3cfe9ff…. An earlier Backend attempt died mid-run on
`No space left on device`; it produced no receipt and its CAP-26–CAP-32 logs are
an environment failure, not a gate finding. Do not read them as proof either way.

Next is T027. Its AC-019 Linux and macOS/Bash-3.2 evidence needs a working
Docker and free disk: at this stop point ~2.3 GB was free, Docker.raw was 6 GB
actual and still growing, and `docker ps` did not answer. Docker was left
running on purpose — it was recovered earlier without deleting volumes, so
stopping it is the user's call. Stop for an execution route rather than
inventing a platform PASS.

Open defect with no owner yet: `../../../../../scripts/verification-lib.sh:1793`
stamps a checkpoint's `start` and `end` both from `date` at seal time, so a long
run reports start==end. The floor at :1627 is correct. No gate decision depends
on it; it needs a follow-up task or an opponent finding.

Leftovers safe to ignore: three `.checkpoint.*` staging dirs and
`../execute.Z23Kci` from interrupted runs. The verification lock is released.
Leaked `sddkit.*` sandboxes under $TMPDIR were removed. `../dossier/source.diff`
and `source-stat.txt` predate the T002 binding fix, and
`../platforms/linux-final.log` predates T025/T026 — regenerate both before a gate.

T022–T026 are accepted but uncommitted; latest commit is still T021 (0d55c62).
`tests/test-gate-contracts.sh` also holds T027–T029's prepared test code, so the
tree cannot be split into clean per-task commits — ask the user how to group them
rather than writing a commit that mislabels its contents. T029's rejection
control has not run.


## Latest handoff — 2026-09-09, T027 complete

Read [2026-09-09-t027.md](2026-09-09-t027.md) first; it supersedes the earlier stop-point above. T027f1 and T027 are accepted; T028/T029 remain unchecked. Both platforms passed 130/130 plus ShellCheck. Tests checkpoint and gates remain pending; owned Linux executor is stopped. User requested stopping after the current task.
