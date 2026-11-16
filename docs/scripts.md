# Scripts

All in `scripts/` (stable path: `~/.sdd/scripts/`):

| Script | What it does |
|---|---|
| `setup.sh` | install / repair everything on this machine (`--no-cli`, `--no-wizard`, `--relink`) |
| `configure-models.sh` | wizard for the model policy (`models.yml`) — which model + effort runs each SDD role, per CLI |
| `model-policy.sh` | query/validate/edit the policy: `get <role> <cli> <field>`, `dispatch [<role>]`, `show`, `check`; edits via `update <role> <model> [<effort>]`, `set`/`unset` `tier`\|`role`\|`dispatch` — validated first, then auto re-stamps copies + adapters; `--project <dir>` overlays that project's `.specify/models.yml` on any read, `overrides` lists what it remaps |
| `project-routing.sh` | a project's own skills and agents (`.specify/routing.md`): `check <dir>` validates the table and that every name resolves; `match <dir> <plan\|implement\|review> [<path>… \| --task <spec-dir> T### \| --diff <base>]` prints the targets for those paths |
| `apply-models.sh` | stamp the policy into generated skill/agent copies under `build/` (Claude homes link there) |
| `project-detect.sh` | cwd → registered project root (worktree-aware) |
| `system-map.sh <cmd>` | query/validate the team topology: `list`, `show`, `path`, `deps`, `consumers`, `contracts`, `check` |
| `brief-status.sh <cmd>` | deterministic repo-brief freshness: `list` (TSV per repo), `check` (exit 1 on missing/stale), `repo <name>`; `--threshold N` (default 20), `--fetch` to opt into network |
| `new-spec.sh "<title>"` | scaffold `.specify/specs/NNN-slug/` from templates; `--multi --repos a,b,c` scaffolds an umbrella spec in the hub `specs/` |
| `spec-worktree.sh <spec-dir>` | cut/reuse branch `spec/NNN-slug` + sibling worktree from the project's base branch; `--remove [--delete-branch]` tears it down post-merge; umbrella: `--repo <name>` / `--all-repos` |
| `spec-status.sh` | machine-side state mutations: `get`/`set`/`show` on STATUS.md frontmatter (enum-validated, bumps `updated:`); `--file spec.md` targets other artifacts |
| `spec-task.sh` | tick tasks deterministically: `list`, `show`, `start`, `done T### --evidence "…"` (tick + evidence one atomic edit — refuses evidence-less ticks), `undo` |
| `spec-graph.sh <cmd> <spec-dir>` | the task dependency graph, computed instead of recalled: `check` (dangling/circular `Depends on:`, duplicate ids), `next` (the batch that is safe to start now — stage order, `[P]` siblings, follow-ups first, file collisions kept apart, a gate alone), `waves` (every remaining batch) |
| `spec-loop.sh <spec-dir>` | the outer loop for implement: one fresh headless session per task in `spec-graph.sh` order via `spec-dispatch.sh`; stops at the first Ship task, on two sessions without progress, at `--max-iterations` (default 30), or when the dispatcher refuses/parks; `--to <cli>`, `--dry-run` |
| `spec-run.sh <spec-dir> T### -- <cmd>` | run an acceptance check FOR REAL: executes the command, captures stdout+exit+hash into `notes/evidence.md`, and ticks the box from that run only on exit 0 — evidence becomes a record, not a typed claim (`--key` to pick the quoted line, `--no-tick` to capture only) |
| `sdd-analyze.sh <spec-dir>` | deterministic spec↔plan↔tasks lint: AC coverage (implementation tasks only — gate refs don't count), ref integrity, acceptance checks, evidence on `[x]` tasks, gates present, no unresolved `[NEEDS CLARIFICATION]` markers; umbrella: `[repo:]` tag integrity + `[EXTERNAL:]` mirroring |
| `spec-ac-coverage.sh <spec-dir>` | AC coverage at the CODE layer (gate-time): greps the repo's test files for each `AC-###`, fails any AC no test names — the deterministic floor beneath the reality-check gate (`--root` per repo, `--tests` for extra globs) |
| `spec-evidence.sh <spec-dir>` | evidence integrity (gate-time): every `[x]` box's `*Evidence:*` must trace to a real `notes/evidence.md` capture block or an on-disk artifact — catches fabricated pointers, missing screenshots, and manual/post-deploy ACs with no owner + check-back date |
| `spec-pr.sh <spec-dir>` | push + open PR; **refuses unless both gates passed** (`--force` only with `--draft`); writes `pr:` + `phase: review` back into STATUS; umbrella: `--repo <name>`, once per repo |
| `spec-ci.sh <cmd>` | the CI watcher: `check`/`watch`/`logs` — PR checks + review + mergeability via `gh`, aggregate written to STATUS `ci:`, distinct exit codes (0 green / 10 pending / 20 red / 30 changes-requested / 40 conflicts); umbrella-aware |
| `spec-dispatch.sh <role> <spec-dir>` | run one phase on ANOTHER CLI/provider headlessly (models.yml `dispatch:` map or `--to`): right working root + model, output captured to `notes/`, artifacts verified on return; `--task T###`/`--all` for implement, umbrella implement takes `--repo <name>` (one slice per run), `--dry-run` prints the command |
| `sdd-status.sh` | dashboard of every spec in every project + hub umbrella specs (worktree-aware; `--open`, `--phase`, `--project`, `--tsv` for machines) |
| `companions.sh` | which official skills (ponytail v5, `aws-core`, Stripe, Next.js, `ui-ux-pro-max`) each Claude/Codex home has, with the install command for the missing ones; `--tsv`; exit 1 when ponytail v5 is absent |
| `scout-guard.sh` | the read-only scout's Bash backstop — a `PreToolUse` hook (wired in `agents/sdd-scout.md`) that refuses the common writes (git writes, kit state scripts, file mutation, redirects to a file, installs, deploys); it judges only the command, so a search for those words still runs. A backstop, not a sandbox |
| `spec-brief.sh <spec-dir> T###` | write a task's implementation brief from the artifacts — the task block, the REQ/AC text and the plan sections and FM/INV rows its *Refs:* name, verbatim — into `notes/verification/briefs/T###.md`; the invoker hands the implementer the path instead of retyping the plan (`--stdout` to print) |
| `sync.sh` | verify/repair the per-item symlinks into Claude homes (`--check`); prunes stale links; `--remove` uninstalls them |
| `build-adapters.sh` | regenerate the Codex, Copilot, Cursor and Antigravity adapters from the skills |
| `sdd-doctor.sh` | validate the kit, home wiring, adapters, system map, and any project's `.specify/` layout — including its optional `models.yml` overlay and `routing.md` (`--all`, `--hub-only`) |

(`lib.sh` is the shared parsing library the others source — fence-bound
frontmatter reads/writes, YAML lists in inline or block form, registry
entries with `~` expansion. All scripts honor `NO_COLOR` / non-TTY output.)

Deterministic checks run as scripts; model judgment is reserved for design and
adversarial review. That split is a design principle (constitution §10).

## Testing the kit itself

The deterministic layer is only trustworthy if it's tested. `tests/` holds the
kit's own suite — same zero-dependency floor as the scripts (bash 3.2 + BSD
tools + git):

```bash
tests/run.sh              # every tests/test-*.sh suite (slow: ~30+ min for all of them)
tests/run.sh task         # only files whose name contains "task"
bash tests/shellcheck.sh  # ShellCheck over the enumerated scripts/*.sh and tests/*.sh, no rc files, SHELLCHECK_OPTS unset
```

Both commands are reuse-checked, so each reads only what the input identity
hashes: the suites and scripts git enumerates, never an ignored local file or
configuration outside the repository. They therefore need a Git worktree root,
such as a clone of the kit: they list what they run through the same git
enumeration the identity uses, and outside a worktree they stop with
"cannot enumerate the kit" rather than guess.

CI runs both on Linux and macOS, plus a run with `bash` shimmed to `/bin/bash`
3.2 so the compatibility claim is enforced, not assumed. Touching a script?
Add the failure mode you just fixed as a test.
