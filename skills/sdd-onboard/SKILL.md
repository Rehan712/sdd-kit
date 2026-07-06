---
name: sdd:onboard
description: Research every repo the hub governs and write its standing brief (briefs/<repo>.md) up front — local checkouts via registry.yml, GitHub-only repos via the system map's remote: field and a cached shallow clone. Also refreshes stale briefs (--refresh). Use when the user types /sdd:onboard, says "onboard the repos", "generate the repo briefs", "refresh the briefs", or right after installing the kit when setup.sh reports repos with no brief.
---

# /sdd:onboard — Research the governed repos, write their briefs

Standing per-repo context lives in `~/.sdd/briefs/<repo>.md` (one file per repo
in `system-map.yml`, from `~/.sdd/templates/brief-template.md`). Without this
skill, briefs appear only lazily — `/sdd:plan` writes one the first time a spec
touches a repo. This skill fills them **up front** (fresh install, new repos)
and **refreshes** them when they drift, so every spec starts warm.

## Modes

| User said... | Mode | Behavior |
|---|---|---|
| `/sdd:onboard` | **onboard** | Write a brief for every system-map repo that lacks one. Repos with an existing brief are reported `current` (or `stale` — suggest `--refresh`) and left untouched. |
| `/sdd:onboard --refresh` | **refresh-stale** | Re-research exactly the repos whose verdict is `stale` or `unknown` (`brief-status.sh list --fetch`), plus any that are `missing`. Fresh briefs are left byte-identical. |
| `/sdd:onboard --refresh <repo> [<repo>…]` | **refresh-named** | Re-research exactly the named repo(s), nothing else. |

## Step-by-step

### 1. Enumerate and triage

```
~/.sdd/scripts/system-map.sh list            # every governed repo
~/.sdd/scripts/brief-status.sh list --fetch  # repo  brief  sha  behind  verdict
```

Triage with `--fetch`: onboard/refresh is the kit's designated network path
(it clones and fetches to research), so triage must fetch too — otherwise a
remote-only repo whose cache clone has drifted reads `fresh` forever and never
enters the refresh-stale work list. Post-o5, `--fetch` deepens only the shallow
cache clones and does a plain `git fetch` on full checkouts (no shallowing);
offline or auth failures are swallowed (`|| true`) so triage degrades to
today's local-only counting. This is scoped to onboard — doctor, status, and
`/sdd:plan` stay no-network (R5).

The verdict column decides the work list per the mode table. Repos with role
`external` are included when reachable — their briefs help stub at contracts —
but the brief must open with a "role: external — read-only for us" note.

### 2. Resolve each repo's checkout — in this order

1. **Local checkout:** `~/.sdd/scripts/system-map.sh path <repo>` (registry.yml
   join). Research branch = the repo's `.specify/stack.yml` `base_branch:` if
   present, else the checked-out branch.
2. **Remote cache clone:** no local path, but `system-map.sh show <repo>` has a
   `remote:` — clone shallow into the hub cache (gitignored, reused):
   ```
   git clone --depth 1 --single-branch <remote> ~/.sdd/.cache/repos/<repo>   # first time
   git -C ~/.sdd/.cache/repos/<repo> fetch --depth 21 origin                 # refresh visits
   ```
   Research branch = the clone's default branch (`origin/HEAD`).
3. **Unreachable:** no path, no `remote:`, or the clone/fetch fails (offline,
   auth, deleted repo) — **skip with a reason**. The run continues; the reason
   lands in the summary table. Never fabricate a brief for a repo you could
   not check out.

### 3. Research — one Explore agent per repo, in parallel

Fan out one Explore agent per work-list repo (one message, multiple Agent
calls). If the hub has a model policy, run them on its `explore` tier
(`~/.sdd/scripts/model-policy.sh get explore claude model` — pass as the Agent
tool's `model` parameter when it prints an alias; otherwise omit). On a
single-agent CLI, research the repos yourself, sequentially, same rules.

Each agent gets the repo's resolved checkout path and returns the brief
template's sections — what it owns, entry points (build/test/deploy commands,
main source roots), contracts provided/consumed (cross-check `system-map.sh
contracts <repo>`), conventions that bite, gotchas — **with a file path or
command output backing every claim**. Anything the agent could not verify in
the checkout is omitted, not guessed.

