# Evidence log

Captured acceptance runs, appended by `spec-run.sh`. One block per run.

## T003 — 2026-07-20T00:26:53

- **Command:** `tests/run.sh spec-status`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:26:53 · sha256:f6f61eddc057 (over full output)

```text
== test-spec-status.sh
  ok   test_append_decision_adds_dated_entry_at_end_and_updates_frontmatter
  ok   test_append_decision_refuses_duplicate_sections_without_mutation
  ok   test_append_decision_refuses_missing_section_without_mutation
  -- 3/3 passed
```

## T003 — 2026-07-20T00:27:43

- **Command:** `tests/run.sh spec-status`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:27:43 · sha256:f6f61eddc057 (over full output)

```text
== test-spec-status.sh
  ok   test_append_decision_adds_dated_entry_at_end_and_updates_frontmatter
  ok   test_append_decision_refuses_duplicate_sections_without_mutation
  ok   test_append_decision_refuses_missing_section_without_mutation
  -- 3/3 passed
```

## T001 — 2026-07-20T00:28:12

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:28:12 · sha256:308fb7743aff (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  -- 4/4 passed
```

## T001 — 2026-07-20T00:29:33

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:29:33 · sha256:308fb7743aff (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  -- 4/4 passed
```

## T002 — 2026-07-20T00:30:39

- **Command:** `tests/run.sh model-policy`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:30:39 · sha256:6633fd9f2bcd (over full output)

```text
== test-model-policy.sh
  ok   test_claude_effort_whitelist_unchanged
  ok   test_codex_sandbox_and_approval_policy_fields
  ok   test_documented_codex_efforts_accepted
  ok   test_junk_codex_effort_rejected
  ok   test_usage_limit_policy_absent_and_present_defaults
  ok   test_usage_limit_policy_rejects_invalid_values
  ok   test_usage_limit_policy_set_unset_round_trip
  ok   test_usage_limit_policy_wizard_preserves_ordered_fallback
  -- 8/8 passed
```

## T004 — 2026-07-20T00:31:22

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 1
- **Captured:** 2026-07-20T00:31:22 · sha256:77920048502f (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  FAIL test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
       assert: expected exit 1, got 0: env HOME=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.XKU6ep/home PATH=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.XKU6ep/empty:/opt/homebrew/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/codex-path:/opt/homebrew/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/codex-path:/Users/babar/.codex/tmp/arg0/codex-arg0x9SnTw:/Users/babar/.local/bin:/Users/babar/.local/bin:/Users/babar/.bun/bin:/Users/babar/.antigravity/antigravity/bin:/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pkg/env/active/bin:/opt/pmk/env/global/bin:/Library/Apple/usr/bin:/Users/babar/.cargo/bin:/Users/babar/Library/Android/sdk/emulator:/Users/babar/Library/Android/sdk/platform-tools:/Users/babar/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/2.5.0/bin SDD_DISPATCH_AUTH_CHECKER=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.XKU6ep/auth-checker /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs/scripts/spec-dispatch-ready.sh copilot implement
           output: copilot ready for implement
       assert: AC-009: missing binary is named missing substring: binary not on PATH
           in: copilot ready for implement
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 5/6 passed
```

## T004 — 2026-07-20T00:32:04

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:32:04 · sha256:92d8c1d6aea7 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 6/6 passed
```

## T005 — 2026-07-20T00:35:23

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:35:23 · sha256:fb397ea841d6 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 8/8 passed
```

## T006 — 2026-07-20T00:42:07

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:42:07 · sha256:7bf2a6a111f4 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 11/11 passed
```

## T006 — 2026-07-20T00:42:49

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:42:49 · sha256:7bf2a6a111f4 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 11/11 passed
```

## T007 — 2026-07-20T00:45:41

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 1
- **Captured:** 2026-07-20T00:45:41 · sha256:4e99186cfbe3 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  FAIL test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
       assert: expected exit 7, got 6: run_dispatch --note spaces and ; punctuation
           output: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
       assert: AC-007: Codex output is classified after its true nonzero exit missing substring: provider usage limit: cli=codex kind=long reset=
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
       assert: AC-003: absent policy prints a manual park command missing substring: manual park:
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
       assert: AC-003: park guidance names the resume command missing substring: spec-resume.sh park
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
       assert: AC-003: shell-safe fallback guidance includes another CLI missing substring: --to claude
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
       assert: AC-003: shell-safe fallback guidance includes every other CLI missing substring: --to copilot
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md
         ✗ codex exited 42 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.hQadeo/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004542.md; artifacts NOT verified
  FAIL test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
       assert: expected exit 7, got 6: run_dispatch
           output: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004543.md
         ✗ codex exited 23 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004543.md; artifacts NOT verified
       assert: AC-003: explicit fail policy emits the same manual guidance missing substring: manual park:
           in: dispatching plan -> codex (root: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj)
       codex standard output
       You have hit your usage limit. Try again at 2099-01-01 00:00
       
       elapsed: 1s — captured: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004543.md
         ✗ codex exited 23 — inspect /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sddkit.W8qsvS/proj/.specify/specs/001-test-feature/notes/dispatch-plan-20260720-004543.md; artifacts NOT verified
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 11/13 passed
```

## T007 — 2026-07-20T00:45:59

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:45:59 · sha256:f5e1b69a9e99 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/13 passed
```

## T007 — 2026-07-20T00:46:30

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:46:30 · sha256:f5e1b69a9e99 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/13 passed
```

## T007 — 2026-07-20T00:47:04

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:47:04 · sha256:f5e1b69a9e99 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/13 passed
```

## T007 — 2026-07-20T00:47:49

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:47:49 · sha256:f5e1b69a9e99 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/13 passed
```

## T008 — 2026-07-20T00:49:41

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 1
- **Captured:** 2026-07-20T00:49:41 · sha256:8022cefe262d (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  FAIL test_ac_004_and_ac_005_park_policy_replays_original_dispatch_once_per_retry
       /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs/tests/test-usage-limits.sh: line 82: DISPATCH_SPEC: unbound variable
       assert: expected exit 7, got 2: env HOME=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-home PATH=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-bin:/opt/homebrew/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/codex-path:/opt/homebrew/lib/node_modules/@openai/codex/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/codex-path:/Users/babar/.codex/tmp/arg0/codex-arg0x9SnTw:/Users/babar/.local/bin:/Users/babar/.local/bin:/Users/babar/.bun/bin:/Users/babar/.antigravity/antigravity/bin:/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pkg/env/active/bin:/opt/pmk/env/global/bin:/Library/Apple/usr/bin:/Users/babar/.cargo/bin:/Users/babar/Library/Android/sdk/emulator:/Users/babar/Library/Android/sdk/platform-tools:/Users/babar/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/2.5.0/bin DISPATCH_SEAM_LOG=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-seams.log DISPATCH_PROVIDER_STDOUT=codex standard output DISPATCH_PROVIDER_STDERR=You've hit your usage limit. Try again at 01:49 AM DISPATCH_PROVIDER_EXIT=42 SDD_RESUME_ROOT=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch resume state SDD_RESUME_SCHEDULER=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-kit/scripts/dispatch-resume-scheduler SDD_RESUME_JITTER_SECONDS=0 DISPATCH_RESUME_LOG=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.log DISPATCH_RESUME_JOBS=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.jobs bash -c cd -- "$1" && shift && "$@" bash /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/original cwd with spaces /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-kit/scripts/spec-dispatch.sh plan /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/proj/.specify/specs/001-test-feature --to codex --note verbatim ; punctuation 
           output: unexpected arg: 
       find: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch resume state: No such file or directory
       assert: AC-004: dispatch park creates one deterministic resume unit
       assert: AC-004: park persists the untouched original dispatcher argv
       assert: AC-004: park persists the untouched original dispatcher cwd
       awk: can't open file /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch resume state//unit.tsv
        source line number 1
       awk: can't open file /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch resume state//unit.tsv
        source line number 1
       assert: AC-004: parsed reset is stored in the resume unit
       grep: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.log: No such file or directory
       assert: AC-004: initial park registers exactly one scheduler entry
           expected: 1
           actual:   
       /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs/tests/test-usage-limits.sh: line 274: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.jobs: No such file or directory
       assert: AC-004: exactly one scheduler job is pending
           expected: 1
           actual:   
       assert: AC-004: park records its event through spec-status missing substring: parked resume unit 
           in: ---
       spec: 001-test-feature
       phase: tasks
       branch: none
       ---
       # Status
       
       ## Blockers
       
       (none)
       assert: expected exit 7, got 2: run_dispatch_resume 
           output: #
       # Usage:
       #   spec-resume.sh park --spec <live-spec> --role <role> --kind <kind> \
       #     [--reset <epoch>] [--backoff-minutes <n>] -- <original argv...>
       #   spec-resume.sh run <unit-id>
       #   spec-resume.sh list [--tsv]
       #   spec-resume.sh cancel <unit-id>
       assert: expected exit 7, got 2: run_dispatch_resume 
           output: #
       # Usage:
       #   spec-resume.sh park --spec <live-spec> --role <role> --kind <kind> \
       #     [--reset <epoch>] [--backoff-minutes <n>] -- <original argv...>
       #   spec-resume.sh run <unit-id>
       #   spec-resume.sh list [--tsv]
       #   spec-resume.sh cancel <unit-id>
       assert: expected exit 7, got 2: run_dispatch_resume 
           output: #
       # Usage:
       #   spec-resume.sh park --spec <live-spec> --role <role> --kind <kind> \
       #     [--reset <epoch>] [--backoff-minutes <n>] -- <original argv...>
       #   spec-resume.sh run <unit-id>
       #   spec-resume.sh list [--tsv]
       #   spec-resume.sh cancel <unit-id>
       cat: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch resume state//unit.tsv: No such file or directory
       assert: AC-005: nested exit 7 honors the resume retry cap missing substring: state	failed
           in: 
       grep: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.log: No such file or directory
       assert: AC-005: initial park plus two nested re-parks add no duplicate jobs
           expected: 3
           actual:   
       /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs/tests/test-usage-limits.sh: line 284: /var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T//sddkit.e5ZObq/dispatch-resume-scheduler.jobs: No such file or directory
       assert: AC-005: retry-cap failure leaves no scheduler job
           expected: 0
           actual:   
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/14 passed
```

## T008 — 2026-07-20T00:50:11

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 1
- **Captured:** 2026-07-20T00:50:11 · sha256:aa8c85efd790 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  FAIL test_ac_004_and_ac_005_park_policy_replays_original_dispatch_once_per_retry
       assert: AC-004: park persists the untouched original dispatcher cwd
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 13/14 passed
```

## T008 — 2026-07-20T00:50:32

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:50:32 · sha256:fb5095caa824 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_and_ac_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  -- 14/14 passed
```

## T009 — 2026-07-20T00:58:07

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T00:58:07 · sha256:85541becff62 (over full output)

```text
== test-usage-limits.sh
  ok   test_ac_001_classifies_every_planned_provider_limit_fixture
  ok   test_ac_001_ordinary_failures_including_limit_word_are_none
  ok   test_ac_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_ac_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_ac_003_and_ac_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_ac_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_ac_004_and_ac_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_ac_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_ac_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_ac_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_ac_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_ac_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_ac_006_and_ac_009_readiness_requires_binary_adapter_and_authentication
  ok   test_ac_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_ac_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_ac_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_ac_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  -- 17/17 passed
```

## T010 — 2026-07-20T01:00:53

- **Command:** `bash -c tests/run.sh && shellcheck -S warning -x scripts/*.sh tests/*.sh`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:00:53 · sha256:e7834fa43ee9 (over full output)

```text
== test-build-adapters.sh
  ok   test_adapters_install_into_every_codex_home
  ok   test_codex_adapters_delegate_copilot_adapters_persona_pass
  ok   test_degrades_without_policy_or_codex_home
  ok   test_delegation_findings_artifact_present_and_shaped
  ok   test_prune_respects_kit_marker_and_role_unmapping
  ok   test_stale_single_agent_claims_are_gone
  ok   test_subagent_tomls_carry_identity_policy_and_persona
  -- 7/7 passed
== test-executable-bits.sh
  ok   test_AC_011_every_kit_script_is_executable
  -- 1/1 passed
== test-golden-example.sh
  ok   test_golden_example_demonstrates_the_conventions
  ok   test_golden_example_passes_sdd_analyze_with_zero_warnings
  -- 2/2 passed
== test-lib.sh
  ok   test_expand_tilde
  ok   test_fm_get_no_frontmatter_is_empty
  ok   test_fm_get_reads_only_the_fence
  ok   test_fm_list_inline_and_block
  ok   test_fm_set_appends_missing_key_inside_fence
  ok   test_fm_set_refuses_file_without_frontmatter
  ok   test_fm_set_replaces_and_keeps_inline_comment
  ok   test_registry_entries_parses_entries_in_any_field_order
  ok   test_registry_path_for_expands_tilde
  ok   test_spec_declared_repos
  ok   test_usage_from_header
  ok   test_yml_clean_hash_needs_preceding_space
  ok   test_yml_get_and_list
  -- 13/13 passed
== test-model-policy.sh
  ok   test_AC_008_usage_limit_policy_absent_and_present_defaults
  ok   test_AC_008_usage_limit_policy_rejects_invalid_values
  ok   test_AC_008_usage_limit_policy_set_unset_round_trip
  ok   test_AC_008_usage_limit_policy_wizard_preserves_ordered_fallback
  ok   test_claude_effort_whitelist_unchanged
  ok   test_codex_sandbox_and_approval_policy_fields
  ok   test_documented_codex_efforts_accepted
  ok   test_junk_codex_effort_rejected
  -- 8/8 passed
== test-sdd-analyze.sh
  ok   test_clean_fixture_is_consistent
  ok   test_dangling_ref_fails
  ok   test_duplicate_task_id_fails
  ok   test_external_marker_must_be_mirrored_in_status
  ok   test_gate_agent_placeholder_fails
  ok   test_missing_artifact_is_an_error
  ok   test_missing_gate_agent_file_fails
  ok   test_missing_verify_line_warns
  ok   test_needs_clarification_blocks
  ok   test_stray_repo_tags_without_umbrella_warn
  ok   test_task_without_acceptance_fails
  ok   test_ticked_box_without_evidence_warns
  ok   test_umbrella_declared_repo_with_no_tasks_warns
  ok   test_umbrella_tagged_tasks_pass
  ok   test_umbrella_undeclared_repo_tag_fails
  ok   test_umbrella_untagged_tasks_fail
  ok   test_uncovered_ac_fails_and_gate_refs_do_not_count
  -- 17/17 passed
== test-spec-ac-coverage.sh
  ok   test_all_acs_bound_passes
  ok   test_default_root_is_the_git_toplevel
  ok   test_extra_test_glob_extends_the_net
  ok   test_longer_ids_do_not_satisfy_shorter_acs
  ok   test_no_acs_in_spec_is_a_noop_not_a_crash
  ok   test_root_path_containing_test_does_not_classify_everything
  ok   test_spec_dir_itself_never_counts_as_coverage
  ok   test_test_paths_with_spaces_are_counted
  ok   test_unreferenced_ac_fails_referenced_ac_passes
  -- 9/9 passed
== test-spec-dispatch.sh
  ok   test_repo_match_is_token_exact
  ok   test_undeclared_repo_refused_and_declared_accepted_past_the_guard
  -- 2/2 passed
== test-spec-run.sh
  ok   test_failing_command_keeps_box_unticked_but_records
  ok   test_key_flag_picks_the_evidence_line
  ok   test_no_tick_captures_only
  ok   test_passing_command_records_and_ticks
  ok   test_usage_errors
  -- 5/5 passed
== test-spec-status.sh
  ok   test_append_decision_adds_dated_entry_at_end_and_updates_frontmatter
  ok   test_append_decision_refuses_duplicate_sections_without_mutation
  ok   test_append_decision_refuses_missing_section_without_mutation
  -- 3/3 passed
== test-spec-task.sh
  ok   test_done_rerun_replaces_evidence_not_duplicates
  ok   test_done_with_evidence_is_one_atomic_edit
  ok   test_done_without_evidence_is_refused
  ok   test_follow_up_ids_never_match_their_parent
  ok   test_gate_and_ship_tasks_are_exempt_from_evidence
  ok   test_list_reports_id_state_stage_subject
  ok   test_preformatted_evidence_is_not_double_wrapped
  ok   test_start_marks_in_progress
  ok   test_undo_unticks_but_keeps_evidence
  ok   test_unknown_task_and_bad_usage
  -- 10/10 passed
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  -- 17/17 passed
```

## T011 — 2026-07-20T01:05:50

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:05:50 · sha256:f7316ff20cef (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  -- 19/19 passed
```

## T012 — 2026-07-20T01:08:20

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 1
- **Captured:** 2026-07-20T01:08:20 · sha256:40dc88e8a1f9 (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  FAIL test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
       assert: AC-010: README explains automatic recovery missing substring: automatic resume
           in: # SDD Kit — spec-driven development, multi-project, multi-CLI
       
       A portable setup for **spec-driven development** (SDD): every non-trivial change is
       captured as a spec, planned, decomposed into checkable tasks, implemented in an
       isolated git worktree, and blocked from shipping until **two adversarial gates**
       pass. Works across all your projects from one install, and drives Claude Code,
       Codex CLI, and Copilot CLI from the same canonical skill files.
       
       > Spec → Plan → Tasks → Implement → Retro. Specs are the durable artifact; code is
       > what falls out.
       
       ## Install
       
       ```bash
       git clone <this-
  -- 19/20 passed
```

## T012 — 2026-07-20T01:09:37

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:09:37 · sha256:e369f51d463c (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  ok   test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
  -- 20/20 passed
```

## T012 — 2026-07-20T01:10:04

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:10:04 · sha256:e369f51d463c (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  ok   test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
  -- 20/20 passed
```

## T012 — 2026-07-20T01:10:21

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:10:21 · sha256:e369f51d463c (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  ok   test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
  -- 20/20 passed
```

## T013o1 — 2026-07-20T01:18:00

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:18:00 · sha256:d2d590aa3de1 (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  ok   test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
  ok   test_T013o1_clock_only_horizons_follow_configured_park_policy
  -- 21/21 passed
```

## T013o2 — 2026-07-20T01:24:47

- **Command:** `tests/run.sh limits`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs
- **Exit:** 0
- **Captured:** 2026-07-20T01:24:47 · sha256:8e77444a9e65 (over full output)

```text
== test-usage-limits.sh
  ok   test_AC_001_classifies_every_planned_provider_limit_fixture
  ok   test_AC_001_ordinary_failures_including_limit_word_are_none
  ok   test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe
  ok   test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused
  ok   test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy
  ok   test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six
  ok   test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry
  ok   test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent
  ok   test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent
  ok   test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler
  ok   test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three
  ok   test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit
  ok   test_AC_005_scheduler_remove_failure_releases_lock_and_retries_same_unit
  ok   test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication
  ok   test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks
  ok   test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted
  ok   test_AC_006_delegate_classifies_only_the_current_attempt_slice
  ok   test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification
  ok   test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models
  ok   test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks
  ok   test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows
  ok   test_T013o1_clock_only_horizons_follow_configured_park_policy
  -- 22/22 passed
```
