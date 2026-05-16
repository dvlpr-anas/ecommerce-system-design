# 02 — Platform Services

## Goal

Configure the cross-cutting platform components every microservice will use: identity (Keycloak), API gateway (Kong), data layer (Postgres, Redis), event backbone (Kafka), observability (Prometheus, Grafana, Loki), and the shared Go libraries that wire it all together.

## Scope

**In scope:** Keycloak realm + clients + roles, Kong declarative config + plugins, Postgres per-service DBs, Redis cluster, Kafka topics, slog/Prometheus/Grafana, `pkg/*` shared Go libs, OpenAPI codegen workflow.

**Out of scope:** Any business logic in services (phases 03/04), client apps (phase 05).

## Prerequisites

- Phase 01 complete: cluster up, Sealed Secrets working, Taskfile in place

## Sub-files

- [`keycloak.md`](./keycloak.md)
- [`kong-gateway.md`](./kong-gateway.md)
- [`postgres.md`](./postgres.md)
- [`redis.md`](./redis.md)
- [`kafka.md`](./kafka.md)
- [`shared-go-libs.md`](./shared-go-libs.md)
- [`observability-logging.md`](./observability-logging.md)
- [`observability-metrics.md`](./observability-metrics.md)
- [`observability-dashboards.md`](./observability-dashboards.md)
- [`api-contracts.md`](./api-contracts.md)

## Phase exit criteria

- [ ] Kong validates a Keycloak-issued JWT and routes to a hello-world pod
- [ ] A test producer writes to `order.events`; a test consumer reads from it
- [ ] Grafana shows golden-signal dashboards for the hello-world service
- [ ] `pkg/events/` defines the four event topic structs and is consumed by a smoke test
- [ ] `task codegen:openapi` runs against a stub OpenAPI spec and produces a Go server stub + TS client

## Risks

- Keycloak operator vs Helm install: pick one early. Helm is simpler; operator gives declarative realms but adds CRD overhead.
- Kafka ops are non-trivial — start with MSK/Confluent Cloud rather than self-hosted Strimzi unless cost forces it.

## References

- Design doc: §3 Architecture Diagrams, §4 Core Microservices, §5 Event Backbone, §10 Observability
- ADR-002, ADR-004, ADR-005, ADR-007
