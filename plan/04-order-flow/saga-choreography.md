# Saga Choreography

## Purpose

Wire the four services together via Kafka events to deliver checkout as a distributed transaction without a central orchestrator. The full sequence (happy path + compensation) is defined in design-doc §6.2. This sub-file is the operational checklist to make that diagram real.

## Inputs / Prerequisites

- Order, Inventory, Payment, Notification services exist (their per-service sub-files complete)
- Kafka topics provisioned (`02-platform-services/kafka.md`)
- `pkg/events` schemas finalized

## Tasks

1. [ ] Lock event contracts in `pkg/events/` and tag a version. Once shipped, schema changes follow expand-and-contract (effort: M)
2. [ ] Per service, document which events it produces and consumes in `services/<svc>/README.md` (effort: S)
3. [ ] Correlation: set `correlation_id = order_id` on every Saga event for end-to-end log tracing (effort: M)
4. [ ] Verify ordering guarantees: partition all Saga events by `order_id` so a single order's events are linearizable within a partition (effort: M)
5. [ ] Build an end-to-end Saga integration test under `tests/saga/`:
   - happy path
   - inventory.reservation_failed
   - payment.failed
   - payment timeout (gateway 10s deadline)
   - inventory.released failure (rare. Should escalate to ops)
 (effort: L)
6. [ ] Trace dashboard in Grafana: timeline view per order_id pulling from Loki (effort: M)
7. [ ] Saga health metric: `saga_duration_seconds` histogram per outcome (CONFIRMED, CANCELLED, STUCK) (effort: M)
8. [ ] Alert: any order in `PENDING_*` state for > 5 minutes (effort: S)

## Deliverables

- `tests/saga/` integration suite covering all branches
- Saga timeline dashboard
- Stuck-order alert

## Exit Criteria

- [ ] Happy path test passes consistently (100/100 runs in CI)
- [ ] Compensation paths verified: simulated payment failure → stock released within 60s, order CANCELLED
- [ ] Saga p95 duration < 5s on dev (without external Stripe latency)
- [ ] Alert fires on a deliberately stuck order

## References

- Design doc: §6.2 Choreography-based Saga (the sequence diagram is the source of truth. Do not duplicate here)
- ADR-005 Event backbone

## Risks & Open Questions

- A choreography saga is implicit. Understanding it requires tracing across topics. Mitigation: keep the design-doc diagram up-to-date with every event addition. Add a CI script that diffs `pkg/events` exports against the diagram's event list (catch silently-introduced events).
