# Data, auth, and event patterns

## DynamoDB — single-table design

One table per environment: `{prefix}-main-{env}`. Every item:

- `PK` (String), `SK` (String), `entityType` (String, for log/scan filtering)
- `PAY_PER_REQUEST`, `RemovalPolicy.RETAIN`, customer-managed KMS key, **PITR enabled**, **TTL attribute `ttl`** (epoch seconds), stream `NEW_AND_OLD_IMAGES` (enable only when a consumer exists — two-phase deploy)
- Three generic GSIs from day one: `GSI1`, `GSI2`, `GSI3` with `GSInPK`/`GSInSK` string keys. GSIs are multi-purpose (reverse lookups + entity-wide listings like `GSI3PK=ENTITY#ORDER`).

### Key conventions (adapt entities, keep the shapes)

```
Owner-scoped entity:    PK=USER#{userId}        SK=ORDER#{orderId}
Singleton per owner:    PK=USER#{userId}        SK=PROFILE / SUBSCRIPTION / SETTINGS
Child of an entity:     PK=ORDER#{orderId}      SK=ITEM#{itemId}
Time-ordered children:  PK=CONV#{convId}        SK=MSG#{isoTimestamp}#{msgId}
Reverse lookup:         GSI1PK=ORDER#{orderId}  GSI1SK=CONFIG   (find entity without knowing owner)
Entity-wide listing:    GSI3PK=ENTITY#ORDER     GSI3SK={createdAt}
Platform config/flags:  PK=PLATFORM             SK=FLAG#{key}
Uniqueness reservation: PK=SLUG#{slug}          SK=RESERVED     (conditional put, first-claim-wins)
Inbound dedup:          PK=SOURCE#{id}          SK=EVT#{externalEventId}  + ttl   (at-least-once webhook retries)
Append-only audit:      PK=ENTITY#{id}          SK=AUDITLOG#{isoTimestampMs}#{eventId}
Scheduled recheck:      PK=RECHECK#{dueDayUtc}  SK=ENTITY#{...}  (daily sweep Queries one partition, then deletes)
```

Idioms:
- **Uniqueness / dedup**: conditional `PutItem` with `attribute_not_exists(PK)`. A duplicate is a 200 no-op for webhook receivers.
- **Append-only logs**: `PutItem` + `attribute_not_exists(SK)`, never `UpdateItem`. Timestamp-in-SK gives lexicographic time-range Queries (`SK BETWEEN AUDITLOG#{from} AND AUDITLOG#{to}￿`) — no GSI needed.
- **State machines**: conditional status transitions (`ConditionExpression: status = :expected`) so duplicate worker invocations can't double-run.
- **Optimistic concurrency**: `update_item` conditioned on `updatedAt = :prev`, retry ~3× on `ConditionalCheckFailedException`.
- **TTL + grace**: `ttl = expiresAt + 7d grace` with lazy expiry checks in code; TTL rows for retention, audit rows with per-tier retention windows.
- Nested config objects can be stored as JSON-string attributes with parse/serialize in the repository mapper — cheaper than deep AttributeValue trees and schema-flexible.

### Repository layer (per service)

- One repository per entity; AWS client injected in the `Deps` struct (Rust) or constructor (TS).
- Key builders centralized: entity key functions in the service repo module; **cross-runtime key shapes** (when TS/Python workers share the table) live in `packages/shared-rust` with golden tests pinning byte-compatibility.
- Never let handlers touch DynamoDB. `handler → service → repository`, always.

## S3 buckets

- Naming: `{prefix}-{purpose}-{env}-{accountId}` (globally unique, IAM-scopable by pattern).
- Static-frontend buckets: `BLOCK_ALL` public access, CloudFront OAI/OAC access only, `DESTROY` removal.
- Data buckets (uploads, exports, vectors): versioned, CORS as needed, lifecycle IA → Glacier-IR, noncurrent-version expiry, and a **deny-unless-encrypted resource policy**.
- Export/DSAR buckets: private + object lifecycle expiry (e.g. 7 days) + presigned URLs minted on read (≤15 min), never stored.
- Prod-only archive bucket: Glacier/Deep-Archive lifecycle, multi-year expiry, RETAIN.

## Auth

### Identity: Cognito user pool per env

