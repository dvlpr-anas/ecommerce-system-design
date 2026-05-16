# Load Testing

## Purpose

Prove the platform sustains design-doc §12.3 load: steady ~1k concurrent users / ~200 orders/min, peak ~10k / ~2k. Surfaces capacity bottlenecks before customers do; validates HPA + pool sizing from [`../04-order-flow/bulkhead-and-limits.md`](../04-order-flow/bulkhead-and-limits.md).

## Inputs / Prerequisites

- Staging environment sized similarly to prod
- All services deployed; observability live
- Stripe test mode (Payment uses test cards)

## Tasks

1. [ ] k6 scripts under `tests/load/`:
   - `browse.js` — homepage + category + PDP browsing (read-heavy)
   - `search.js` — search query distribution
   - `cart-add.js` — anon + auth cart adds
   - `checkout.js` — full checkout flow (limited rate to avoid Stripe rate caps)
   - `admin-ops.js` — moderate admin operations in parallel
   — effort: L
2. [ ] Scenarios: steady-state (sustain 60 min at 1k VU / 200 orders/min), peak (ramp to 10k VU / 2k orders/min over 10 min, sustain 30 min) — effort: M
3. [ ] Run from a dedicated load-test runner pool (k6 cloud or k6 operator on a separate K8s cluster) — effort: M
4. [ ] Capture: SLO compliance during test, max RPS before SLO breach, bottleneck identification (CPU, DB conns, Kafka lag) — effort: M
5. [ ] Refine resource limits + HPA max replicas from results; re-run until peak sustains within SLO — effort: L
6. [ ] Document the test recipe + last-known-good results in `tests/load/README.md` — effort: S
7. [ ] Establish a "load test before major release" gate in [`../07-launch/pre-launch-checklist.md`](../07-launch/pre-launch-checklist.md) — effort: S

## Deliverables

- k6 scripts checked in
- Last-known-good baseline results stored (date, commit, scenario, p95s)
- Tuned resource limits + HPA configs

## Exit Criteria

- [ ] Steady-state test runs 60 min with zero SLO breaches
- [ ] Peak test runs 30 min with zero SLO breaches AND HPA does not max out (has headroom)
- [ ] Saga p95 < 5s under peak (excluding Stripe variability)
- [ ] No DLQ messages produced during the test (other than deliberate negative scenarios)

## References

- Design doc: §12.3 Load Profile, §12.2 Bottleneck Analysis

## Risks & Open Questions

- Synthetic load looks unlike real traffic — repeat with shadow traffic from a recorded session if possible.
- Stripe test mode has rate limits; cap checkout scenario or mock Stripe at the Payment Service boundary for load.
