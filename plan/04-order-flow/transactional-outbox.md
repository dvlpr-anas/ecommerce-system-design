# Transactional Outbox

## Purpose

Guarantee atomicity between database state changes and Kafka event publishing without two-phase commit. Pattern from design-doc §6.1: within one DB transaction, write the state change and an `outbox` row; a poller publishes outbox rows to Kafka and marks them as published.

## Inputs / Prerequisites

- `pkg/outbox` library exists ([`../02-platform-services/shared-go-libs.md`](../02-platform-services/shared-go-libs.md))
- Each service has its own `outbox` table in its DB
- Kafka topic ACLs allow the service to write its event topic

## Tasks

1. [ ] Standardize the `outbox` table schema across services:
   ```sql
   CREATE TABLE outbox (
     id BIGSERIAL PRIMARY KEY,
     event_id UUID NOT NULL UNIQUE,
     event_type TEXT NOT NULL,
     payload JSONB NOT NULL,
     headers JSONB,
     published BOOLEAN NOT NULL DEFAULT false,
     published_at TIMESTAMPTZ,
     created_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   CREATE INDEX outbox_unpublished_idx ON outbox (created_at) WHERE published = false;
   ```
   — effort: S
2. [ ] Wire `pkg/outbox.Poller` in every Order, Inventory, Payment, Product service (Notification is read-only) — effort: M
3. [ ] Poller config: poll every 500ms, batch size 100, mark `published=true` after Kafka ack — effort: S
4. [ ] Cleanup job (K8s CronJob): delete rows where `published=true AND published_at < now() - INTERVAL '7 days'` — effort: S
5. [ ] Metric `outbox_pending_count` emitted; alert when > 1k or oldest unpublished > 60s — effort: M
6. [ ] Event ID is generated at insert and used as Kafka message key OR header for downstream idempotency — effort: S
7. [ ] Failure mode: if Kafka unreachable, poller backs off (exponential) and emits `outbox_publish_failures_total` — effort: M

## Deliverables

- Standardized `outbox` schema in every producer service
- Poller running with metrics visible on dashboard
- Cleanup CronJob
- Alert on outbox lag

## Exit Criteria

- [ ] Killing the Kafka broker for 30s does not lose events — they backlog in outbox, then drain after broker returns
- [ ] `outbox_pending_count` is < 10 under nominal load
- [ ] Cleanup job actually reduces row count week-over-week
- [ ] Two pollers running in parallel (HA) do not double-publish (SELECT ... FOR UPDATE SKIP LOCKED)

## References

- Design doc: §6.1 Transactional Outbox Pattern
- ADR-005 Event backbone

## Risks & Open Questions

- SELECT ... FOR UPDATE SKIP LOCKED is required for multi-replica poller HA. Implement in `pkg/outbox.Poller`; unit-test the locking behavior.
- Outbox table grows fast; partition by month if cleanup can't keep up.
