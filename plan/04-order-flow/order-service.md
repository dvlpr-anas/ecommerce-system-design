# Order Service

## Purpose

Owns the order aggregate. Event-sourced: every state change is an append to `events`; current state lives in the `orders` projection. Initiates the checkout Saga, listens for inventory/payment events, transitions order status. Uses transactional outbox for atomic state-change + event emission.

## Inputs / Prerequisites

- Phase 02 complete (`pkg/events`, `pkg/outbox`, Kafka topics)
- Cart Service available (to fetch cart on checkout)
- Pricing Service available (to compute totals)
- [`transactional-outbox.md`](./transactional-outbox.md) and [`saga-choreography.md`](./saga-choreography.md) understood

## Tasks

1. [ ] Author `services/order-service/api/openapi.yaml`:
   - `POST /orders/checkout` (returns 202 + order_id)
   - `GET /orders/{id}` (status, items, totals)
   - `GET /orders` (cursor list, current user's orders)
   - Admin: `GET /orders` all-users, `POST /orders/{id}/cancel`, `POST /orders/{id}/refund`
   — effort: M
2. [ ] DB migrations:
   - `events` (id BIGSERIAL, order_id UUID, event_type, payload JSONB, created_at — append-only, partitioned by created_at month)
   - `orders` (id PK, user_id, status, total, currency, created_at, updated_at — projection)
   - `order_items` (order_id FK, sku, qty, unit_price)
   - `outbox` (id, event_type, payload, published BOOL, created_at)
   - `processed_events` (event_id PK, processed_at — idempotency table)
   — effort: L
3. [ ] Checkout handler:
   - Fetch cart from Cart Service
   - Validate prices via Pricing Service (re-quote at checkout)
   - In ONE transaction: append `OrderCreated` to `events`, upsert `orders`, insert outbox row → respond 202
   — effort: L
4. [ ] Outbox poller goroutine (from `pkg/outbox`) publishing to `order.events` — effort: S
5. [ ] Kafka consumers:
   - `inventory.events`: on `StockReserved` → status PENDING_PAYMENT; on `StockReleaseFailed` (compensation gone wrong) → ESCALATE
   - `payment.events`: on `PaymentCompleted` → status CONFIRMED; on `PaymentFailed` → status CANCELLED, emit `OrderCancelled` for compensation
   — effort: L
6. [ ] All consumers idempotent via `pkg/idempotency.processed_events` — effort: M
7. [ ] State-machine guard: only allowed transitions (CREATED → RESERVED → PAID → CONFIRMED, with CANCELLED branches) — effort: M
8. [ ] Kustomize manifests, HPA, ServiceMonitor, NetworkPolicy (egress to Kafka, Postgres, Cart, Pricing, Keycloak) — effort: M
9. [ ] Tests: event-sourcing replay test (rebuild projection from events), saga happy + compensation paths via testcontainers — effort: L

## Deliverables

- Service deployed
- Outbox poller running, lag < 5s
- Order projection consistent with event log
- Consumer groups visible on Kafka Health dashboard

## Exit Criteria

- [ ] `POST /api/v1/orders/checkout` returns 202 with `order_id` in < 200ms p95
- [ ] Order status visible via `GET /orders/{id}` after Saga completes
- [ ] Replay of events table reproduces current projection exactly
- [ ] Double-publishing the same `OrderCreated` event does not produce a duplicate order
- [ ] Killing Order during a checkout: order is either CONFIRMED or CANCELLED within 60s, never stuck

## References

- Design doc: §4.1 Service Catalog (Order row), §6.1 Transactional Outbox, §6.2 Saga, §7.4 Idempotency

## Risks & Open Questions

- Event-sourcing replay performance: bound events per order, snapshot every 100 events (deferred until measured).
- Reading the `orders` projection has stale-read risk relative to `events`. For `GET /orders/{id}` immediately after checkout, read from projection but also block-on outbox flush — or accept eventual consistency (preferred).
