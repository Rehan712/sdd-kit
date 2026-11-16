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
spec-evidence.sh, spec-ac-coverage.sh and spec-gate.sh. Full logs and SHA-256
metadata remain under spec-local notes/captures; --summary bounds returned
success output to 2048 bytes and failure output to 8192 bytes/20 diagnostic
lines without changing the actual exit code.

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
