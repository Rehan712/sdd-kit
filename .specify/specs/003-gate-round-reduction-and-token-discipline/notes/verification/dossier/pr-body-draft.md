Implementation draft — validation and gate results must be filled before PR creation.

Repeated review rounds could reuse stale captures or repeat unchanged checks, while task completion depended on an implementer’s evidence claim. This change adds versioned FM/INV test bindings, complete source-aware captures, deterministic return acceptance, stage coverage checkpoints, a shared verification floor, and per-gate round reservations capped at three without exact-round authorization.

Invoker and reviewer contracts now require no-tick capture, validated acceptance, class-wide fixes, and current evidence. Retro reporting keeps usage, verification reuse, findings, and 14-day quality observations separate; unknown measurements remain unknown.

Spec: `.specify/specs/003-gate-round-reduction-and-token-discipline/spec.md`
Plan: `.specify/specs/003-gate-round-reduction-and-token-discipline/plan.md`
Tasks: `.specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md`

Validation: historical macOS Bash 3.2 and Linux suites passed 130/130 plus ShellCheck; current host checkpoints/floor and independent review remain in progress. GitHub-hosted CI has not run for this change.
