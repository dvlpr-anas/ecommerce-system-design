# Shared Go Libraries (`pkg/*`)

## Purpose

Every Go service must consume the same auth middleware, request-ID propagation, structured logger, Prometheus middleware, circuit-breaker wrapper, outbox poller, and HTTP response envelope. Build these once in `pkg/*` so phases 03 and 04 add services without duplicating plumbing.

## Inputs / Prerequisites

- `monorepo-structure.md` complete (`pkg/` exists)
- `kafka.md` complete (event topics decided)
- `keycloak.md` complete (JWT structure known)

## Tasks

1. [ ] `pkg/events/`, Go structs for every event (`OrderCreated`, `StockReserved`, `StockReleased`, `PaymentCompleted`, `PaymentFailed`, etc.). JSON Schema files alongside. Producer/consumer helpers that validate on encode/decode (effort: L)
2. [ ] `pkg/outbox/`. Generic outbox poller: takes a `*sql.DB`, a Kafka producer, polls `outbox` table for unpublished rows, publishes them, marks as published. Idempotent. Exposes Prometheus `outbox_pending_count` (effort: L)
3. [ ] `pkg/circuitbreaker/`. Thin wrapper around `sony/gobreaker` with config matching design-doc §7.1 (5 failures → open, 30s timeout, 3 successes → close). Exposes `circuit_breaker_state` metric (effort: M)
4. [ ] `pkg/middleware/`, Gin middlewares: `RequestID` (read or generate `X-Request-ID`), `Logger` (slog with request_id, user_id, duration_ms), `Metrics` (`http_requests_total`, `http_request_duration_seconds`), `Auth` (validate JWT against Keycloak JWKS, populate context with claims), `Recover` (panic → 500 + slog error) (effort: L)
5. [ ] `pkg/httputil/`. Response envelope helpers per design-doc §8.3 (`Respond`, `RespondError`), cursor pagination helpers per §8.4 (encode/decode cursor as base64 JSON) (effort: M)
6. [ ] `pkg/httpserver/`. Opinionated Gin server factory: applies all standard middleware in the right order, exposes `/healthz`, `/readyz`, `/metrics` (effort: M)
7. [ ] `pkg/db/`. Sqlx wrapper, migration runner (goose), per-query context timeout (default 5s), connection pool config (effort: M)
8. [ ] `pkg/idempotency/`, `processed_events` table helper (insert-on-conflict-skip per design-doc §7.4), idempotency-key middleware for external API calls (effort: M)
9. [ ] Unit-test every package to ≥ 80% coverage (effort: L)
10. [ ] Publish a `pkg/CHANGELOG.md` and version-tag breaking changes. Services pin a version (effort: S)

## Deliverables

- Go modules under `pkg/` for each of the eight packages
- Test suites and coverage reports in CI
- `pkg/CHANGELOG.md`

## Exit Criteria

- [ ] A throwaway "hello-world" service in `services/hello-service/` can be assembled in < 50 lines by importing `pkg/httpserver`, `pkg/middleware`, `pkg/httputil`
- [ ] `pkg/outbox` poller round-trip works against local Postgres + Kafka in `task up`
- [ ] `pkg/events` validator rejects a malformed event payload
- [ ] CI coverage report ≥ 80% per package

## References

- Design doc: §5.2 Schema Enforcement, §6.1 Transactional Outbox, §7 Resilience, §8.3-§8.4 API standards, §10 Observability

## Risks & Open Questions

- Versioning shared libs in a monorepo is annoying. Adopt `replace` directives in `go.work` for dev, semver tags for prod. Document in `pkg/README.md`.
- `pkg/middleware/Auth` calls Keycloak JWKS on cold start. Cache aggressively (in-process, 1h TTL).
