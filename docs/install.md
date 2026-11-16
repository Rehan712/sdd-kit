# Install

```bash
git clone <this-repo> ~/sdd-kit        # anywhere you like
cd ~/sdd-kit
scripts/setup.sh
```

`setup.sh` is idempotent (re-run it after every `git pull`). It:

1. Symlinks `~/.sdd` → the clone (everything references this stable path).
   If `~/.sdd` already points at another live clone it stops instead of
   silently switching your install — pass `--relink` to move it here.
2. Bootstraps `registry.yml` from `registry.example.yml` — **edit it** to register
   your projects (absolute path + stack tags).
3. Bootstraps the **model policy** (`models.yml`) — on a terminal it runs the
   `configure-models.sh` wizard (Enter accepts the defaults; `--no-wizard` to
   skip prompts), then stamps each skill/agent with its tier's model + effort
   (see [Model tiering](model-tiering.md)).
4. Symlinks each SDD skill and agent into every Claude home (`~/.claude`,
   `~/.claude_*`) — one link per item, your other skills are untouched.
5. Generates Codex (`~/.codex`, plus every `~/.codex_*` profile home — the
   `CODEX_HOME=~/.codex_gym codex` pattern), Copilot (`~/.copilot`), Cursor
   (`~/.cursor/skills`) and Antigravity (`~/.gemini/config/skills`) adapters
   from the canonical skills, if those CLIs are installed (`--no-cli` to skip).
6. Runs `sdd-doctor.sh` to verify.

After install, `/sdd:onboard` researches every repo in `system-map.yml` and
writes its standing brief (`briefs/<repo>.md`) — setup prints a hint whenever
registered repos have no brief. Existing installs: add `onboard: implementation`,
`review: implementation`, and `go: reasoning` to your machine-local `models.yml`
roles (new installs get them from the example; `sdd-doctor.sh` lists every
unmapped role with the command that maps it).

## Install as a plugin

The same install, started from inside the tool — no terminal clone. The
plugin (`plugin/`) carries one skill, `sdd-setup`, which clones the kit to
`~/.sdd-kit` and runs `scripts/setup.sh`; run it again later to update.

| Tool | Install the plugin | Then |
|---|---|---|
| Claude Code | `/plugin marketplace add Rehan712/sdd-kit`, then `/plugin install sdd-kit@sdd-kit` (shell: `claude plugin install sdd-kit --marketplace Rehan712/sdd-kit`) | `/sdd-kit:sdd-setup` |
| Codex | `codex plugin marketplace add Rehan712/sdd-kit`, then `codex plugin add sdd-kit@sdd-kit` | ask for the `sdd-setup` skill |
| Copilot CLI | `copilot plugin marketplace add Rehan712/sdd-kit`, then `copilot plugin install sdd-kit@sdd-kit` | ask for the `sdd-setup` skill |
| Antigravity | `agy plugin install https://github.com/Rehan712/sdd-kit` | ask for the `sdd-setup` skill |
| Cursor | Settings → Customize → *From GitHub Repository* → `Rehan712/sdd-kit` | ask for the `sdd-setup` skill |

Start a new session afterwards so the installed skills load.

Why the plugin is an installer and not the kit itself:

- **A plugin folder is replaced on every update**, and the hub holds this
  machine's `registry.yml`, `models.yml`, repo briefs and umbrella specs.
  They would be lost, so the hub stays a git clone outside the plugin.
- **Plugin content is static.** The model policy stamps a model and effort
  into each skill and agent per machine, and the Codex and Copilot adapters
  are generated; a plugin can ship neither.
- **Plugin names are prefixed.** Shipped as Claude Code plugin content the
  skills load as `/sdd-kit:sdd-specify` and the agents as `sdd-kit:opponent`
  (measured on Claude Code 2.1.322), and Claude Code ignores `hooks:` in a
  plugin agent, which drops the scout's Bash guard.

So there is one install path, and the plugin is a second way to start it.
Uninstalling the plugin leaves the kit in place (`sync.sh --remove` unlinks it).

How far each tool goes:

| Tool | Skills | Gates run as | Model policy |
|---|---|---|---|
| Claude Code | native, stamped | separate subagents | per skill and agent |
| Codex | generated adapters | separate subagents | per-tier profiles |
| Copilot CLI | generated agents | review passes in the same session | model pinned per agent |
| Cursor, Antigravity | generated pointers to the hub's skill files | review passes in the same session | none — the session's model |

Cursor and Antigravity support is new. Each generated skill is a short file
that sends the session to the canonical one under `~/.sdd/skills/` — Antigravity
loads only the first 24000 bytes of a skill, which `sdd-implement` exceeds.
Antigravity's CLI was seen loading them; Cursor's loader was not exercised
(the skills follow its documented naming rules). No spec has been run end to
end on either. Cursor also loads `~/.claude/skills` and
`~/.codex/skills`, so on a machine with those homes it lists the SDD skills
more than once — use the copy under `~/.cursor/skills`.

Per project, one-time: create `.specify/stack.yml` (the skills do this for you on
first `/sdd:specify` if it's missing):

```yaml
stacks: [javascript, aws]     # tags matching templates/stack-overlays/
base_branch: main             # optional; default dev
```

## Multi-machine

The repo is the source of truth. On each machine: clone, `scripts/setup.sh`, edit
`registry.yml` for that machine's project paths. Pull + re-run `setup.sh` to update.
`knowledge/`, overlays, constitution, umbrella `specs/`, and skill improvements
travel through git; the registry and the model policy never do. For a team,
that split is the whole model: fork the kit as the team's hub repo — topology,
umbrella specs, and lessons are shared; each member's `registry.yml` maps the
repo names to wherever they're checked out locally.

`system-map.yml` and `briefs/*.md` describe YOUR repos, so this public
template gitignores them (nobody publishes their topology by accident). In
your team's fork, delete those two entries from `.gitignore` and commit both —
that is what makes the map and the briefs team-shared.
