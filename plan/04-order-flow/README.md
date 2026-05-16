# 04: Order Flow (Checkout Path)

## Goal

Implement the checkout Saga end-to-end. Four services (Order, Inventory, Payment, Notification) coordinated via Kafka choreography, transactional outbox for exactly-once semantics, full compensation on failure, DLQs for poison messages.

## Scope

**In scope:** services 5-8 from design-doc §4.1, the Saga choreography from §6.2, transactional outbox from §6.1, resilience patterns from §7, DLQ + replay tooling, bulkhead limits.

**Out of scope:** UI for checkout (phase 05), production hardening (phase 06).

## Prerequisites

- Phase 02 complete (Kafka topics, `pkg/outbox`, `pkg/events`, observability)
- Phase 03 complete OR proceeding in parallel, Order needs Cart contents on checkout

## Sub-files

- [`order-service.md`](./order-service.md)
- [`inventory-service.md`](./inventory-service.md)
- [`payment-service.md`](./payment-service.md)
- [`notification-service.md`](./notification-service.md)
- [`saga-choreography.md`](./saga-choreography.md)
- [`transactional-outbox.md`](./transactional-outbox.md)
- [`resilience-patterns.md`](./resilience-patterns.md)
- [`dlq-and-replay.md`](./dlq-and-replay.md)
- [`bulkhead-and-limits.md`](./bulkhead-and-limits.md)

## Phase exit criteria

- [ ] Happy path: `POST /orders/checkout` → order.created → inventory.reserved → payment.completed → order.confirmed → notification email sent. End-to-end < 5s p95 on dev
- [ ] Compensation path: simulated payment failure releases reserved stock and marks order CANCELLED
- [ ] Killing the Payment pod mid-flow eventually completes via retry or cleanly compensates (no stuck state)
- [ ] DLQ catches a deliberately poisonous event. Replay CLI re-injects after manual fix
- [ ] Idempotent event processing. Replaying any event twice does not double-charge, double-reserve, or double-confirm

## Risks

- Saga debugging is hard. Invest in request-id propagation through events (set `correlation_id` = order_id) before scale-up.
- External payment gateway is the slowest hop, 10s timeout (design-doc §7.3) means a checkout can take that long visible to the customer (but the 202 + async confirmation pattern decouples user-perceived latency).

## References

- Design doc: §4, §5, §6, §7
- ADR-005 Event backbone
