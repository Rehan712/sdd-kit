# Repo brief: <repo-name>

> Standing context for planning against this repo without re-exploring it from
> scratch. Written by `/sdd:plan` the first time a spec touches the repo, or by
> `/sdd:onboard` to seed it upfront; refreshed by `/sdd:retro` after a spec
> ships changes here. Facts only — if you haven't verified a path this pass,
> don't write it.

**Updated:** YYYY-MM-DD (by spec `<slug>`)
**Source:** <branch> @ <full-sha>

## What it owns

One paragraph: the domain this repo is the source of truth for, and what it
explicitly does NOT own.

## Entry points

- Build/run: `<command>`
- Test: `<command>`
- Deploy: `<command or pipeline>`
- Main source roots: `<paths>`

## Contracts

- Provides: `<contract id (kind) — schema path>` (mirror of system-map.yml, plus detail)
- Consumes: `<contract id — how it's pulled in (codegen? pinned version?)>`

## Conventions that bite

The 3-6 things a newcomer gets wrong here: layering rules, naming, codegen
steps that must run after schema changes, directories that look editable but
are generated, etc.

## Gotchas

Dated bullets, each with `(learned: <spec-slug>)`. Prune anything the repo has
since fixed.
