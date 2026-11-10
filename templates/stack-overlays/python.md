# Stack overlay: Python

Read alongside `plan.md` when the project's stack includes `python`.

## Conventions

- **Python 3.11+**, pinned via `requires-python` in `pyproject.toml` and `.python-version`.
- **uv by default** (poetry where entrenched). Deps, metadata, and all tool config live in `pyproject.toml`; the lockfile is committed and CI installs frozen. New projects never grow a `requirements.txt`.
- **venv discipline:** every project has its own venv; run everything through `uv run` / `poetry run`. Never install into the system interpreter.
- **ruff** as linter and formatter (replaces flake8/isort/black). CI fails on violations; suppressions carry an error code and a reason.
- **mypy strict** in CI. All public functions fully annotated. Modern typing: `X | None`, `list[str]`, `Self`, `TypedDict`/`Protocol` where they fit.
- **pydantic v2 at boundaries** (`model_validate`, `BaseSettings` for env). Internal pure data: `dataclass`, frozen where practical. Don't pydantic-ify internal structures that never cross a boundary.
- **Errors:** specific exception types, narrow `except` clauses, `raise ... from err`. Custom exceptions inherit from a project base exception.

## Project layout

```
pyproject.toml          # single manifest: project, deps, ruff, mypy, pytest config
uv.lock                 # committed
src/<package>/          # src layout — forces installed-package imports
  __init__.py
  py.typed              # ship type info
  <feature>.py
tests/
  conftest.py           # shared fixtures
  test_<feature>.py
```

- src layout is mandatory for new projects — it catches "works on my machine" import bugs.
- One settings module using `BaseSettings`; no raw `os.environ[...]` scattered through the code.

## Testing expectations

- pytest with plain functions; fixtures over setup/teardown; `parametrize` over copy-pasted cases.
- `tmp_path`, `monkeypatch`, `capsys` over hand-rolled equivalents.
- Mock at process/network boundaries via injected dependencies, not deep `unittest.mock.patch` string paths.
- ruff + mypy + pytest all gate CI.

## AWS Lambda specifics (when the project also deploys Python to Lambda)

- Use **`aws-lambda-powertools[all]`** for logger, metrics, tracer, parser, idempotency.
- Reuse boto3 clients at module scope, not per-invocation.
- Cold start budget: ~1-2s for a small handler with pydantic + powertools. Heavier deps (`pandas`, `numpy`) push it higher — consider Lambda Layers or container images.
- Bundle with `uv pip install --target ./build` + zip, or `aws-cdk-lambda-python-alpha` (CDK construct).
- **arm64** by default for cost + speed.

## Common pitfalls / smells

- `except:` or `except Exception: pass` — errors deserve names and handling.
- Mutable default arguments (`def f(items=[])`) — the classic shared-state bug.
- Untyped or `Any`-typed public functions dodging mypy.
- `requirements.txt`, `requirements-dev.txt`, `constraints.txt` sprawl in a new project.
- Import-time side effects (opening connections, reading env) — defer to explicit init.
- Circular imports patched with function-local imports instead of fixing module boundaries.
- Pydantic models used as internal domain objects everywhere, paying validation cost for trusted data.

## Failure-mode and checkpoint defaults

Use the [verification contract](../verification-contract.md). Fill applicable
scenario prompts as concrete FM/INV rows with test families in the plan; record
explicit exclusions with a component/category and reason. Shared scenarios use
one row listing all affected components.

- Boundary: malformed external DTOs map validation exceptions to the declared response without leaking internals.
- Partial failure: exception or cancellation after context-manager entry closes owned sessions; failure before entry closes nothing.
- Concurrency/ordering: retry a partially applied job and assert idempotence and isolation of per-request mutable defaults.

Optional `checkpoints` use exact authored task-stage names: run the focused
component tests when its stage finishes and integration after consumers land.
Start from `pytest`, adapting to existing project scripts and test scope.
Required `gate_checks` separately cover the full suite (`pytest`)
and mandatory static checks (`ruff check .; ruff format --check .; mypy .`); checkpoints never replace that list.
Commands here are planning defaults, not an assertion that a project has them.
