# 06 — Hardening (Production Readiness)

## Goal

Verify the platform meets production bar: security review, SLOs and alerts, load + chaos testing, DR drill, runbooks for every service. No new features — only proving what was built actually holds up.

## Scope

**In scope:** threat model, security scanning, SLO definition + alerting, k6 load tests, chaos scenarios, DR drill, runbook authoring, expand-and-contract migration policy.

**Out of scope:** new product features, new services, anything that adds risk in this window.

## Prerequisites

- Phases 03 + 04 + 05 complete; all services deployed to staging
- Production environment provisioned via Terraform (but empty / dark)

## Sub-files

- [`threat-model.md`](./threat-model.md)
- [`security-scanning.md`](./security-scanning.md)
- [`slos.md`](./slos.md)
- [`alerting.md`](./alerting.md)
- [`load-testing.md`](./load-testing.md)
- [`chaos-testing.md`](./chaos-testing.md)
- [`disaster-recovery.md`](./disaster-recovery.md)
- [`runbooks.md`](./runbooks.md)
- [`db-migration-strategy.md`](./db-migration-strategy.md)

## Phase exit criteria

- [ ] Threat model signed off; all HIGH/CRITICAL findings remediated or accepted with explicit owner
- [ ] All services have SLOs + alerts; every alert links to a runbook
- [ ] Load test sustains peak profile (10k users / 2k orders/min) within SLO
- [ ] Chaos suite passes: pod-kill, broker-partition, DB-failover each leave the platform in a recoverable state
- [ ] DR drill restores Postgres + Kafka within RTO; data loss within RPO
- [ ] Every service has a runbook reviewed by on-call

## Risks

- Load testing in staging is informative but not definitive — capacity may differ in prod. Plan a shadow-traffic dry run before launch.
- Chaos testing is dangerous — only run in a dedicated chaos environment or in staging during off-hours, with clear stop-loss.

## References

- Design doc: §7 Resilience, §9 Security, §10 Observability, §11.4 Rollback Plan, §12 Capacity & Scaling