### 4. Write the briefs

For each researched repo, write `~/.sdd/briefs/<repo>.md` from
`~/.sdd/templates/brief-template.md`:

- `**Updated:** <today> (by /sdd:onboard)`
- `**Source:** <branch> @ <full-sha>` — the researched checkout's branch and
  `git rev-parse HEAD` (provenance: what the brief's content describes). Note:
  `brief-status.sh` counts staleness against the repo's **base branch**
  (stack.yml `base_branch:` → `origin/HEAD` → main|dev|master), not this
  line's branch — when the checkout you researched is NOT on the base branch,
  say so in the brief; a brief without a parseable Source line reports
  verdict `unknown`.
- On **refresh**: rewrite the researched sections, but keep existing `Gotchas`
  entries that still apply (they carry `(learned: <spec-slug>)` provenance the
  re-research cannot see). Drop only gotchas the checkout contradicts.
- Write the file only after research succeeded — a failed repo never truncates
  or deletes an existing brief.

### 5. Report — per-repo summary table

End with one row per system-map repo:

| Repo | Source | Result |
|---|---|---|
| `<repo>` | local / cache / — | written / refreshed / current / stale (suggest --refresh) / skipped: <reason> |

Then re-run `~/.sdd/scripts/brief-status.sh check` and paste its summary line —
that's the run's exit evidence. Remind the user briefs are committed,
team-shared context: `git -C ~/.sdd add briefs/ && git commit` publishes them.

## Grounding rules — non-negotiable

1. **Never write a path, ID, or verdict from memory.** Every file path, command,
   and contract in a brief must come from the repo checkout read *in this
   session* (by you or your Explore agent). If you can't point at its source,
   leave it out.
2. **Quote before you act.** Before writing a brief section, re-read the
   template's instructions for that section and satisfy exactly what they say.
3. **Unknown → ask or mark, never invent.** A repo you couldn't reach is
   `skipped: <reason>` in the summary — never a brief assembled from
   recollection or the repo's name.
4. **Paste outputs, don't paraphrase.** Entry-point commands in a brief are the
   actual commands found in the repo (package.json scripts, Makefile, CI), and
   the run's evidence is `brief-status.sh check`'s actual output line.
5. **On contradiction, stop.** If research contradicts `system-map.yml` (a
   dependency or contract the map doesn't know), surface it and fix the map
   (`system-map.sh check` must pass) — don't write a brief that quietly
   disagrees with the topology.

## Rules

- **Never delete or truncate a brief.** Worst case a brief goes untouched and
  stays `stale` — a failed refresh must leave the old file byte-identical.
- **The cache is disposable, the briefs are not.** `~/.sdd/.cache/` is
  gitignored scratch; never commit it, never point a brief at it as a path.
- **No credentials in artifacts.** Clone with the user's ambient git auth;
  never write a URL containing a token into `system-map.yml`, a brief, or the
  summary (CON-001).
- **Don't research the hub itself.** The hub is meta-tooling; it's not in the
  system map and gets no brief.
- **Refresh is explicit.** This skill only rewrites a brief in `--refresh` mode
  (or when creating a missing one). No other phase auto-refreshes; `/sdd:plan`
  warns and points here.
- **Stay deterministic where scripts exist.** Missing/stale decisions come
  from `brief-status.sh`, never from eyeballing dates (constitution §10.6).

## Done when

- Every repo in `system-map.yml` has either a brief with `Updated:` + `Source:`
  lines or a `skipped: <reason>` row in the summary.
- No pre-existing brief was deleted, and non-work-list briefs are byte-identical.
- `brief-status.sh check` output is pasted in the summary.
- The user knows which briefs to commit and which repos were skipped and why.
