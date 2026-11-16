# Multi-repo features (umbrella specs)

A team's feature rarely lives in one repo — web + mobile + big-screen clients,
several backend services, a separate infra repo. The kit handles that with
three pieces:

- **`system-map.yml`** (team-shared in your fork — unlike the machine-local
  registry; see [Multi-machine](install.md#multi-machine)): what each repo *is* — role (`app|service|infra|design|library|external`),
  owning team, `depends_on`, and the **contracts** between repos (OpenAPI,
  event schemas) with their source repo. Query/validate via
  `scripts/system-map.sh {list,show,path,deps,consumers,contracts,check}`.
- **Umbrella specs** in the hub's `specs/NNN-slug/`: ONE spec for the feature
  (`new-spec.sh --multi --repos a,b,c "<title>"`), with `repos:` frontmatter,
  ACs tagged `[repo:<name>]`, and a **Repo matrix** in STATUS.md tracking
  branch/worktree/PR per repo. Tasks carry `[repo:<name>]` tags
  (`sdd-analyze.sh` enforces them), each executing in its own repo's worktree
  (`spec-worktree.sh --repo <name>`), and each repo ships its own PR
  (`spec-pr.sh --repo <name>`) — but the **gates run once, spec-wide**, over
  every repo's diff together, and block all the PRs.
- **Repo briefs** in `briefs/<name>.md`: standing per-repo context (what it
  owns, entry points, contracts, gotchas) seeded in bulk by **`/sdd:onboard`**
  (local checkouts via the registry; GitHub-only repos via the map's `remote:`
  field and a cached shallow clone), written by `/sdd:plan`'s per-repo
  exploration, and refreshed by `/sdd:retro` — so specs stop re-exploring ten
  repos from scratch. Each brief records the commit it described
  (`**Source:** <branch> @ <sha>`); `scripts/brief-status.sh` flags briefs
  ≥ 20 commits (configurable) behind as stale, surfaced by `sdd-doctor.sh`,
  `sdd-status.sh`, `setup.sh`, and a `/sdd:plan` warning. Refresh is always
  explicit: `/sdd:onboard --refresh [repo…]`.

Ordering is **contract-first** (see `knowledge/cross-repo-contracts.md`):
contract changes → infra → provider services → consumer apps, and the same
order for merge/deploy. Dependencies on *other teams'* repos never become
tasks — the spec records `[EXTERNAL: <team/repo> — <what> — needed-by <date>]`,
mirrored in STATUS blockers, and implementation stubs at the agreed contract.

Single-repo features are untouched by all of this — their specs stay in the
project repo exactly as before.
