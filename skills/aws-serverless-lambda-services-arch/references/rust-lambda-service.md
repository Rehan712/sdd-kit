# Rust Lambda service — the default runtime

Every backend service is a **Rust binary Lambda** unless a row in SKILL.md §"Runtime decision table" says otherwise. Patterns below are lifted from a production Rust-on-Lambda platform and the `aws-lambda-router` crate.

## Cargo workspace layout

One cargo workspace at the repo root, embedded in the wider monorepo:

```toml
# Cargo.toml (repo root)
[workspace]
resolver = "2"
members = ["services/*", "packages/shared-rust"]

[workspace.package]
edition = "2021"
rust-version = "1.80"

[workspace.dependencies]        # single source of truth for versions
lambda_http = "0.13"
lambda_runtime = "0.13"
aws-lambda-router = "0.1"       # Express-like routing (path params, middleware, CORS)
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json", "env-filter"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
thiserror = "2"
aws-config = "1"
aws-sdk-dynamodb = "1"
shared-rust = { path = "packages/shared-rust" }

[profile.release]               # cold-start critical — do not soften
opt-level = 3
lto = "fat"
codegen-units = 1
strip = true
panic = "abort"
```

`rust-toolchain.toml`: pin `channel = "stable"`, targets `aarch64-unknown-linux-gnu`, components `rustfmt`, `clippy`.

## Service crate anatomy

One directory per service, one binary named `bootstrap` (cargo-lambda convention):

```
services/<name>-service/
├── Cargo.toml            # [[bin]] name = "bootstrap", path = "src/main.rs"
└── src/
    ├── main.rs           # tracing init + router registration + lambda_http::run
    ├── handlers/*.rs     # route handlers — parse/validate, call service, shape response
    ├── services/*.rs     # business logic — returns Result<T, ServiceError>
    ├── repositories/*.rs # DynamoDB access — AttributeValue in/out, key builders
    ├── models.rs         # serde structs: API shapes (camelCase) + item shapes
    ├── auth.rs           # JWT verification / API-key lookup middleware
    └── error.rs          # ServiceError (thiserror) → HTTP status mapping
```

```toml
# services/<name>-service/Cargo.toml
[package]
name = "<name>-service"
version = "0.1.0"
edition.workspace = true

[[bin]]
name = "bootstrap"
path = "src/main.rs"

[dependencies]
lambda_http = { workspace = true }
aws-lambda-router = { workspace = true }
tokio = { workspace = true }
# ...pull everything from { workspace = true }; declare only service-specific deps here
```

**Layering rule (same as the TS platform): `handler → service → repository`. Never skip layers.**

## main.rs skeleton

```rust
use lambda_http::{run, service_fn, Body, Error, Request, Response};

mod auth;
mod error;
mod handlers;
mod models;
mod repositories;
mod services;

// Clients built once per container, reused across warm invocations.
pub(crate) struct Deps {
    pub table: String,
    pub ddb: aws_sdk_dynamodb::Client,
}

async fn build_deps() -> anyhow::Result<Deps> {
    let cfg = aws_config::load_from_env().await;
    Ok(Deps {
        table: std::env::var("TABLE_NAME")?,
        ddb: aws_sdk_dynamodb::Client::new(&cfg),
    })
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    static DEPS: tokio::sync::OnceCell<Deps> = tokio::sync::OnceCell::const_new();
    let deps = DEPS
        .get_or_try_init(|| async { build_deps().await })
        .await
        .map_err(|e| -> Error { format!("init: {e}").into() })?;

    handlers::route(req, deps).await
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .json()
        .with_target(true)
        .with_current_span(false)
        .with_span_list(false)
        .without_time()          // CloudWatch stamps time already
        .with_max_level(tracing::Level::INFO)
        .init();
    run(service_fn(handler)).await
}
```

Routing options, in order of preference:
1. **`aws-lambda-router`** (published crate, Express-like: path params `:id`, middleware, CORS preflight) — use for services with >3 routes.
2. Hand-rolled `match (method, path)` — fine for 1–3 route services (health checks, webhook receivers).

## Error handling

