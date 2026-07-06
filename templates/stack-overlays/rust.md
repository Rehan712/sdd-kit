# Stack overlay: Rust

Read alongside `plan.md` when the project's stack includes `rust`.

## Conventions

- **Edition 2021+**, latest stable toolchain, `rust-version` pinned in the workspace `Cargo.toml`.
- **clippy + rustfmt gate CI:** `cargo clippy --workspace --all-targets -- -D warnings` and `cargo fmt --check`. `#[allow]` only with a justification comment.
- **Errors:** `thiserror` enums in library crates; `anyhow` at binary boundaries only. Add context on propagation (`.context(...)`); never let `anyhow` appear in a library's public API.
- **Async:** `tokio` with minimal features. No blocking I/O in async fns (`spawn_blocking` instead); never hold a sync mutex across `.await`. Channels bounded by default.
- **serde:** explicit `rename_all` at API boundaries; `deny_unknown_fields` for untrusted input; boundary DTOs separate from domain types when internals would leak.
- **unsafe:** `#![forbid(unsafe_code)]` in library crates by default. If needed: isolate it, document invariants, run Miri in CI for that crate.

## Project layout

```
Cargo.toml            # [workspace] with shared deps in [workspace.dependencies]
crates/
  core/               # domain logic, no I/O
  <adapter>/          # I/O adapters (http, db, queue) depending on core
bins/ or crates/cli/  # thin binaries: parse args/config, wire crates, anyhow boundary
tests/                # cross-crate integration tests (per-crate tests live in each crate)
```

- Dependency direction: binaries → adapters → core. Core stays free of tokio/HTTP types where possible.
- Feature flags are additive; never use them to change behavior silently.

## Testing expectations

- Unit tests as `#[cfg(test)]` modules next to the code; integration tests in each crate's `tests/`.
- `proptest` for algebraic invariants: parsers, encode/decode round-trips, ordering, idempotence. Don't property-test glue code.
- Test error paths, not just happy paths — error enums exist to be asserted on.
- `cargo test --workspace` is the gate; doctests count.

## Dependency hygiene

- Every new dep is reviewed for maintenance and transitive weight; check `cargo tree -d` for duplicate versions.
- `cargo deny check` (or `cargo audit`) in CI for licenses and advisories.
- Shared versions via `[workspace.dependencies]`; crates use `workspace = true`.

## Common pitfalls / smells

- `unwrap()`/`expect()` on fallible operations in library paths — the top production panic source.
- `.ok()` or `let _ =` silently discarding a `Result`.
- Unbounded `mpsc::unbounded_channel()` "because it's easier" — that's deferred OOM.
- `clone()` sprawl papering over ownership design problems.
- A god-crate where `core` imports the HTTP framework — boundaries have dissolved.
- Stringly-typed errors (`Err("bad input".into())`) instead of typed enums.
