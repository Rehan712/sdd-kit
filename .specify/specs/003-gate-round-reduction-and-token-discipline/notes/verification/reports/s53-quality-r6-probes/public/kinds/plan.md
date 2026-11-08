---
plan_for: 003-verification-fixture
---
# Plan: Verification fixture

REQ-001, REQ-002, REQ-003 and REQ-004 use the families below.

## Risks, failure modes and verification

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | parser, runner | boundary | A shared malformed binding reaches either component | Reject the binding before execution | shell-family, assertion-family |
| FM-002 | docs | regression | The documented schema drifts | Fail the static schema check | static-family |

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | release | Every manual result names its artifact | Release checklist | manual-family |

Exclusions: docs / concurrency/ordering — documentation has no shared mutable state.

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| shell-family | test | AC-001 | `tests/check.sh::test_ac_001_shared` |
| assertion-family | assertion | AC-002 | `scripts/check-contract.sh::assert_ac_002_contract` |
| static-family | static | AC-003 | `tests/static.sh::test_ac_003_schema` |
| manual-family | manual | AC-004 | release-observation |
| integration-family | test | AC-001, AC-002 | `tests/integration.sh::test_ac_001_002_integration` |
