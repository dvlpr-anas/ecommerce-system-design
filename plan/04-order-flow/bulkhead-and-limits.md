# Bulkhead & Resource Limits

## Purpose

A runaway service cannot starve others. Per design-doc §7.7, every K8s Deployment has CPU/memory `requests` and `limits`; every HTTP client has a bounded pool per downstream; every DB connection pool is sized to fit. Codified per service here as a checklist.

## Inputs / Prerequisites

- All Saga services deployed (this is configuration, applied last)
- Cluster has metrics-server installed for HPA

## Tasks

1. [ ] Set Pod resource `requests` and `limits` for every service. Initial sizing from order-of-magnitude analysis (refined in `06-hardening/load-testing.md`):
   - User: 100m/256Mi requests, 500m/512Mi limits
   - Product: 200m/512Mi requests, 1000m/1Gi limits (cache-heavy)
   - Pricing: 100m/256Mi requests, 500m/512Mi limits
   - Cart: 100m/256Mi requests, 500m/512Mi limits
   - Order: 200m/512Mi requests, 1000m/1Gi limits
   - Inventory: 200m/512Mi requests, 1000m/1Gi limits
   - Payment: 100m/256Mi requests, 500m/512Mi limits
   - Notification: 100m/256Mi requests, 500m/512Mi limits
   — effort: M
2. [ ] HPA per service: min 2 replicas (HA), max derived from load tests, scale on CPU > 70% — effort: M
3. [ ] HTTP client config in `pkg/httputil`: `MaxConnsPerHost=32`, `MaxIdleConnsPerHost=8`, idle conn timeout 90s — effort: S
4. [ ] DB pool config in `pkg/db`: per-service `max_open_conns=20`, `max_idle_conns=5`, `conn_max_lifetime=30m`. Ensure `Σ(max_open) ≤ pg_max_connections` minus headroom — effort: M
5. [ ] PodDisruptionBudget per service: `minAvailable: 1` so node drains don't take down the only replica — effort: S
6. [ ] Anti-affinity rules: replicas spread across nodes/AZs — effort: S
7. [ ] Verify limits via `kubectl top pod` under load — effort: S

## Deliverables

- Resource requests/limits + HPA + PDB in every service's Kustomize manifests
- Connection-pool config in `pkg/*`
- Anti-affinity rules

## Exit Criteria

- [ ] Every service Deployment has both `requests` and `limits`
- [ ] HPA scales up during a synthetic load spike (verified once)
- [ ] PDB prevents simultaneous eviction during a node drain
- [ ] Total PG connections from all services < `max_connections` of the cluster

## References

- Design doc: §7.7 Bulkhead Isolation, §12.1 Horizontal Scaling

## Risks & Open Questions

- Initial sizing is guesswork; redo after load tests in phase 06.
- Memory limits trigger OOM-kill if a service has a leak — pair with memory alerts at 80% of limit so the team sees it before pods restart.
