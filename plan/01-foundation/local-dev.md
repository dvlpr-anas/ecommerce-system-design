# Local Development Stack

## Purpose

A single `task up` boots the entire backing stack locally so engineers can run any service against real Postgres / Redis / Kafka / Keycloak / Kong without a cloud account. Critical for fast inner-loop development.

## Inputs / Prerequisites

- Docker Desktop or Colima with ≥ 8 GB RAM allocated
- `taskfile.md` complete (provides the `task up` shortcut)

## Tasks

1. [ ] Author `docker-compose.dev.yml` at repo root with services: `postgres:16`, `redis:7`, `kafka:3.7` (KRaft mode, single broker), `keycloak:24` (dev mode, h2 backed), `kong:3.6` (DBless mode), `prometheus`, `grafana` — effort: L
2. [ ] Add init scripts: `infra/dev/postgres-init.sql` creating per-service databases (`user_db`, `product_db`, `pricing_db`, `order_db`, `inventory_db`, `payment_db`) and a non-root role per DB — effort: M
3. [ ] Add `infra/dev/kong.yaml` declarative config with hello-world routes — replaced fully in `02-platform-services/kong-gateway.md` — effort: S
4. [ ] Add `infra/dev/keycloak-realm.json` minimal realm export — replaced in `02-platform-services/keycloak.md` — effort: S
5. [ ] Add named volumes for Postgres, Kafka, Keycloak so data survives `task down` — effort: S
6. [ ] Add healthchecks on every service so dependents wait correctly — effort: M
7. [ ] Document required `/etc/hosts` entries (`api.local`, `auth.local`) in root README — effort: S

## Deliverables

- `docker-compose.dev.yml` at repo root
- `infra/dev/` directory with init scripts and dev configs
- `task up` and `task down` shortcuts

## Exit Criteria

- [ ] `task up` returns within 90s with all containers healthy
- [ ] `psql -h localhost -U postgres -l` shows the six per-service databases
- [ ] `curl http://localhost:8001` returns Kong admin response
- [ ] `curl http://localhost:8080/realms/master` returns Keycloak realm metadata
- [ ] `kafka-topics --bootstrap-server localhost:9092 --list` works (no topics yet, exits 0)

## References

- Design doc: §2 Technology Stack, §13 Monorepo Management

## Risks & Open Questions

- Kafka in KRaft single-node mode for dev is fine but won't replicate prod's HA topology — flag this in `06-hardening/chaos-testing.md` so chaos tests are run against staging, not dev.
- Keycloak dev mode is not production-safe (h2 in-memory) — this is intentional for local; prod setup lives in `02-platform-services/keycloak.md`.
