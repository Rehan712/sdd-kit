---
name: sdd:plan
description: Spec-driven development phase 2. Read an existing spec.md and produce plan.md alongside it, pulling in the relevant stack overlays from ~/.sdd/templates/stack-overlays/ and consulting the matching tech-stack subagent(s). Use when the user types /sdd:plan, says "plan this", "how would we build this", or asks for an implementation plan for a spec that already exists.
---

# /sdd:plan — Produce an implementation plan

Phase 2 of the SDD workflow. Reads an accepted `spec.md`, designs the
implementation, writes `plan.md` next to it.

**Umbrella spec?** (`repos:` in spec.md frontmatter, lives in `~/.sdd/specs/`)
Read `~/.sdd/templates/umbrella-guide.md` §Plan and follow it wherever it
overrides this file.

## Step-by-step

### 1. Locate the active spec

Named slug/NNN → `<project>/.specify/specs/NNN-*/spec.md`, else the hub's
`~/.sdd/specs/NNN-*/`. Otherwise the most recently modified spec dir in the
resolved project (`ls -t <project>/.specify/specs/ | head -1`) — but skip
specs whose STATUS shows `phase: shipped|abandoned`, and confirm with the user
on any ambiguity. Project root via `~/.sdd/scripts/project-detect.sh`.

### 2. Read the inputs

- `STATUS.md` first — phase, settled decisions (don't relitigate), open questions.
- `spec.md`. If its status is still `draft`, confirm with the user the spec is
  final, then `~/.sdd/scripts/spec-status.sh --file spec.md set <dir> status accepted`.
  Any `[NEEDS CLARIFICATION: …]` markers: resolve with the user BEFORE
  designing; remove each as answered and log it in STATUS Decisions.
- `~/.sdd/constitution.md` + `<project>/.specify/constitution.md` (if present).
- Stack tags: `<project>/.specify/stack.yml`, else the project's registry
  entry. Load `~/.sdd/templates/stack-overlays/<tag>.md` for each.
- `~/.sdd/knowledge/*.md` — skim for relevance.
- `~/.sdd/briefs/<repo>.md` when it exists. Freshness first:
  `~/.sdd/scripts/brief-status.sh repo <repo>` — on `stale`/`unknown`, warn
  and suggest `/sdd:onboard --refresh <repo>`; never auto-refresh from here.
  A brief is a starting map — grounding rules still require re-verifying paths.

### 3. Consult stack expert(s)

Pick the expert per stack tag from **`~/.sdd/templates/stack-routing.md`**
(§Planning consultation). Multi-stack work: consult each relevant expert **in
parallel** via the Agent tool — each returns its stack's considerations, file
paths, and risks. Don't bypass them even if you "already know"; the agents
encode lessons the overlay doesn't.

### 4. Explore the codebase

Agent tool, `subagent_type: Explore`: find existing patterns to reuse, code
this change must modify, contracts it must respect. Don't pre-decide — let
exploration inform the design. If `~/.sdd/models.yml` exists, pass
`~/.sdd/scripts/model-policy.sh get explore claude model` as the Agent tool's
`model` param when it prints an alias (opus/sonnet/haiku/fable); otherwise omit.

**Explorers locate; you verify.** Explore agents may run on a cheaper tier —
before a file path, hook point, or "no change needed" claim from a report
becomes part of the design, re-read that code first-hand this session. A
misread inherited into plan.md poisons every downstream phase.

### 5. Draft the plan

Fill `plan.md` from the template — every section, or an explicit "n/a":

1. **Approach** — one paragraph, referencing REQ-###.
2. **Architecture** — components, file paths, what changes where.
3. **Data model** — schemas, migrations.
4. **API / contracts** — new/changed endpoints, event payloads.
5. **Dependencies** — packages, AWS resources, IAM.
6. **Stack overlay notes** — per-tag callouts from overlays + experts.
7. **Risks** — ranked likelihood × impact, each with a mitigation.
8. **Rollout** — flags, deploy order, observability, how each MET-### gets measured.
9. **Out of scope** — what came up but won't ship here.
10. **References** — ADRs, code paths, links.

Name the files, the IAM actions, the metric names. Vague plans produce vague code.

### 6. Reconcile with the spec

If planning revealed the spec is wrong or ambiguous, **stop and fix the spec
first**; tell the user what changed and why. Then resume.

### 7. Update STATUS.md

`phase: plan`, `active_tool: claude`, bump `updated:` (spec-status.sh does the
bump). Append load-bearing architectural calls to the Decisions log with
one-line rationale; refresh Open questions; set Where-things-stand / Next
action → `/sdd:tasks`.

### 8. Hand off

Path to `plan.md`; 3 bullets (approach, biggest risk, deploy strategy); next:
`/sdd:tasks`.

## Grounding rules — non-negotiable

1. Never write a path, ID, or verdict from memory — only from a file read or command run this session.
2. Re-read the exact artifact lines before acting on them.
3. Unknown → ask or write `[NEEDS CLARIFICATION: <question>]`; never guess silently.
4. Paste real command output, never "it worked".
5. Artifacts disagree → stop, reconcile (spec > plan > tasks), say what changed.

## Rules

- **No code in this phase.** Plan only.
- **Reference REQ-### / AC-### everywhere** — every architectural choice traces to a requirement.
- **Honor the constitution**; surface any conflict explicitly.
- **Don't expand scope** — tempting refactors go to "Out of scope".

## Done when

- `plan.md` exists with all template sections completed (or "n/a").
- The user has the path, the summary, and the next step.
- Any spec edits made during planning are saved.
