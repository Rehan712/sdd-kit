# Umbrella specs — the multi-repo playbook

Read on demand: a spec is an **umbrella spec** iff its `spec.md` frontmatter
declares `repos: [a, b, …]`. It lives in the hub (`~/.sdd/specs/NNN-slug/`),
never in a project repo. Single-repo specs never need this file.

**The invariant everything below serves:** the hub spec dir owns the artifacts
(`spec.md`, `plan.md`, `tasks.md`, `STATUS.md`, `notes/`) and is edited
directly — the hub is not a code repo and has no spec branch. Code edits
happen ONLY in a declared repo's own worktree, resolved per task.

Shared mechanics (all phases):

- **Repo resolution:** `~/.sdd/scripts/system-map.sh path <name>` (registry-
  joined). Deps/contracts: `system-map.sh deps|consumers|contracts <name>`.
- **Worktrees:** `spec-worktree.sh --repo <name> <spec-dir>` cuts/reuses one
  repo's worktree (idempotent, prints the path last); `--all-repos` does all,
  one `<name>TAB<path>` line each. Worktree guard before any edit:
  `git -C <wt> rev-parse --abbrev-ref HEAD` must print `spec/NNN-slug`.
- **STATUS:** frontmatter `branch:`/`worktree:` stay `none`; the **Repo
  matrix** table holds per-repo branch/worktree/PR/tasks-done. PR URLs also
  land as `pr_<name>:` frontmatter (spec-pr.sh writes them).
- **Dispatch:** hub phases (plan/tasks/retro) dispatch normally —
  `spec-dispatch.sh` roots the headless run at the hub (which owns the
  artifacts) with declared repos as read-only context. Implement dispatches
  ONE repo slice at a time:
  `spec-dispatch.sh implement <spec-dir> --repo <name> [--task T### | --all]`
  — the run executes only that repo's `[repo:]` tasks; gate and Ship tasks
  are spec-wide and never run in a dispatched slice. Plain `--all` (the
  cross-repo orchestrated run) never dispatches (exit 5) — run it
  interactively, or under `/sdd:go` which always implements locally.
- **Contract-first ordering** (`knowledge/cross-repo-contracts.md`): contract
  changes → infra → provider services → consumer apps; the same order for
  merge and deploy. Other teams' repos are never tasked — the spec records
  `[EXTERNAL: <team/repo> — <what> — needed-by <date>]`, mirrored in STATUS
  blockers; implementation stubs at the agreed contract.

## Plan (/sdd:plan)

- The stack set is the UNION of every declared repo's stacks (each repo's
  `.specify/stack.yml`, else its registry entry).
- Required reading: `~/.sdd/system-map.yml` and `knowledge/cross-repo-contracts.md`.
- **Explore fan-out:** one Explore agent per declared repo, in parallel (one
  message, multiple Agent calls) — each gets its repo path + the spec's ACs
  for that repo; ask for a structured brief (what it owns, entry points,
  contracts provided/consumed, files this feature touches, conventions that
  bite). Then persist: write/update `~/.sdd/briefs/<name>.md` from
  `brief-template.md`, including `**Updated:**` and
  `**Source:** <branch> @ <full-sha>` (`git rev-parse HEAD` of the explored
  checkout — provenance; staleness counts against the BASE branch).
- **plan.md shape:** Architecture organized per repo (one subsection each, so
  /sdd:tasks can tag mechanically). API/contracts is the coordination spine —
  name each changing contract, its source repo, consumers; contract changes
  are the first tasks. Risks must cover half-shipped states (what users see
  when repo A merged and repo B didn't; flag / additive API / dark launch).
  Rollout names the repo-by-repo deploy order.
- If planning reveals the spec scoped the wrong repos, stop and fix the
  spec's `repos:` + Repos-in-scope table first.

## Tasks (/sdd:tasks)

- Every non-gate, non-Ship task carries `[repo:<name>]` after the ID
  (`sdd-analyze.sh` rejects untagged/mis-tagged). Tasks in different repos are
  `[P]` by default; stage ordering still encodes the contract sequence:
  **Contracts → Infra → Providers → Consumers** → Tests/Obs/Docs/Gates/Ship.
- Codegen regeneration is its own task per consumer repo.
- Gates: no per-project resolution — use the hub defaults; both gates run
  ONCE, spec-wide.
- Ship: one PR task per declared repo (`spec-pr.sh --repo <name> <spec-dir>`);
  merge/deploy expectation providers-before-consumers in the rollout task.

## Implement (/sdd:implement)

Pre-flight (replaces the single-repo steps):

1. Read hub `STATUS.md` including the Repo matrix.
2. No single worktree — resolve each task's `[repo:]` worktree lazily:
   `WT="$(~/.sdd/scripts/spec-worktree.sh --repo <name> <spec-dir> | tail -1)"`;
   record branch+worktree in the matrix row the first time. Run the worktree
   guard per repo per session.
3. `sdd-analyze.sh <spec-dir>` (it enforces `[repo:]` tags), then STATUS:
   `phase: implement`, `active_tool:`, bump `updated:`.

Per task: the tagged repo's worktree is the working root; its *Files:* are
relative to that repo; read that repo's stack overlays and
`~/.sdd/briefs/<name>.md`. A change that "also needs a tweak" in a sibling
repo is a NEW task for that repo — never a cross-worktree edit.

Orchestrated (--all): pass the orchestrator the hub spec dir, a repo table
(`name → local path → worktree`, pre-cut via `--all-repos`), and each repo's
stack tags. It routes every task to its `[repo:]` worktree.

Gates: the dossier lists EVERY declared repo's worktree + diff command
(`git -C <wt> diff <that repo's base>...HEAD`, from the Repo matrix), and
instructs the gate to judge the repos TOGETHER — contract compatibility
between the slices is precisely what it must challenge. A gate that reviewed
only one repo's diff has not run.

Ship: one `spec-pr.sh --repo <name> <spec-dir>` per repo (spec-wide gates gate
them all; each URL lands in the matrix + `pr_<name>:`); `phase: review` once
all declared repos have PRs.

## Review (/sdd:review)

`spec-ci.sh` aggregates over every declared repo's PR (worst state wins;
`--repo <name>` narrows). Merge in the plan's rollout order — providers before
consumers — re-probing each remaining PR after every merge. Teardown:
`spec-worktree.sh --remove [--delete-branch] --all-repos <spec-dir>`.
