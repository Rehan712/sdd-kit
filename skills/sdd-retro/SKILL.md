---
name: sdd:retro
description: Spec-driven development phase 5. After a spec ships, harvest what the gates and the implementation actually taught us — write notes/retro.md in the spec dir, file cross-project lessons into the hub knowledge/, and propose stack-overlay or constitution amendments. Use when the user types /sdd:retro, says "run the retro", "harvest the lessons", or when the Ship stage's retro task comes up in /sdd:implement.
---

# /sdd:retro — Harvest lessons after ship

Phase 5 of the SDD workflow — the feedback loop. Specs generate hard evidence about
what we get wrong (opponent rounds, reality-check gaps, security findings, reopened
tasks). This skill turns that evidence into durable improvements: hub knowledge,
overlay amendments, constitution proposals. Without it, every spec relearns the
same lessons.

**Dispatched phase?** If `~/.sdd/scripts/model-policy.sh dispatch retro`
prints a CLI other than the one you are running on, offer
`bash ~/.sdd/scripts/spec-dispatch.sh retro <spec-dir>` (headless run there;
checks `notes/retro.md` landed on return; umbrella specs dispatch too — the
run is rooted at the hub with declared repos as read-only context) and run
locally only if the user declines. Prints nothing → run here as normal.

## Step-by-step

### 1. Locate the spec

Same resolution rules as `/sdd:plan`: explicit slug or NNN → that spec; otherwise the
most recently modified spec dir in the resolved project. The spec should be `shipped`
(or at least `review` with both gates passed) — if it isn't, ask before proceeding.

### 2. Read the evidence

From the spec dir (worktree copy if STATUS names one, else the main checkout):

- `STATUS.md` — decisions log, gate verdict history, handoff notes.
- `notes/opponent.md` — every round: what was CHALLENGED, what held up.
- `notes/reality-check.md` — what lacked evidence, what was demanded.
- `notes/history.md` — rotated session detail, if present.
- `tasks.md` — count the follow-up tasks (`T###<class><n>`: `o` opponent, `a`
  reality-check, `s` security, `c` CI, `r` review feedback).
  Each one is a defect the original pass missed; the class tells you which gate caught it.
  The *Evidence:* lines are the per-task acceptance record — a task whose evidence was
  weak or absent at gate time is itself a process finding.
- `spec.md` — the Success metrics (MET-###): can any be measured yet?

### 3. Distill lessons — four buckets

For each defect/finding, ask: **what would have prevented this, and where does that
prevention live?** Sort into:

1. **Stack-specific** → an amendment to `~/.sdd/templates/stack-overlays/<tag>.md` (e.g.
   "a package outside CI silently breaks the build — exclude non-src dirs or add it to CI").
2. **Cross-project process** → an entry in the kit `~/.sdd/knowledge/` (existing file if
   topical, else a new `knowledge/<topic>.md`), dated, linking the spec. Coordination
   defects between repos (contract drift, merge-order breakage, a stubbed [EXTERNAL]
   that shipped as if integrated) go to `knowledge/cross-repo-contracts.md`.
3. **Project-local** → a proposed addition to `<project>/.specify/constitution.md`.
4. **Repo-specific facts** (umbrella specs) → the repo's `~/.sdd/briefs/<name>.md`:
   refresh the brief of EVERY repo this spec touched — entry points that moved, a new
   contract, a gotcha the gates surfaced. Bump its `Updated:` line with this spec's slug
   AND its `**Source:** <branch> @ <full-sha>` line to the repo's current HEAD (that line
   is what `brief-status.sh` counts drift against — a refresh that skips it leaves the
   brief reading as stale). Stale briefs poison the next spec's planning; this step is
   what keeps them alive.

A lesson must be **generalizable**: "the CORS allowlist missed `mark-read`" is a
changelog line, not a lesson. "Fail-closed allowlists need a dedicated test enumerating
every public route, or dead routes get misclassified" is a lesson.

Also capture **process lessons**: a stage that produced many follow-ups, an estimate
that blew up (task count at tasks-time vs. final), a gate that had to run 3+ rounds —
and what upstream change (spec question, plan section, task granularity) would fix it.

### 4. Write `notes/retro.md`

From `~/.sdd/templates/retro-template.md` — defect table, lessons filed,
MET-### check, keep-doing items. Also read `notes/ci.md` if the PR needed CI
triage — recurring CI failure classes are overlay material.

### 5. Apply the durable edits

- **Hub `knowledge/` entries and overlay amendments: apply directly.** Keep each
  addition short (3–8 lines), dated, with a `(learned: <project>/NNN-slug)` pointer.
  Don't duplicate — if the file already states the lesson, strengthen it instead.
- **Constitution changes (hub or project): propose only.** Quote the exact diff in
  your summary; the owner applies or rejects.

### 6. Update STATUS.md

- `retro: done (<date>)`, bump `updated:`.
- One line in **Where things stand**: retro done, N lessons filed.

### 7. Hand off

Tell the user: the path to `notes/retro.md`, the lessons filed (and where), any
proposed-but-not-applied constitution changes, and any MET-### that needs a
check-back date.

## Grounding rules — non-negotiable

1. Never cite a finding, gate round, or task id from memory — only from a file read this session.
2. Lessons quote the gate report or follow-up task they came from.
3. Evidence doesn't say why a defect happened → "cause unclear", never a fabricated narrative.
4. MET-### checks report the actual query/dashboard value or "not yet measurable, check <date>" — and that check-back date goes into the spec's STATUS Next action so it doesn't fall on the floor.
5. STATUS, notes, and tasks.md disagree → the notes files are primary; reconcile and flag the drift.

## Rules

- **No code changes.** The retro observes; it doesn't fix. A latent bug found during
  retro becomes a new task/spec, not a stealth edit.
- **Evidence over memory.** Every lesson cites a gate round, finding, or follow-up
  task id. If you can't cite it, don't file it.
- **Lessons are generalizable or they're not filed.** The bar: would this line have
  changed how a *different* spec in a *different* project was built?
- **Keep the hub lean.** One knowledge entry per concept. Amend, don't append
  duplicates. A knowledge/ file past ~150 lines needs splitting, not more bullets.
- **Don't grade people.** The retro is about the system (spec quality, gate coverage,
  overlay gaps) — not about which tool or session made a mistake.

## Done when

- `notes/retro.md` exists with the defect table and lessons list.
- Hub knowledge/overlay edits are applied; constitution proposals are quoted.
- `STATUS.md` shows `retro: done`.
- The user has the summary.
