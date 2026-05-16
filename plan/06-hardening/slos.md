# SLOs

## Purpose

Define measurable, customer-facing service level objectives per service. SLOs anchor alerting, capacity planning, and the error budget that gates risky launches.

## Inputs / Prerequisites

- All services emitting `http_requests_total` and `http_request_duration_seconds` ([`../02-platform-services/observability-metrics.md`](../02-platform-services/observability-metrics.md))
- Load profile from design-doc §12.3 known

## Tasks

1. [ ] Per-service SLOs (initial targets, refine after load test):
   - **User Service**: availability 99.9%, p95 < 200ms (28-day window)
   - **Product Service** (browse): availability 99.95%, p95 < 250ms; (search) p95 < 400ms
   - **Pricing Service**: availability 99.95%, p95 < 150ms
   - **Cart Service**: availability 99.9%, p95 < 200ms
   - **Order Service** (`POST /checkout`): availability 99.9%, p95 < 500ms (returns 202)
   - **Inventory Service** (consumer-only public surface): admin endpoints availability 99.5%
   - **Payment Service**: availability 99.9%, p95 < 1000ms (includes Stripe round-trip in checkout)
   - **Notification Service**: end-to-end "PaymentCompleted → email sent" p95 < 30s, 99.9% success
   — effort: M
2. [ ] Saga SLO: `saga_duration_seconds` p95 < 5s, success rate > 99.5% — effort: S
3. [ ] Error budget policy: if monthly budget exhausted, freeze risky launches and route engineering effort to reliability — effort: S
4. [ ] Encode SLOs as Prometheus recording rules (`slo:availability:ratio`, `slo:latency:p95`) — effort: M
5. [ ] Per-SLO error budget burn-rate alerts (multi-window: fast + slow) — effort: M
6. [ ] SLO dashboard in Grafana with green/yellow/red per service — effort: M

## Deliverables

- `infra/observability/slos.yaml` (or equivalent) as code
- Recording rules + burn-rate alerts
- SLO dashboard

## Exit Criteria

- [ ] SLO dashboard renders with real data
- [ ] A synthetic SLO breach triggers the burn-rate alert
- [ ] Error budget policy is documented and acknowledged by the team

## References

- Design doc: §10 Observability, §12.3 Load Profile

## Risks & Open Questions

- These are starting targets; revisit after first month of prod traffic and adjust based on actual customer impact.
- Inventory + Notification have no public REST surface; their SLOs are internal (saga participation correctness, end-to-end notification latency).
