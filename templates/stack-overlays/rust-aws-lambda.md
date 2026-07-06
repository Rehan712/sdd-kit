# Stack overlay: Rust on AWS Lambda

Read alongside `plan.md` when `stack.yml` includes `rust-aws-lambda`.

## Toolchain

- **cargo-lambda** for building and deploying. `cargo lambda build --release --arm64`.
- **Rust edition 2021** minimum.
- **MSRV pinned** in `Cargo.toml` (`rust-version = "1.75"` or current floor).
- **Architecture:** `aarch64-unknown-linux-gnu` (Graviton). Faster, cheaper, ~no downsides.

## Crate layout

- Binary crate per Lambda: `crates/<name>/src/main.rs`.
- Shared logic in a workspace library crate (`crates/shared`).
- Use a workspace `Cargo.toml` at the repo root with `resolver = "2"`.

## Async runtime

- `tokio` with `rt` + `macros` features.
- `#[tokio::main]` in `main.rs`; `lambda_runtime::run(service_fn(handler)).await?`.
- For HTTP behind API Gateway / Function URL: `lambda_http` crate + `tower::ServiceBuilder` for middleware.
- For axum-on-Lambda: `axum::Router` wrapped in `lambda_http::run`.

## Serialization

- `serde` + `serde_json`. Use `#[serde(rename_all = "camelCase")]` for boundaries with JS callers.
- Define request/response types as plain structs; don't reuse domain types at the API boundary if they leak internals.

## AWS SDK

- `aws-sdk-*` (the v3 Rust SDK). Reuse `Client` instances at module scope or `OnceCell`.
- `aws-config::load_from_env()` once per cold start.

## Errors

- `thiserror` for library crates; `anyhow` only at the binary boundary.
- Map domain errors to HTTP status in a single `IntoResponse` impl.

## Observability

- `tracing` + `tracing-subscriber`. Emit JSON logs (`tracing-subscriber` with `json()` formatter).
- Include `request_id` from the Lambda context as a span field.
- **EMF metrics**: there is no official AWS Powertools for Rust crate (Powertools ships Python/TS/Java/.NET only). Either use a community crate (e.g. `lambda-powertools` on crates.io — community-maintained, evaluate before adopting) or hand-roll EMF by printing structured JSON to stdout in the EMF schema.

## Memory & cold start

- 512 MB is a fine starting point; benchmark and scale based on observed CPU.
- Cold starts on Graviton + `release` build typically 50-150ms for a small handler.
- Heavy deps (regex compilation, deserializers) at module scope so they amortize across warm invocations.

## Testing

- Unit tests inside each crate (`#[cfg(test)] mod tests`).
- Integration tests in `tests/` against a moto-style stub or local DynamoDB.
- For Lambda HTTP: `lambda_http::Request` can be constructed in tests; assert against the `Response`.

## Deploy

- `cargo lambda deploy <fn-name>` for ad-hoc; CDK + `cdk-aws-lambda-rust` (or pre-built zip) for IaC.
- CDK: bundle the zip from `target/lambda/<name>/bootstrap` as `Code.fromAsset()`.

## Pitfalls

- Forgetting `--arm64` and shipping x86 → silent 2-3x slower & more expensive.
- Linking against system OpenSSL — use `rustls-tls` features on http clients to stay portable.
- `tokio::main(flavor = "current_thread")` is usually fine and lighter than the default multi-thread.
- Calling `aws_config::load_from_env()` per invocation instead of once at cold start — wastes ~100ms each call.
