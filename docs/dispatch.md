# Dispatch, loops and usage limits

## Cross-CLI dispatch (different providers per phase)

Model tiering picks the model *within* whichever CLI you're typing in. The
optional **`dispatch:`** map in `models.yml` goes one step further: it names
the CLI that should *run* a phase, so one machine can plan on Claude Code
(opus), write tasks on Codex, and implement on Copilot:

```yaml
dispatch:
  tasks: codex
  implement: copilot
```

When a phase skill sees its role mapped to a different CLI, it offers
**`scripts/spec-dispatch.sh <role> <spec-dir>`** — the one dispatcher. It runs
the target CLI headlessly (`codex exec` inside its workspace-write sandbox /
`copilot -p --agent sdd-<phase>` / `claude -p`) with the phase's model from
the same policy, in the right working root (for implement it pre-cuts the
spec worktree and runs the guard first), captures the final message into the
spec's `notes/`, flips `active_tool:` in STATUS.md, and **verifies the
artifacts on return** with the kit's deterministic checkers (`sdd-analyze.sh`
for tasks, plus `spec-evidence.sh` for implement). Artifacts are the
interface — a foreign model's output passes the same gates as anyone else's.

Boundaries, on purpose: `specify` is never dispatchable (it's an interview),
`review` is never dispatchable (merge decisions are interactive), and umbrella
specs dispatch their hub phases (plan/tasks/retro, rooted at the hub) plus
one-repo implement slices (`--repo <name>`) — never the cross-repo
orchestrated `--all`, which stays interactive. A dispatched run is
non-interactive by contract — the prompt forbids asking questions; unknowns become
`[NEEDS CLARIFICATION]` markers and the run stops cleanly. **Single-provider
setups: omit `dispatch:` entirely — nothing changes.** Each mapped CLI must be
installed and authenticated; `sdd-doctor.sh` and `model-policy.sh check` flag
mappings this machine can't honor. The run uses the target CLI's home from the
caller's environment (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, else that CLI's
default) and prints it — with several accounts, export the one you mean. The
example policy ships no active `dispatch:` map, and the Codex/Copilot adapters
keep a session on its own provider: "follow the model policy" there means that
CLI's models, and another provider is reached only through this script.

## Graph and loop (control flow lives in scripts)

The two decisions a long run gets wrong when a model makes them from memory
are scripted:

- **What may start now** — `spec-graph.sh next <spec-dir>` derives the
  dependency graph from `tasks.md` (stage order, written order, `[P]`,
  `Depends on:`, open follow-ups) and prints the one batch whose dependencies
  are all `[x]` and whose *Files:* cannot collide. The orchestrator dispatches
  exactly those rows; `sdd-analyze.sh` fails a dangling or circular
  dependency before implementation starts.
- **When to stop** — `spec-loop.sh <spec-dir>` runs implement as a loop of
  fresh sessions, one task each, instead of one session that carries every
  finished task in its context. State is on disk (`tasks.md`, STATUS, the
  spec branch), so a killed loop resumes by being run again. It stops at the
  first Ship task (the PR stays yours), after two sessions that tick nothing
  and open nothing (exit 1), at `--max-iterations` (exit 8), or when the
  dispatcher refuses or parks the run. It needs a CLI to dispatch to: the
  `dispatch:` map or `--to <cli>` (the CLI you are on works too). Gate rounds
  stay capped by `spec-gate.sh`; umbrella specs stay interactive.

## When a provider hits its usage limit

Usage-limit recovery applies only to **dispatched** runs. It is off by default:
when `models.yml` has no `on_limit:` block, the dispatcher reports the
classified limit and exits without scheduling, retrying, or switching
providers. Add an explicit policy only when those automatic actions are wanted:

```yaml
on_limit:
  short: park
  long: delegate
  fallback: [claude, copilot]
  backoff_minutes: 60
```

The parser accepts exactly the `short`, `long`, `fallback`, and
`backoff_minutes` keys. `short` and `long` accept `park`, `delegate`, or
`fail`; a present block defaults to `short: park`, `long: delegate`, an empty
`fallback`, and `backoff_minutes: 60`. A short limit is automatically parked
for resume. For a long limit with `delegate`, the dispatcher tries ready fallback
CLIs in `fallback` order (never the provider that just limited); if none is
ready, it parks instead. Remove `on_limit:` to stop future automatic actions.

For manual recovery, use the copy-pasteable park or `--to` command printed by
the limit report. Inspect existing parked work with
`scripts/spec-resume.sh list`, and cancel a unit you no longer want resumed
with `scripts/spec-resume.sh cancel <unit-id>`. Existing units remain until
they resume successfully or are cancelled. Interactive sessions cannot recover
automatically after their CLI turn ends; follow the manual recipe in
[`knowledge/usage-limit-handling.md`](https://github.com/Rehan712/sdd-kit/blob/main/knowledge/usage-limit-handling.md).
