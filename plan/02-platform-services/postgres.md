# PostgreSQL

## Purpose

One PostgreSQL cluster, **strict database-level isolation per service** (ADR-004). Services never query another service's database — cross-service data flows only through Kafka events or REST. Provides per-service connection pooling, automated backups, PITR, and a read-replica strategy for read-heavy services.

## Inputs / Prerequisites

- `terraform-skeleton.md`: `modules/postgres/` exists and is applied to dev
- Sealed Secrets working (DB passwords stored encrypted)

## Tasks

1. [ ] Provision a single PG 16 cluster via Terraform (RDS or Cloud SQL) for dev, staging, prod environments — effort: M
2. [ ] Apply the per-service databases via a bootstrap migration: `user_db`, `product_db`, `pricing_db`, `order_db`, `inventory_db`, `payment_db` — effort: M
3. [ ] Create per-service Postgres roles with privileges scoped to their own database only — effort: M
4. [ ] Decide on connection pooling: in-cluster PgBouncer (per-service sidecar) vs RDS Proxy / GCP Cloud SQL Auth Proxy. Default: **PgBouncer sidecar** for portability — effort: M
5. [ ] Configure PITR with 7-day retention in dev/staging, 30-day in prod — effort: S
6. [ ] Configure automated daily snapshots; verify a restore-to-new-instance drill (also exercised in `06-hardening/disaster-recovery.md`) — effort: M
7. [ ] Add read replica for `product_db` (read-heavy: catalog browse, search) — effort: M
8. [ ] Set extension allow-list: `pg_stat_statements`, `pgcrypto`, `pg_trgm` (for ILIKE fallbacks), and the built-in `tsvector` (no extension needed) — effort: S
9. [ ] Configure `pg_stat_statements` and slow-query logging (>500ms) — effort: S
10. [ ] Sealed secrets for each service's DB credentials — effort: S

## Deliverables

- Terraform-managed PG cluster per environment
- Bootstrap migration creating the six DBs and roles
- PgBouncer sidecar manifest template under `k8s-manifests/base/pgbouncer/`
- Read replica for `product_db`
- Per-service sealed secrets with `DATABASE_URL`

## Exit Criteria

- [ ] `\l` in psql shows the six per-service DBs
- [ ] Service role for `user_db` cannot SELECT from `order_db` (`permission denied`)
- [ ] `pg_stat_statements` returns query stats
- [ ] PITR restore-to-new-instance completes within RTO target (verified once)
- [ ] Read replica lag < 1s under nominal load

## References

- Design doc: §4.2 Database-per-Service Strategy, §12.1 Horizontal Scaling (PG row)
- ADR-004 Database strategy

## Risks & Open Questions

- Single shared cluster means a runaway query in one service can starve others. Mitigate via per-role connection limits and per-PgBouncer pool sizes. Revisit if noisy-neighbor incidents occur.
- Schema migrations run as K8s Jobs from each service (see [`../06-hardening/db-migration-strategy.md`](../06-hardening/db-migration-strategy.md)) — the platform layer only provisions DBs, not schemas.
