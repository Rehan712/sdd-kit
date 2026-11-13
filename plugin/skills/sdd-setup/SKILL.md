---
name: sdd-setup
description: Install or update the SDD kit (spec-driven development) on this machine. Clones the kit, links it at ~/.sdd, and installs the SDD skills and agents into every supported CLI it finds (Claude Code, Codex, Copilot, Cursor, Antigravity). Use when the user says "install the SDD kit", "set up sdd", "update the SDD kit", or when an sdd skill fails because ~/.sdd is missing.
---

# Install or update the SDD kit

This plugin is the kit's installer, not the kit. The kit is a git clone linked
at `~/.sdd` (the *hub*). It holds this machine's project registry, model policy
and repo briefs, and a plugin folder is replaced on every plugin update — so the
hub lives outside it, and the SDD skills are installed from the hub.

## Steps

1. Run the installer that ships with this skill — `scripts/install.sh`, relative
   to the directory this SKILL.md is in:

   ```bash
   bash "<this skill's directory>/scripts/install.sh" --no-wizard
   ```

   Keep `--no-wizard`: without it a first install asks which models to use
   on any shell that has a terminal, and the command waits for answers nobody
   can type. First run: clones the kit to `~/.sdd-kit` and runs its
   `scripts/setup.sh`.
   Later runs: fast-forwards the installed clone and re-runs `setup.sh`. It
   needs `git` and network access to github.com. If the sandbox blocks either,
   ask the user to approve the command — do not work around it.

2. Report what it printed: the doctor summary (errors and warnings verbatim)
   and the "Next steps" block. If it exits non-zero, show the message and stop.
   Never delete or re-point `~/.sdd`, and never edit another clone, to make it
   pass — an existing `~/.sdd` is someone's working install.

3. Tell the user to start a new session so the freshly installed skills load,
   then begin with the specify phase: `/sdd:specify "<feature>"` in Claude
   Code, the `sdd-specify` skill in Codex, Cursor and Antigravity, or
   `copilot --agent sdd-specify` in Copilot CLI.

## What this does not do

- It does not register projects: the user edits `~/.sdd/registry.yml` (the
  installer prints the path).
- It does not pick models: `--no-wizard` writes the default model policy. The
  user can run `~/.sdd/scripts/configure-models.sh` in a terminal afterwards.
