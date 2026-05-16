# 06: Local Hardening

## Goal

Harden everything that can be hardened **without a cloud cluster**: threat model the design, run security scans, baseline load against the local stack, codify the DB migration policy, and draft runbooks. Cloud-only hardening (chaos in cluster, real DR drill, SLO measurement in prod, paging alerts) is deferred to [`../08-cloud-deployment/`](../08-cloud-deployment/).

## Scope

**In scope:** threat model, SAST plus dependency plus container scanning in CI, k6 load test driven against `docker-compose` stack, expand-and-contract DB migration policy, runbook drafts authored from local-failure experiments.

**Out of scope:**
- Chaos engineering on a real cluster (see [`../08-cloud-deployment/chaos-testing.md`](../08-cloud-deployment/chaos-testing.md))
- DR drill against managed Postgres or Kafka (see [`../08-cloud-deployment/disaster-recovery.md`](../08-cloud-deployment/disaster-recovery.md))
- SLO definition tied to prod telemetry (see [`../08-cloud-deployment/slos.md`](../08-cloud-deployment/slos.md))
- Paging alert pipeline (see [`../08-cloud-deployment/alerting.md`](../08-cloud-deployment/alerting.md))

## Prerequisites

- Phases 03, 04, and 05 complete. Full stack runs end-to-end on `task up`.

## Sub-files

- [`threat-model.md`](./threat-model.md)
- [`security-scanning.md`](./security-scanning.md)
- [`load-testing.md`](./load-testing.md): k6 against `localhost`. Results are directional. Repeated against prod in phase 08.
- [`runbooks.md`](./runbooks.md): draft form. Finalized after on-call review in phase 08.
- [`db-migration-strategy.md`](./db-migration-strategy.md)

## Phase exit criteria

- [ ] Threat model authored. HIGH or CRITICAL findings either remediated or have an explicit owner plus deadline.
- [ ] CI fails on HIGH or CRITICAL trivy, govulncheck, or npm audit findings
- [ ] k6 load test runs against local stack and produces a baseline report (latency p50, p95, p99, error rate, throughput)
- [ ] DB migration policy documented. Every service's migration tool wired up.
- [ ] Runbook draft exists for each of the eight services

## Risks

- Load testing on a laptop is bound by host CPU and memory. Results are directional, not predictive. Re-run against the deployed cluster in phase 08 before launch.
- Threat model based on the design doc may miss issues that only surface in deployed config (for example, real NetworkPolicy gaps). Re-review after phase 08.

## References

- Design doc: §7 Resilience, §9 Security, §11.4 Rollback Plan, §12 Capacity & Scaling
