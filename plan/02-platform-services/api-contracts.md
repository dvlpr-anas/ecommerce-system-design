# API Contracts (OpenAPI)

## Purpose

Contract-first development per design-doc §8.1: OpenAPI 3.0 YAML is the source of truth for every service's HTTP API. Server stubs are generated for Go; TypeScript clients are generated for the three frontends. Hand-written handlers wire the generated interfaces. Versioning and response envelope rules from §8.2-§8.4 are enforced via the spec.

## Inputs / Prerequisites

- `taskfile.md`: `task codegen:openapi` task exists (stubbed)
- `shared-go-libs.md`: `pkg/httputil` defines the response envelope

## Tasks

1. [ ] Choose generators: `oapi-codegen` for Go server stubs, `openapi-typescript` + Zod for TS client — effort: S
2. [ ] Implement `task codegen:openapi` script that:
   - finds every `services/*/api/openapi.yaml`
   - runs `oapi-codegen` → `services/<svc>/internal/handler/generated.go`
   - aggregates into `packages/api-client-ts/src/<svc>.ts` with Zod schemas
   — effort: L
3. [ ] Author shared OpenAPI components in `api-gateway/openapi-shared.yaml`:
   - standard envelope (`Envelope<T>`, `Error`)
   - cursor pagination params
   - error codes enum
   - standard headers (`X-Request-ID`)
   — effort: M
4. [ ] Add CI step that lints every spec with `spectral` against a project ruleset (require `Envelope` response, cursor pagination, version prefix `/api/v1`) — effort: M
5. [ ] Codegen pre-commit hook: regenerate clients before commit if spec changed — effort: S
6. [ ] Versioning rules documented in `api-gateway/README.md`:
   - URL path versioning (`/api/v1`, `/api/v2`)
   - Non-breaking additions allowed in current version
   - Old versions supported for 2 release cycles with `Deprecation` header
   — effort: S
7. [ ] Backwards-compat check: spec diff in PR CI uses `oasdiff` to detect breaking changes; PR must add new version or label `breaking-change-approved` — effort: M

## Deliverables

- `task codegen:openapi` working end-to-end on a stub spec
- `api-gateway/openapi-shared.yaml` with envelope + pagination + errors
- Spectral ruleset under `api-gateway/.spectral.yaml`
- `oasdiff` CI check
- `packages/api-client-ts/` populated by codegen

## Exit Criteria

- [ ] Adding a route to a stub spec, running `task codegen:openapi`, produces both Go stubs and a TS client without manual edits
- [ ] A PR that breaks an API without bumping the version fails CI
- [ ] Spectral CI rejects a spec missing the standard envelope

## References

- Design doc: §8 API Design Strategy (all subsections)

## Risks & Open Questions

- Hand-written server logic can drift from spec — enforce by failing CI when generated `*.go` files are stale relative to spec.
- `expo-router` typed routes and OpenAPI client coexistence — verify in `05-frontends/mobile-app.md`.
