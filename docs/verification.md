# Versioned verification workflow

New specs opt in with `verification_contract: 1`. The
[verification contract](https://github.com/Rehan712/sdd-kit/blob/main/templates/verification-contract.md) defines typed tests,
shared FM/INV rows, command configuration, structured returns and report grammar.
Legacy captures remain readable; current gates still require proof freshness.
Required `gate_checks` cover the full suite and mandatory static checks. Optional
`checkpoints` add commands for exact task-stage names; completed-task coverage is
checked even when a stage has no commands. Integrity verifies stored artifacts;
freshness verifies that their inputs still describe the current source.

From the existing spec worktree, use the local scripts when developing the kit:

```bash
# Returns and reports are spec bookkeeping, never worktree files: a stray
# return.txt beside the code changes the input manifest, and acceptance then
# rejects the fresh capture as stale.
VERIFY="$SPEC/notes/verification"; mkdir -p "$VERIFY/returns" "$VERIFY/reports"
# --return prints the Verification-Return block; save it as printed.
bash scripts/spec-run.sh "$SPEC" "$TASK" --from-task --no-tick --summary --return > "$VERIFY/returns/$TASK.txt"
bash scripts/spec-gate.sh accept "$SPEC" "$TASK" "$VERIFY/returns/$TASK.txt"
bash scripts/spec-gate.sh checkpoint "$SPEC" "$STAGE"
bash scripts/spec-gate.sh floor "$SPEC"
bash scripts/spec-gate.sh round "$SPEC" opponent
# Delegate the independent review with the granted identities, then:
bash scripts/spec-gate.sh round "$SPEC" opponent --complete "$VERIFY/reports/opponent.md"
# Check what the NEXT round needs, and check a round-4+ authorization the
# moment you write it: same grammar and the same diagnostics as the
# reservation, reserving nothing and changing no state. A waiver validated only
# by attempting a reservation costs a floor to discover it never parsed.
bash scripts/spec-gate.sh waiver "$SPEC" opponent 2
bash scripts/spec-gate.sh tally "$SPEC"
```

Five public entrypoints expose `--help`: spec-run.sh, spec-task.sh,
spec-evidence.sh, spec-ac-coverage.sh and spec-gate.sh.

Full capture retention is **off by default**. Each versioned run still verifies
the real command and records a sealed receipt under `notes/captures/`: exact
arguments, exit status, before/after input hashes, test-binding and output
hashes, output byte count, and a bounded summary. A failure includes up to 20
diagnostic lines. Full output and input manifests are temporary during the run.
Acceptance, freshness checks, and review gates use the receipt. Replaying or
inspecting the original full output later requires opting in before the run.

```bash
git config --local sdd.fullCaptures true    # keep full captures for this repository
git config --local sdd.fullCaptures false   # use receipts for subsequent runs
```

Use `--global` to set your user default. A repository setting takes precedence.
Full mode retains `output.log`, the test bindings, and each distinct input
manifest once in `notes/captures/manifests/`. Switching modes affects new runs.
Legacy tasks keep their existing Markdown evidence format and also honor this setting.
The updated kit verifies both earlier full formats and compact receipts. Update
all verifiers before sharing receipts, and archive the entire spec including
any logs excluded by Git. Retro retains the evidence.

A new spec's `notes/.gitignore` keeps `captures/`, `verification/captures/`,
`verification/floors/` and `verification/checkpoints/` out of Git. Each later
spec's input manifest lists every tracked file, so committing these run records
makes every following spec's evidence larger. A spec created before this needs
the same file added by hand, and records it already committed stay listed until
they are untracked (`git rm -r --cached`). The ignored records exist only in the
checkout that produced them: run the tally and the retro before removing it.

Finish batch edits before capture/acceptance. Workers never tick; the invoker
rejects incomplete or forged returns without changing tasks. Checkpoint failure
stops the next stage even when only retained-coverage checks apply. A fresh floor
executes analyzer, coverage, evidence integrity and every required gate_checks
command. Only exact local checks explicitly opted into reuse may reuse complete
unchanged inputs; unknown/external/time-dependent checks execute again. Stale
proof refreshes verification while preserving historical completion.

The opponent retains every established blocker, stable Class, all known sites
and searched/unexamined scope. Root cause remains a separate process label.
Reality-check includes every AC and carries only validated unchanged prior PASS
rows; an executed suite does not decide semantic coverage. A reservation refusal
stops dispatch. Use --reconcile for interrupted reports; never reset history.
Models, separate gates and security-review authority retain their existing roles.
Measure actual usage or record unknown; compare cost alongside 14-day defects.
