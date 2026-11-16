# Customizing

- **Add a stack**: write `templates/stack-overlays/<tag>.md` (+ optionally
  `agents/<tag>-expert.md`), add the tag to your project's `stack.yml`, and add
  one row to `templates/stack-routing.md` — the single routing table every
  skill and the orchestrator read. Re-run `setup.sh`. A new language gets a
  digest under `templates/style-guides/` that the overlay names in a
  `## Style guide` section; a new expert copies the `## Working rules` block
  from an existing one (the test suite checks both).
- **Project-specific rules**: `<project>/.specify/constitution.md` extends the kit
  constitution with overrides only. A project can pin its own reality-check agent
  there (`Reality-check agent: <path>` — resolution order: constitution pin →
  project-local `.claude/agents/reality-check*.md` → kit default).
- **Project-specific models and skills**: `<project>/.specify/models.yml`
  remaps roles and dispatch for that project (see [Per-project overrides](model-tiering.md));
  `<project>/.specify/routing.md` names its own planning,
  implementation and review skills and agents per file signal (see [Project skills and agents](skills-and-routing.md)).
  Both are committed with the project.
- **Editing skills/agents**: edit them **in this repo only** — then re-run
  `setup.sh` (or `apply-models.sh` + `build-adapters.sh`) so the model-stamped
  `build/` copies and the Codex/Copilot adapters pick the change up. Without a
  `models.yml` the homes link the canonical files directly and see edits
  instantly. Never edit a copy in a home directory — `sdd-doctor.sh` catches
  both drift and a stale build.
- **The feedback loop**: `/sdd:retro` files lessons into `knowledge/` and proposes
  overlay amendments. Every knowledge file opens with a `**Cue:**` line — the
  kind of situation it applies to — and `/sdd:specify`, `/sdd:plan` and
  `/sdd:tasks` list the cues and open only the files that match, so a lesson
  is read where it applies and costs nothing elsewhere (`sdd-doctor.sh` warns
  on a file with no cue). A mechanical defect becomes a proposed check rather
  than more prose, and a lesson that was in place while its defect came back
  is fixed at the cause, not restated. Commit those; that is how the kit gets
  smarter with every feature you ship.
