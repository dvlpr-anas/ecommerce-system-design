# Dead Letter Queues & Replay

## Purpose

Poison messages (unprocessable after max retries) route to per-topic DLQs per design-doc §7.6. Ops can inspect, fix the underlying cause, and replay. Without this, one bad event halts a partition consumer indefinitely.

## Inputs / Prerequisites

- DLQ topics created ([`../02-platform-services/kafka.md`](../02-platform-services/kafka.md))
- All consumers use `pkg/events` retry/DLQ helpers

## Tasks

1. [ ] Per-consumer DLQ routing: on `max_retries` reached, publish to `<topic>.dlq` with original payload + headers `x-dlq-reason`, `x-dlq-original-topic`, `x-dlq-error`, `x-dlq-retry-count`, `x-dlq-first-failed-at` (effort: M)
2. [ ] Build `cmd/dlq-replay/` CLI:
   - `dlq-replay list --topic order.events.dlq`
   - `dlq-replay inspect --offset <n>`
   - `dlq-replay drain --topic order.events.dlq --to order.events --filter ...`
 (effort: L)
3. [ ] Ops dashboard panel: DLQ message count per topic, alert if any DLQ non-empty for > 15 min (effort: M)
4. [ ] Runbook entry per service: "Event in DLQ" → how to inspect, fix, replay (template lives in [`../06-hardening/runbooks.md`](../06-hardening/runbooks.md)) (effort: M)
5. [ ] Replay safety: the original event_id is preserved so idempotent consumers do not double-process (effort: S)
6. [ ] Smoke test: deliberately publish a malformed event → it lands in DLQ → fix-and-replay flow restores happy path (effort: M)

## Deliverables

- `cmd/dlq-replay/` CLI checked into a shared `tools/` dir
- DLQ panels on Kafka Health dashboard
- Per-service "DLQ event" runbook

## Exit Criteria

- [ ] Malformed event lands in DLQ within 5 retries (~2 minutes)
- [ ] Replay CLI drains DLQ back into source topic and consumer processes successfully
- [ ] Alert fires when DLQ non-empty for > 15 min
- [ ] Replay does not duplicate side-effects (idempotency table)

## References

- Design doc: §7.6 Dead Letter Queues

## Risks & Open Questions

- Replay CLI is dangerous. Restrict access via RBAC on Kafka ACLs to platform-team service account.
- Long-term: consider a UI for DLQ inspection (Karapace / kowl / custom internal tool).
