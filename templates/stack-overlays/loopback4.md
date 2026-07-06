# Stack overlay: LoopBack 4

Read alongside `plan.md` when `stack.yml` includes `loopback4`.

## Layered architecture

- **Models** (`src/models/`): TypeScript classes decorated with `@model`, `@property`. Source of truth for shape.
- **Repositories** (`src/repositories/`): persistence layer. Use `DefaultCrudRepository` unless you genuinely need a custom one.
- **Datasources** (`src/datasources/`): connection config. Pull secrets from env or AWS Secrets Manager, never hard-code.
- **Controllers** (`src/controllers/`): HTTP layer. Decorate with `@get`, `@post`, `@requestBody`. Validate via spec, not in-handler `if` statements.
- **Services** (`src/services/`): cross-cutting business logic; injected into controllers.
- **Sequence** (`src/sequence.ts`): request pipeline. Customize for auth, logging, error mapping.

## OpenAPI

- LB4 generates OpenAPI from controller decorators — **the spec is the source of truth**. Frontend clients (e.g. RTK Query OpenAPI codegen) should regenerate from `/openapi.json` after backend changes.
- Run `npm run openapi-spec` (or equivalent) in CI to detect schema drift.

## Validation

- Request body shapes come from `@model` definitions via `getModelSchemaRef`. Don't write parallel zod schemas — let LB4 generate the JSON Schema.
- Use `@param.query.string`, `@param.path.number`, etc. for type-safe params.

## Auth

- `@authenticate('jwt')` (or your strategy name) on the controller class or method.
- Don't roll your own — extend `loopback4-authentication` or `@loopback/authentication-jwt`.
- Roles via `@authorize({ allowedRoles: ['admin'] })`.

## Testing

- **Unit:** `@loopback/testlab` for repositories with a stub datasource.
- **Acceptance:** spin up the app against an in-memory datasource (`memory`) or testcontainers Postgres/Mongo; hit real endpoints.
- **Don't mock the database** for migration-sensitive tests.

## Deployment

- Docker image; multi-stage build keeping the runtime slim.
- Behind Nginx or API Gateway. Health endpoint at `/health` (LB4 boots one for you).
- Logs are JSON to stdout; container runtime ships to CloudWatch.

## Pitfalls

- Forgetting to register a repository in `application.ts` → cryptic DI error at runtime.
- Decorators on inherited methods sometimes silently fail — keep route decorators on the subclass method.
- `@belongsTo` / `@hasMany` relations need the inclusion resolver registered to actually populate.
- Default `@property({type: 'string'})` accepts `null`. Add `required: true` to forbid it.
