# 08: Cloud Deployment & Production Hardening

## Goal

Take the locally-validated system and run it on the cloud substrate built in phase 07. Wire deploy automation, author K8s manifests for every service, point services at managed Postgres, Kafka, and Redis, then prove the deployed system on real infra: chaos, DR, SLO measurement, paging alerts.

## Scope

**In scope:** image push in CI, K8s manifests (Deployment, Service, HPA, NetworkPolicy, PodDisruptionBudget) for every service, environment promotion workflow (dev to staging to prod with manual gate), config swap from local docker-compose endpoints to managed cloud endpoints, chaos suite on cluster, DR drill against managed Postgres plus Kafka, SLO and SLI dashboards in prod Grafana, alert pipeline (Prometheus to Alertmanager to PagerDuty or Opsgenie).

**Out of scope:** any net-new business logic, launch checklist itself (that is [`../09-launch/`](../09-launch/)).

## Prerequisites

- Phase 06 complete (system hardened to local-feasible bar)
- Phase 07 complete (cluster, registry, and Sealed Secrets exist in dev)

## Sub-files

- [`cicd-deploy.md`](./cicd-deploy.md): push images to registry, update manifests, environment promotion, prod approval gate
- [`service-manifests.md`](./service-manifests.md): per-service Deployment, Service, HPA, NetworkPolicy, PDB. Kustomize overlays per env.
- [`slos.md`](./slos.md): SLI and SLO definitions wired to prod Prometheus
- [`alerting.md`](./alerting.md): Alertmanager routing, paging integration, alert-to-runbook links
- [`chaos-testing.md`](./chaos-testing.md): pod-kill, broker-partition, DB-failover scenarios on staging
- [`disaster-recovery.md`](./disaster-recovery.md): Postgres PITR restore, Kafka topic restore, full DR drill

## Phase exit criteria

- [ ] Push to `main` builds, pushes images to the registry, and updates dev manifests. Dev cluster picks up the new image automatically.
- [ ] Staging deploy succeeds and golden-path checkout completes against managed Postgres, Kafka, and Redis
- [ ] Prod deploy requires a reviewer click in the GitHub Environments UI
- [ ] All services have SLOs plus alerts. Every alert links to a runbook.
- [ ] Chaos suite passes: pod-kill, broker-partition, and DB-failover each leave the platform in a recoverable state
- [ ] DR drill restores Postgres plus Kafka within RTO. Data loss within RPO.
- [ ] Load test (re-run of phase 06 k6) sustains peak profile (10k users, 2k orders per minute) within SLO **against staging**

## Risks

- Local docker-compose hides failure modes (single-broker Kafka, single Redis). Expect surprises on first deploy. Budget time to fix.
- Cosign image signing plus admission verification (deferred from phase 01) lands here if required for launch.
- Chaos testing is dangerous. Only run in a dedicated staging window with clear stop-loss.

## References

- Design doc: §7 Resilience, §10 Observability, §11 Deployment Strategy, §11.4 Rollback Plan
- ADR-006 CI/CD strategy
