# Usage-limit handling for dispatched runs

This note records the empirical provider messages recognized by the dispatched
run wrapper. It documents observed wording, not a provider contract: providers
may change their messages at any time. When wording drifts, update the cited
evidence, the classifier's pattern table, and its fixtures together; do not
invent a new message from memory.

## Message provenance

- **Claude:** pipe-epoch headless format from
  [anthropics/claude-code#2087](https://github.com/anthropics/claude-code/issues/2087);
  reset wording from
  [anthropics/claude-code#5977](https://github.com/anthropics/claude-code/issues/5977);
  session, weekly, and Opus-window terminology from
  [Claude support's usage-limit guide](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work).
- **Codex:** “usage limit” followed by “try again at” reports from
  [openai/codex#12299](https://github.com/openai/codex/issues/12299) and
  [openai/codex#30041](https://github.com/openai/codex/issues/30041).
- **Copilot:** premium-request and premium-model-quota reports from
  [GitHub Community discussion 165869](https://github.com/orgs/community/discussions/165869)
  and [discussion 167237](https://github.com/orgs/community/discussions/167237),
  with current product context in
  [GitHub's Copilot usage-limits documentation](https://docs.github.com/en/copilot/concepts/usage-limits).

The classifier deliberately requires provider-specific hard-failure wording.
An ordinary failure that merely says “limit” must not trigger a park or
fallback. See `scripts/usage-limit-patterns.tsv` and
`tests/fixtures/usage-limits/` for the versioned detector inputs.

## Policy and automatic recovery

Automatic recovery is an opt-in `models.yml` policy. With no `on_limit:` block,
the default is off: a dispatched run reports the limit and takes no automatic
action. A present block accepts exactly these parser keys:

```yaml
on_limit:
  short: park
  long: delegate
  fallback: [claude, copilot]
  backoff_minutes: 60
```

`short` and `long` each select `park`, `delegate`, or `fail`. A present block
defaults to `short: park`, `long: delegate`, `fallback: []`, and
`backoff_minutes: 60`. Parking preserves the dispatched command for one-shot
resume, along with the parking shell's PATH — launchd/cron fire with the stock
system PATH, and the stored PATH is what resolves the provider CLIs at replay
time (only PATH travels; never the whole environment). Delegation tries the
ordered, ready `fallback` CLIs and parks when it cannot find one. Remove
`on_limit:` to disable future automatic actions; use
`scripts/spec-resume.sh list` and `scripts/spec-resume.sh cancel <unit-id>` to
inspect or cancel already parked work.

## Manual recipe for an interactive session

An interactive CLI session cannot recover automatically: when its provider
limit ends the turn, the wrapper does not get a chance to run. Save any useful
terminal output, wait until the provider's reported reset time (or choose a
different provider yourself), then start a fresh interactive session in the
same worktree. Read the spec's `STATUS.md`, inspect the remaining unchecked
task in `tasks.md`, and continue with the appropriate SDD command. Do not
assume a parked resume unit exists: interactive sessions do not create one.