- Pool `{prefix}-users-{env}`: email sign-in, self-signup, `autoVerify email`, strong password policy, optional MFA, custom attributes for tier/role, groups `admin`/`user` with precedence.
- **PreSignUp Lambda trigger** rejects duplicate emails before the verification code is sent (avoids AliasExistsException-at-confirm). Scope the trigger's `ListUsers` to a wildcard pool ARN to break the pool⇄trigger circular dependency.
- Client: no secret, 1-h access/id tokens, 30-d refresh, `preventUserExistenceErrors`.

### Enforcement: in-handler JWT verification (not edge authorizers)

Function URLs are `authType: NONE`; the edge is CloudFront + WAF; **every service verifies JWTs itself**:

- **RS256 (user tokens)**: verify against Cognito JWKS by `kid` (cache keys ~1 h, one forced refresh on unknown kid), check `iss`, `aud`/`client_id`, `token_use`, `exp`/`nbf` with ~30 s clock skew.
- **HS256 (machine/secondary-principal tokens)**: signed with a shared `JWT_SECRET` from SSM; claims must carry the expected `role`. Used for principals that don't live in Cognito (e.g. external agents, service tokens).
- **API keys (data plane / public API)**: store only the SHA-256 at `PK=APIKEY-LOOKUP, SK=<sha256>`; consistent GetItem to verify; cache verdicts in-process ~60 s.
- **Internal service-to-service**: shared `INTERNAL_API_TOKEN` header, param from SSM; internal services get no CloudFront behavior at all.
- Map verified claims to a typed `AuthContext { user_id, roles, permissions }` and pass it down; role-based path-prefix allowlists in middleware.

### Multi-tenancy

Tenant boundary = **partition key**: everything hangs off `PK=USER#{userId}` (or `ORG#{orgId}` if you have organizations). Isolation is enforced by every repository call being scoped to the verified caller's ID — a GSI lookup must still be ownership-checked in the service layer before returning. Per-tenant third-party secrets go in SSM paths keyed by tenant ID, never in the table.

## Async & event-driven

### SQS worker pattern (the default for anything out-of-band)

Producer service → SQS queue → dedicated worker Lambda. Per queue:
- DLQ with `maxReceiveCount: 3` + a DLQ-depth alarm.
- `visibilityTimeout > worker timeout` (e.g. 960 s vs 870 s).
- `SqsEventSource` with `reportBatchItemFailures: true`; `batchSize` 1 for heavy jobs, ~5 for light fan-out.
- Free-tier/dev guard: a context flag that sets the event-source mapping `enabled: false` to stop empty long-polls.

Canonical workers:
- **Outbound webhooks**: message `{eventType, entityId, data, eventId, timestamp}`; worker loads subscriber configs from the table, filters by event, signs body **HMAC-SHA256**, POSTs, tracks delivery, auto-disables endpoints after N consecutive failures.
- **Push/notification sender**: SQS → web-push (VAPID) + FCM.

### DynamoDB Streams

Use **event-filter criteria on the EventSourceMapping** so the consumer only sees what it needs (e.g. only `REMOVE` events from `dynamodb.amazonaws.com` where `SK begins_with MSG#` and the old image has attachments → delete orphaned S3 objects on TTL expiry). Failures → `SqsDlq` onFailure. Remember: stream + consumer = two-phase deploy.

### EventBridge schedules

Rate rules for sweepers (idle cleanup every 2 min), cron for daily/monthly aggregation jobs. A daily job that must count things **exactly once** pairs the sweep with a transactional marker row (`COUNTED#` + increment in the same transaction, then delete the recheck row).

### Inbound third-party webhooks (Stripe/Meta/etc.)

1. Public route, **raw-body HMAC verification** first (`X-Hub-Signature-256` / `Stripe-Signature`) — reject unsigned; CloudFront behavior must use `ALL_VIEWER_EXCEPT_HOST_HEADER` so signature headers survive.
2. Dedup at-least-once retries with a conditional-put marker row (+ ttl); duplicates ack 200 as no-ops.
3. Do the real work async (persist → trigger internal Lambda invoke or SQS), keep the receiver fast.

## AI integration (when the app needs it)

- **Amazon Bedrock** via SDK; model IDs as env vars (never hard-coded); explicit transient-vs-permanent error-code sets with exponential backoff (3×).
- Streaming chat: Python + Lambda Web Adapter with `RESPONSE_STREAM` Function URL (see cdk-infrastructure.md §escape hatches) or Rust `lambda_http` streaming. SSE protocol: `data: {"type":"chunk|replace|meta|error|done"}\n\n`.
- Prompt safety: sanitize user input (strip control/invisible chars, escape angle brackets, strip known injection patterns), XML-delimited prompt structure, track token usage including cache read/creation.
