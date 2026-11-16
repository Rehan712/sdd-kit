# Model tiering (which model runs each phase)

Not every phase deserves the same model. Design and adversarial judgment —
specify/plan/tasks, the opponent, the reality-check, the security review — get
the strongest reasoning models on high effort; rote implementation runs on a
mid-tier model that's faster and cheaper. The split follows what a mistake at
each tier can cost:

| Work | Who | Tier | Tools |
|---|---|---|---|
| **Read-only** — search, docs lookup, running a named command, log digests | `sdd-scout` | `recon` (cheap) | no Edit/Write, and a Bash guard (`scout-guard.sh`) that refuses the common writes — git writes, kit state scripts, file mutation, redirects to a file, installs and deploys (a backstop, not a sandbox) |
| **Writing code** — one task at a time, smallest complete change | stack experts, `test-engineer` | `implementation` (mid) — `[hard]` tasks and retries escalate to `implement-hard` | full |
| **Judging it** — the two gates, the security pass | `opponent`, `reality-check`, `security-reviewer` | `reasoning` (strongest) | no Edit/Write — a reviewer never fixes what it grades |

The mapping is the **model policy**:

- **`models.yml`** (machine-local, gitignored — like the registry) defines
  **tiers** (a model + reasoning effort per CLI) and maps **roles** to tiers.
  Shipped defaults: `reasoning` = Claude `opus (xhigh)` / Codex `gpt-6.1-sol (xhigh)`
  / Copilot `claude-opus-4.8`; `implementation` = `sonnet (high)` / `gpt-6.1-terra (high)`
  / `claude-sonnet-4.5`; `recon` = `haiku (medium)` for the read-only scout.
  Provider model ids are retired over time — if a default no longer launches
  on your CLI, `model-policy.sh update <role> <model> --cli <cli>` swaps it. Roles: `specify` `plan` `tasks` `retro` `orchestrator`
  `opponent` `reality-check` `security-reviewer` `test-engineer`
  `implement-hard` → reasoning (test-engineer because tests are the AC binding
  every gate trusts; `implement-hard` is the escalation role — `[hard]`-tagged
  tasks, failed-acceptance retries, and gate follow-ups dispatch on it instead
  of repeating a failure at the tier that produced it; on Claude it is passed
  as the model's alias family plus the tier's effort, so a pinned
  `claude-opus-5-5` escalates as `opus`, and a hard tier that is the same
  model at a higher effort still changes the retry); `implement` `stack-expert` `onboard` `review` → implementation;
  `explore` (the `sdd-scout` agent) → recon. All
  of it is editable — add tiers, remap roles, or delete `models.yml` to run
  everything on the session model.
- **`scripts/configure-models.sh`** is the wizard (runs on first `setup.sh`;
  re-run anytime). `scripts/model-policy.sh show` prints the current mapping;
  `check` validates it.
- **One-off edits from the command line** — no wizard, no hand-editing:
  `scripts/model-policy.sh update plan claude-opus-5 xhigh` changes the model
  (+ effort) behind a role (it edits the tier the role points at and warns
  which sibling roles share it — add `--solo` to split the role onto its own
  cloned tier and leave the siblings untouched); `set tier <tier> <cli>
  model|effort <value>`, `set role <role> <tier>`, and `set dispatch <role>
  <cli>` (with matching `unset`s — `unset tier <tier>` with no field drops the
  whole tier, refused while a role still points at it) cover everything else
  in the file. Every edit is validated before
  it is saved — a bad model id or effort never lands — and then re-stamps the
  generated copies and CLI adapters automatically (`--no-apply` to skip).
  Running Claude sessions load agent models at startup, so agent-model edits
  apply from the next session.
- **How it's applied per CLI** — each the strongest way that CLI allows:
    - *Claude Code:* `scripts/apply-models.sh` generates copies of every skill and
      agent under `build/` with `model:` + `effort:` stamped into the frontmatter,
      and `sync.sh` points the home symlinks there. `/sdd:plan` runs on the
      reasoning tier even in a sonnet session; stack experts dispatched by the
      orchestrator run on the implementation tier. An agent's stamp holds for
      its whole run. A skill's stamp covers only the turn that loaded it — the
      next turn (a background agent finishing, your reply) is back at the
      session's own effort — so each stamped skill copy opens with a note
      telling the session to launch its agents in the foreground and to re-invoke
      the skill first in a later turn, which puts the effort back. The model is
      different: Claude Code applies a skill's `model:` only when you type its
      command, never when the session loads the skill itself (a plain-language
      request, or another skill chaining it) — so `/sdd:go` runs plan and
      tasks each as an agent, passing the phase's model and effort from the
      policy, and implement in the orchestrator agent.
    - *Codex CLI:* sessions pin models via one profile per tier
      (`~/.codex/sdd-<tier>.config.toml` → `codex --profile sdd-reasoning`);
      each adapter's preamble tells the agent to steer the session to its phase's
      tier via `/model` or a relaunch. The gates and `[hard]`-escalation ship as
      generated **subagents** (`~/.codex/agents/sdd-{opponent,reality-check,implement-hard}.toml`)
      the adapters delegate to by name — fresh-context review instead of
      persona passes. Their TOMLs carry the tier's model + effort; note current
      Codex (0.144.4) spawns them on the session model (see
      `knowledge/cli-subagent-delegation.md`), so the profile stays the model lever.
    - *Copilot CLI:* each generated `sdd-<phase>` agent (and the gate persona
      copies) gets `model:` pinned in its frontmatter; effort is session-level, so
      the preamble suggests `--effort` when the session is set lower. Copilot's
      custom-agent handoff is empirically proven (model pin included — same
      knowledge file), but the kit doesn't wire gate delegation through it yet;
      the adapters keep the persona-pass until that follow-up spec ships.

**Per-project overrides.** A project can commit
`<project>/.specify/models.yml` holding `roles:` and/or `dispatch:` — nothing
else:

```yaml
roles:
  stack-expert: reasoning    # this repo's code is hard — write it on the strong tier
dispatch:
  implement: codex
```

It names *tiers*; each machine's `models.yml` still says what a tier is, so no
model id is committed and a teammate with different models keeps working (a
tier their machine lacks → their own mapping stands, and `sdd-doctor.sh` says
so). `scripts/model-policy.sh --project <dir> show|check` prints and validates
the merged result. What it reaches: every dispatched phase
(`spec-dispatch.sh`, on all three CLIs) and every Claude subagent spawn (the
dispatcher passes the alias and effort as Agent-tool params). What it cannot
reach: the model of an interactive session already running a phase, and Codex
subagents — both are fixed machine-wide by the stamped copies and profiles.

After editing `models.yml` by hand, re-run `scripts/setup.sh` (or
`apply-models.sh` + `sync.sh` + `build-adapters.sh`) — or skip the hand-edit
entirely and use `model-policy.sh update`/`set`, which does all of that for
you. `sdd-doctor.sh` flags a stale or missing build, and validates the policy
file.

Everything that writes code sends its read-only work down a tier: `/sdd:plan`,
`/sdd:onboard`, `/sdd:review` and `/sdd:implement` fan scouts out for
searches, docs lookups and log digests, and the stack experts do the same for
a sweep or a long log — one narrow question per scout, re-read first-hand
before it shapes a plan or an edit. The gates do not: an adversarial verdict
never rests on a recon-tier "nothing else calls this".
