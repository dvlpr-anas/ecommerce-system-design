# OpenAPI Codegen Pipeline (Frontend View)

## Purpose

The flip-side of [`../02-platform-services/api-contracts.md`](../02-platform-services/api-contracts.md) — how the generated TS client lands in `packages/api-client-ts`, how versions are pinned, and how frontends consume it. Same `task codegen:openapi` command; this sub-file owns the frontend integration.

## Inputs / Prerequisites

- `task codegen:openapi` produces TS output ([`../02-platform-services/api-contracts.md`](../02-platform-services/api-contracts.md))
- `packages/api-client-ts` exists

## Tasks

1. [ ] Output structure: one TS module per service (`packages/api-client-ts/src/user.ts`, `product.ts`, etc.) plus a root `index.ts` re-export — effort: S
2. [ ] Zod schemas alongside types for runtime validation (`UserSchema`, `ProductSchema`) — effort: S
3. [ ] Versioning: bump `packages/api-client-ts/package.json` patch on every regeneration, minor on additive spec changes, major on breaking — automated via a CI script reading `oasdiff` output — effort: M
4. [ ] Consumers use `workspace:*` so they always get the latest from the monorepo; in CI, a build step ensures `task codegen:openapi` produces no diff (specs and generated code in sync) — effort: M
5. [ ] Provide a thin `createClient({ baseUrl, getToken })` factory so all three apps build their auth-aware client uniformly — effort: S
6. [ ] Document client usage in `packages/api-client-ts/README.md` with code samples — effort: S
7. [ ] Telemetry: client wraps calls with a hook so each app can attach distributed-tracing headers — effort: M

## Deliverables

- Reliable, reproducible codegen
- CI guard catches stale generated files
- `createClient` factory used by all three apps

## Exit Criteria

- [ ] Running `task codegen:openapi` twice in a row produces no diff
- [ ] All three apps build against the latest generated client
- [ ] A breaking spec change without a major version bump fails CI

## References

- Design doc: §8 API Design Strategy

## Risks & Open Questions

- Generator choice (`openapi-typescript`, `orval`, `openapi-fetch`) — settle in [`../02-platform-services/api-contracts.md`](../02-platform-services/api-contracts.md); this sub-file inherits the choice.
