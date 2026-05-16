# Chaos Testing

## Purpose

Verify the failure-mode design under §7 of the design doc actually works: kill a pod, partition the broker, fail over the DB, and confirm the platform self-heals or gracefully degrades. Especially important for the Saga. A paper-only saga is not a real saga.

## Inputs / Prerequisites

- Staging environment with realistic data
- [`../06-hardening/load-testing.md`](../06-hardening/load-testing.md) baseline known (re-run against staging in this phase) so chaos results have a comparison

## Tasks

1. [ ] Install Chaos Mesh (or LitmusChaos) in `chaos` namespace on staging (effort: M)
2. [ ] Scenarios:
   - **Pod kill**: kill 1 of N replicas of each service during steady load → no SLO breach
   - **Pod kill (only replica)**: scale to 1 then kill → < 60s downtime, PDB prevents this in real life
   - **Network partition (broker)**: isolate Kafka broker from one service for 30s → outbox backlogs, drains after
   - **DB failover**: trigger RDS/Cloud SQL failover → < 30s reconnect, no data loss
   - **Slow downstream**: inject 5s latency into Pricing → circuit breaker opens, Cart degrades gracefully
   - **Disk full**: fill Postgres data volume to 95% → alerts fire, no silent corruption
   - **OOM kill**: stress one Payment pod past memory limit → restart, saga completes via retry
 (effort: L)
3. [ ] Each scenario has: pre-conditions, action, expected behavior, pass/fail criteria, blast radius (effort: M)
4. [ ] Run weekly in staging during off-hours. Auto-stop if SEV-1 alerts fire (effort: M)
5. [ ] Document findings in `tests/chaos/runs/<date>.md`. File remediation issues for surprises (effort: S)
6. [ ] Optional: GameDay quarterly with the whole team (effort: M)

## Deliverables

- Chaos Mesh installed and scoped to staging
- Scripted scenarios under `tests/chaos/scenarios/`
- Weekly run reports
- Remediation backlog for surprises

## Exit Criteria

- [ ] All listed scenarios pass at least once
- [ ] Pod-kill during checkout: order still completes or cleanly compensates
- [ ] Broker partition: zero events lost
- [ ] DB failover: < 30s recovery, all in-flight transactions retried via outbox

## References

- Design doc: §7 Resilience Patterns (entire section)

## Risks & Open Questions

- Chaos in staging is safe but does not stress prod-only configs (e.g., HA Keycloak, MSK quotas). Plan a one-off pre-launch chaos test in prod during a quiet window.
- Chaos Mesh CRDs are powerful. Restrict RBAC so only ops team can run experiments.
