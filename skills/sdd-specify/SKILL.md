---
name: sdd:specify
description: Spec-driven development phase 1. Interview the user about a feature, then write spec.md to the resolved project's .specify/specs/NNN-slug/ directory using the hub template at ~/.sdd/templates/spec-template.md. Features spanning multiple repos become ONE umbrella spec in the hub's specs/ directory instead (new-spec.sh --multi). Use this skill when the user types /sdd:specify, says "let's spec out X", "write a spec for X", "let's plan X" (and there's no existing spec), or otherwise asks to start a new feature in a spec-driven way.
---

# /sdd:specify — Write a feature specification

You are running the **first phase** of the spec-driven development (SDD) workflow defined in `~/.sdd/` (the spec hub).

## What you produce

A new directory at `<project>/.specify/specs/NNN-<slug>/` containing **`spec.md`** — a feature specification filled in via dialogue with the user. The directory will later receive `plan.md`, `tasks.md`, and notes/.

## Step-by-step

### 1. Resolve the project — and the blast radius

Run `~/.sdd/scripts/project-detect.sh` from the current cwd. The output is the absolute project root.

If it exits non-zero, ask the user which project this spec is for (one of the names in `~/.sdd/registry.yml`) and use that path.

Also read the matching project entry in `registry.yml` to know the `stacks` tags — you'll use these later in `/sdd:plan`.

**Scope check (when `~/.sdd/system-map.yml` exists):** before scaffolding, decide whether this feature lands in ONE repo or several. Read the map (`~/.sdd/scripts/system-map.sh list`, and `deps`/`consumers` for the repos involved) and ask the user which repos the feature touches — `AskUserQuestion` with multiSelect over the plausible candidates. Consumers of a contract the feature changes are candidates by construction.

- **One repo** → continue with the normal flow below.
- **Two or more repos you own** → this is an **umbrella spec**. It lives in the hub (`~/.sdd/specs/`), not in any one project — step 3 uses `--multi`.
- **Repos with role `external`** (another team's) are never in scope for tasks. They become `[EXTERNAL: <team/repo> — <what you need> — needed-by <date>]` markers in §7 Constraints — collect the details during the interview.

Also skim `~/.sdd/briefs/<repo>.md` for each repo in scope, if present — standing context that sharpens the interview questions.

### 2. Read the constitutions

Load both:

- `~/.sdd/constitution.md` (cross-project)
- `<project>/.specify/constitution.md` if it exists (project-specific overrides)

These shape acceptance criteria. If a requirement violates the constitution, flag it during the interview rather than silently allowing it.

### 3. Bootstrap the spec directory

Single-repo spec: run `~/.sdd/scripts/new-spec.sh --project "<project-root>" "<short title>"`, where `<project-root>` is the **absolute path** resolved in step 1 (the value `project-detect.sh` printed, or the registry `path:` for the project you picked) — **not** the bare project name. `--project` is a filesystem path: passing a name creates a nested `<name>/.specify/specs/001-…` relative to cwd instead of finding the project's real specs dir.

Umbrella spec: run `~/.sdd/scripts/new-spec.sh --multi --repos <name,name,…> "<short title>"` with the registry/system-map **names** (not paths) chosen in step 1. The script validates each name, rejects `external` repos, and scaffolds into `~/.sdd/specs/NNN-slug/` with `repos:` frontmatter, a "Repos in scope" section in spec.md, and a per-repo matrix in STATUS.md.

The script:

- Computes the next `NNN`.
- Slugifies the title.
- Copies `spec-template.md`, `plan-template.md`, `tasks-template.md`, and `status-template.md` into the new directory with placeholders substituted.
- Prints the new directory path.

Capture that path; it's where you'll write. The directory now also contains `STATUS.md` — the spec's living cross-tool memory (read by Claude/Codex/Copilot on entry, updated on exit).

**Sanity-check the printed path** before writing: it must be `<project-root>/.specify/specs/NNN-slug` with `NNN` continuing the project's existing sequence. If you see `001` in a project that already has specs (or the path is relative / nested under another spec dir), you passed a name instead of an absolute path — `rm -rf` the stray dir and re-run with `<project-root>`.

### 4. Interview the user

Ask focused questions to fill `spec.md`. Use `AskUserQuestion` for multiple-choice decisions; ask free-form questions one at a time when the answer is open-ended.

Drive toward filling these sections in order, but don't be a robot — if the user already said something, use it.

1. **Problem** — what's painful today, from the user's perspective. Insist on a concrete example.
2. **Goals (REQ-###)** — testable bullets. Each one gets a REQ-### id.
3. **Non-goals** — explicit. Ask "what's *not* in scope?" if not volunteered.
4. **Success metrics (MET-###)** — how we'll know it worked *after* ship: target +
   measurement source (metric/dashboard/query name). Ask "how would you check, two
   weeks post-launch, that this was worth building?" For internal/refactor work,
   "n/a because ..." is an acceptable answer — silence is not.
5. **User stories** — for each role. Include unhappy paths.
6. **Acceptance criteria (AC-###)** — observable, testable. Reference REQ-###.
   *Umbrella specs:* tag each AC with the repo(s) whose behavior proves it — `[repo:<name>]`. An AC no repo owns is unprovable; an AC every repo owns is several ACs in a trench coat.
7. **Constraints (CON-###)** — what we can't change.
   *Cross-team dependencies:* for each thing another team must ship, write `[EXTERNAL: <team/repo> — <what you need> — needed-by <date>]` and get the contact + realistic date from the user. These are tracked blockers, not tasks — `sdd-analyze.sh` checks they're mirrored in STATUS, and implementation stubs at the agreed contract until they land.
8. **Open questions** — anything that blocks `/sdd:plan`.

If the user says "you decide", make a reasonable call and record it twice: in the STATUS Decisions log (so it isn't re-litigated) and as an open question (so they can override). If you *can't* decide — a missing domain fact, a business rule only they know — write `[NEEDS CLARIFICATION: <the question>]` inline where the answer belongs. Never fill the gap with an invented answer; the marker blocks `/sdd:tasks` until resolved, which is the point.

### 5. Write spec.md

Use the structure from the template (already copied). Replace the placeholders with the interview answers. Keep it concise — 200-400 lines is healthy; 800+ is a smell that you should split.

Every AC-### must name the command or observable artifact that will verify it (test, curl, screenshot, metric). An AC that can't be checked by `/sdd:implement` or the reality-check gate is an opinion, not a criterion — rewrite it until it's checkable.

Frontmatter:

```yaml
spec_id: NNN-slug
title: <one-line title>
status: draft
created: <today>
updated: <today>
owners: [<user's github handle if known>]
project: <project name from registry>   # umbrella specs: `hub`, plus a `repos: [a, b, c]` line
```

Umbrella specs: `new-spec.sh --multi` already wrote `project: hub` and `repos:` — don't remove them; every downstream tool (worktree/PR scripts, analyzer, implement) keys off `repos:`. Fill in the "Repos in scope" table it added (why each repo is touched).

### 6. Initialize STATUS.md

`new-spec.sh` already scaffolded `STATUS.md` (phase `specify`). Fill it in:

- **Where things stand** — one line: spec drafted, awaiting plan.
- `active_tool: claude`.
- **Decisions log** — add an entry for any "you decide" call you made during the interview. For umbrella specs, log the repo-scoping decision (which repos are in, which were considered and excluded, and why).
- **Open questions / blockers** — copy the spec's blocking open questions here. Every `[EXTERNAL: …]` marker from the spec gets a blocker line here too (the analyzer checks the mirror).
- **Next action** — `/sdd:plan`.
- Bump `updated:`.

This file is the handoff record; keep it current so Codex or Copilot can pick the spec up cold.

### 7. Hand off

Tell the user:

- The path to the new `spec.md`.
- A 2-line summary of what the spec captures.
- Suggested next command: `/sdd:plan`.

## Grounding rules — non-negotiable

1. **Never write a path, ID, or verdict from memory.** Every file path, spec/task/AC/REQ id, and status value you use must come from a file you read or a command you ran *in this session*. If you can't point at its source, resolve it before using it.
2. **Quote before you act.** Before acting on an artifact, re-read the relevant lines and satisfy exactly what they say — not your recollection of them.
3. **Unknown → ask or mark, never invent.** If the user or the artifacts don't answer a question, ask — or write `[NEEDS CLARIFICATION: <question>]` into the artifact. A silent guess is the failure mode this workflow exists to prevent.
4. **Paste outputs, don't paraphrase.** Report any script/command result as the actual output lines, trimmed — never a summary like "it worked".
5. **On contradiction, stop.** If artifacts disagree with each other or with what the user said, don't silently pick one: surface it, reconcile (spec wins over plan, plan over tasks), and say what you changed.

## Rules

- **Never write code in this phase.** Even if the design feels obvious, defer to `/sdd:plan`.
- **Never skip the interview.** If the user gives a one-liner, ask follow-ups — the spec's quality determines everything downstream.
- **Use existing utilities.** Always go through `scripts/project-detect.sh` and `scripts/new-spec.sh`. Don't hand-roll directory creation.
- **Bootstrap new projects on first use.** If the resolved project lacks `.specify/`, create the minimal scaffold (`.specify/specs/` plus a thin `.specify/stack.yml` naming the project's stack tags, and optionally `base_branch:`) and add the project to `~/.sdd/registry.yml`.
- **Umbrella scope is a spec decision, not a guess.** If you're unsure whether a repo is in scope, ask — adding a repo later means re-planning; a repo in `repos:` with no work fails the analyzer. A repo the feature merely *calls* (unchanged) is not in scope; a repo whose code must change is.
- **Keep the system map honest.** If the interview reveals a repo or dependency `~/.sdd/system-map.yml` doesn't know about, add/update the entry (and run `~/.sdd/scripts/system-map.sh check`) as part of this phase.

## Done when

- `<project>/.specify/specs/NNN-<slug>/spec.md` exists, with all template sections filled in (or explicitly marked "n/a").
- Every remaining `[NEEDS CLARIFICATION]` marker is mirrored in Open questions — the user knows these block `/sdd:tasks`.
- STATUS.md reflects the interview (decisions logged, phase `specify`, next action `/sdd:plan`).
- The user has been told the path and the next step.
