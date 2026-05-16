# Inventory Service

## Purpose

Stock management as event sourcing. Reserves stock on `OrderCreated`, releases on `PaymentFailed` or `OrderCancelled`. Append-only writes avoid row-lock contention on hot SKUs (design-doc §12.2). Owns `inventory_db`.

## Inputs / Prerequisites

- Phase 02 complete
- [`transactional-outbox.md`](./transactional-outbox.md) and Order Service event contracts agreed

## Tasks

1. [ ] OpenAPI (admin-only): `GET /inventory/{sku}`, `PATCH /inventory/{sku}` (restock), `GET /inventory` — effort: M
2. [ ] DB migrations:
   - `events` (id BIGSERIAL, sku, event_type, qty_delta, order_id, created_at — append-only)
   - `inventory_snapshot` (sku PK, available_qty, reserved_qty, updated_at) — projection
   - `outbox`, `processed_events`
   — effort: M
3. [ ] Snapshot rebuilder job — replays `events` into `inventory_snapshot`. Run on every deploy as part of K8s Job — effort: M
4. [ ] Kafka consumer `order.events`:
   - `OrderCreated` → atomically check `available_qty >= qty` per item, append `StockReserved` events, emit `inventory.reserved` via outbox. If any item insufficient → emit `inventory.reservation_failed`
   - `OrderCancelled` → append `StockReleased`, emit `inventory.released`
   — effort: L
5. [ ] Kafka consumer `payment.events`:
   - `PaymentFailed` → release reserved stock for that order (compensation)
   — effort: M
6. [ ] Idempotent processing via `processed_events` keyed on event_id — effort: S
7. [ ] Per-SKU partition affinity: produce `inventory.events` keyed by sku so a single consumer sees all events for one SKU (avoids races) — effort: S
8. [ ] Restock endpoint emits `StockReplenished` (admin-triggered) — effort: S
9. [ ] Manifests, HPA, ServiceMonitor, NetworkPolicy — effort: M
10. [ ] Tests: concurrent reservations on the same SKU resolve correctly (last-writer-wins via event ordering); compensation works — effort: M

## Deliverables

- Service deployed
- Snapshot rebuilder job
- Consumer groups for `order.events` and `payment.events`
- Outbox poller for `inventory.events`

## Exit Criteria

- [ ] `OrderCreated` for an in-stock item → `StockReserved` event within 1s
- [ ] Out-of-stock SKU → `inventory.reservation_failed` event → Order Service marks order CANCELLED
- [ ] `PaymentFailed` → reserved stock released; `available_qty` restored
- [ ] Replay of `events` reproduces `inventory_snapshot` exactly
- [ ] 100 concurrent reservations on the same 50-unit SKU result in exactly 50 successful reservations

## References

- Design doc: §4.1 (Inventory row), §5 Event Backbone, §6.2 Saga, §12.2 Bottleneck Analysis (Write contention row)

## Risks & Open Questions

- Hot-SKU contention: if a flash-sale SKU receives 1k orders/sec, a single partition consumer becomes a bottleneck. Mitigation: shard SKUs across partitions and accept eventual reconciliation; or batch-reserve. Decide before launch.
- Negative inventory protection: never let `available_qty` go below 0 — assertion in projection updater, alert on violation.
