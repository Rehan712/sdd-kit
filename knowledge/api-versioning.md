# API versioning

How public APIs across these projects evolve without breaking callers.

## Default: additive evolution

Most changes are additive and don't need a version bump:

- **New endpoint** → ship it. No version change.
- **New optional field in request** → ship it. Server defaults if absent.
- **New field in response** → ship it. Clients ignore unknown fields (and should).
- **New error code** → ship it. Clients should default to generic error handling.

## When a version bump is required

- Removing a field from a response.
- Changing the type of a field (e.g., `string` → `number`).
- Making a previously-optional request field required.
- Changing semantics of an existing field.
- Changing an error code's meaning.
- Restructuring response shape.

## Versioning strategy

- **URL path versioning**: `/v1/...`, `/v2/...`. Pragmatic, cacheable, debuggable. Default choice.
- **Header versioning** (`Accept: application/vnd.foo.v2+json`) only when the API is consumed by a sophisticated client that already does content negotiation.
- Never query-string versioning (`?v=2`) — proxies and caches misbehave.

## Deprecation

- Mark deprecated endpoints in the OpenAPI spec with `deprecated: true`.
- Add a `Sunset` header with the planned retirement date.
- Announce to known callers ≥30 days before removing.
- Log every call to a deprecated endpoint with the caller's identity (auth context) so we know who needs migration.

## Breaking changes in event payloads (SNS, EventBridge, Kinesis)

- Version events too: include a `version: 1` field in the envelope.
- Subscribers fan out by version where possible (separate queue per version).
- Schema registry (EventBridge Schema Registry, Confluent, or homegrown JSON Schemas in a repo) prevents drift.

## RTK Query / OpenAPI codegen consumers

When the backend bumps a version:

1. Backend ships new endpoints at `/v2/...` alongside `/v1/...`.
2. Frontend regenerates against the new OpenAPI spec.
3. Frontend migrates call sites endpoint-by-endpoint (the type errors guide the migration).
4. Backend retires `/v1/...` after the frontend ships and stabilizes.

## What we DON'T do

- We don't ship two parallel implementations for years. Pick a sunset date and hold it.
- We don't try to maintain "compatibility shims" forever — they accumulate bugs faster than they prevent them.
- We don't release breaking changes without a version bump because "no one is calling that yet" — someone always is.
