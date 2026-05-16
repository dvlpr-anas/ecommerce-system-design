# 02: Platform Services (Local)

## Goal

Configure the cross-cutting platform components every microservice will use, **all running locally via `docker-compose.dev.yml`**: identity (Keycloak), API gateway (Kong), data layer (Postgres, Redis), event backbone (Kafka), observability (Prometheus, Grafana, Loki), plus the shared Go libraries and OpenAPI codegen that wire it all together.

Cloud-managed equivalents (RDS, MSK or Confluent, GKE-hosted Keycloak, managed Grafana, etc.) are explicitly **out of scope here**. They are provisioned in [`../07-cloud-infrastructure/`](../07-cloud-infrastructure/) and the services are pointed at them in [`../08-cloud-deployment/`](../08-cloud-deployment/) via config swap.

## Scope

**In scope (local):** Keycloak realm plus clients plus roles, Kong declarative config plus plugins, per-service Postgres schemas, single-node Redis, single-broker Kafka (KRaft), slog, Prometheus, Grafana, Loki, `pkg/*` shared Go libs, OpenAPI codegen workflow. All on docker-compose.

**Out of scope:** managed cloud equivalents, HA topologies, multi-AZ, TLS via cert-manager, business logic (phases 03 and 04), client apps (phase 05).

## Prerequisites

- Phase 01 complete: `task up` boots an empty docker-compose stack on the host

## Sub-files

- [`keycloak.md`](./keycloak.md): runs as a docker-compose service. Realm imported on boot.
- [`kong-gateway.md`](./kong-gateway.md): runs in DB-less mode against a mounted declarative config
- [`postgres.md`](./postgres.md): single Postgres 16 container with init scripts for per-service schemas
- [`redis.md`](./redis.md): single-node Redis for dev (cluster mode deferred to cloud)
- [`kafka.md`](./kafka.md): single-broker Kafka in KRaft mode
- [`shared-go-libs.md`](./shared-go-libs.md)
- [`observability-logging.md`](./observability-logging.md): Loki plus Promtail in docker-compose
- [`observability-metrics.md`](./observability-metrics.md): Prometheus in docker-compose, scraping `host.docker.internal`
- [`observability-dashboards.md`](./observability-dashboards.md): Grafana provisioning via mounted dashboard JSON
- [`api-contracts.md`](./api-contracts.md): OpenAPI codegen via `task codegen:openapi`

## Phase exit criteria

- [ ] `task up` brings Keycloak, Kong, Postgres, Redis, Kafka, Prometheus, Grafana, Loki up healthy
- [ ] Kong validates a Keycloak-issued JWT and routes to a hello-world container
- [ ] A test producer writes to `order.events` on local Kafka, and a test consumer reads from it
- [ ] Grafana shows golden-signal dashboards for the hello-world service
- [ ] `pkg/events/` defines the four event topic structs and is consumed by a smoke test
- [ ] `task codegen:openapi` runs against a stub OpenAPI spec and produces a Go server stub plus TS client

## Risks

- Single-broker Kafka and single-node Redis hide failure modes (rebalance, replication lag). Document this and re-test those modes in phase 08 against the real cluster.
- docker-compose memory usage grows quickly. Recommend at least 12 GB allocated to Docker Desktop before starting phase 03.

## References

- Design doc: §3 Architecture Diagrams, §4 Core Microservices, §5 Event Backbone, §10 Observability
- ADR-002, ADR-004, ADR-005, ADR-007