Two-tier boundary, mirroring `ServiceError` from the TS platform:

```rust
// error.rs
#[derive(Debug, thiserror::Error)]
pub enum ServiceError {
    #[error("{0}")] Validation(String),      // → 400
    #[error("unauthorized")] Unauthorized,   // → 401
    #[error("{0}")] Forbidden(String),       // → 403
    #[error("{0} not found")] NotFound(String), // → 404
    #[error("{0}")] Conflict(String),        // → 409
    #[error(transparent)] Internal(#[from] anyhow::Error), // → 500 (logged, body redacted)
}
```

- `services/` and `repositories/` return `Result<T, ServiceError>`; use `anyhow::Context` on AWS SDK calls so failures carry the operation name.
- One `into_response(ServiceError) -> Response<Body>` mapper at the handler layer. Error bodies are **RFC-7807 problem+json**: `{"type","title","status","detail"}`.
- Success bodies: helpers `ok(json)`, `created(json)`, etc. **API JSON is camelCase** — `#[serde(rename_all = "camelCase")]` on every API-facing struct.

## DynamoDB access

- Hand-rolled `AttributeValue` mapping (or `serde_dynamo` if the team prefers — pick one per repo and stick with it).
- Key builders live in `packages/shared-rust` (e.g. `pk_user(user_id) -> "USER#{id}"`) so key shapes are compile-time-checked in one place. If keys must match another runtime byte-for-byte (TS/Python workers on the same table), pin them with golden unit tests in the shared crate.
- Idioms:
  - Query: `key_condition_expression("PK = :pk AND begins_with(SK, :prefix)")`
  - Uniqueness / dedup: conditional `PutItem` with `attribute_not_exists(PK)`
  - Append-only audit rows: `PutItem` + `attribute_not_exists(SK)`, never `UpdateItem`
  - Optimistic concurrency: `update_item` with `condition_expression("updatedAt = :prev")`, retry ~3× on `ConditionalCheckFailedException`
  - TTL: numeric `ttl` attribute (epoch seconds), enable TTL on the table

## Auth

- **JWT bearer**: verify with `jsonwebtoken` crate against the shared signing key (SSM-sourced, cached in `Deps`). Extract claims at the top of the handler (or as `aws-lambda-router` middleware); pass a typed `AuthContext { user_id, tenant_id, role }` down to services.
- **API-key data plane** (machine-to-machine): store SHA-256 of the key at `PK=APIKEY-LOOKUP, SK=<sha256>`; verify with a consistent `GetItem`; cache verdicts in-process ~60 s (`Mutex<HashMap>`).
- **Internal-only services**: shared `INTERNAL_API_TOKEN` header check; do not put the service behind CloudFront.

## Cold-start budget (defaults, don't regress)

- `provided.al2023` + ARM64 (Graviton) always.
- Release profile above (fat LTO, strip, panic=abort).
- All AWS clients behind `OnceCell`; never build a client per request.
- `reqwest` with `default-features = false, features = ["rustls-tls", "json"]` (no OpenSSL).
- In-process TTL caches for hot lookups (config flags, API keys, kill switches) instead of per-request DynamoDB/SSM hits.
- Optional OTEL: init only when `OTEL_EXPORTER_OTLP_ENDPOINT` is set; init failure logs a warning, never fatal.

## Testing

- Pure logic: co-located `#[cfg(test)]` unit tests; golden tests in `shared-rust` for anything that must stay byte-compatible across runtimes.
- CI gates (workspace-wide): `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace --locked`.
- Integration: run DynamoDB Local as a CI sidecar and point `aws_sdk_dynamodb` at it via `endpoint_url` when repository coverage matters.

## Streaming / special cases

- Response streaming (SSE/chat): `lambda_http` supports streaming responses on Function URLs with `invokeMode: RESPONSE_STREAM`; remember CloudFront `compress: false` on the streaming behavior or buffering breaks the stream.
- Non-HTTP triggers (SQS, DynamoDB Streams, EventBridge): use `lambda_runtime` + `aws_lambda_events` typed events instead of `lambda_http`; same `Deps`/`OnceCell` pattern applies.
