# Disaster Recovery

## Purpose

Document and test the procedures for recovering from catastrophic failure: full Postgres loss, Kafka topic corruption, region outage. Validate RPO and RTO targets by drill, not by hope.

## Inputs / Prerequisites

- PITR enabled on Postgres ([`../02-platform-services/postgres.md`](../02-platform-services/postgres.md))
- Kafka with replication ≥ 3 across AZs ([`../02-platform-services/kafka.md`](../02-platform-services/kafka.md))
- Sealed Secrets keys backed up out-of-band ([`../01-foundation/sealed-secrets.md`](../01-foundation/sealed-secrets.md))

## Tasks

1. [ ] Define targets:
   - **RPO**: ≤ 5 minutes for transactional data (Postgres), ≤ 1 minute for events (Kafka replication)
   - **RTO**: ≤ 1 hour for full platform restoration in same region; ≤ 4 hours for region failover
   — effort: S
2. [ ] Postgres drill:
   - Restore PITR to a new instance using a backup from 1h ago
   - Validate `events` table integrity (Order, Inventory, Payment)
   - Document time taken; iterate until within RTO
   — effort: M
3. [ ] Kafka drill:
   - Simulate broker loss (1 of 3) → cluster heals automatically
   - Simulate topic data loss → restore from MSK tier-2 storage or rebuild from event-sourced services (Order/Inventory)
   - Document procedure for unrecoverable topics
   — effort: M
4. [ ] Sealed Secrets recovery: restore key from offline backup to a new cluster, decrypt sample secret — effort: M
5. [ ] Cross-region failover (out-of-scope for MVP launch; document approach):
   - Async PG replica + Kafka mirror to secondary region
   - DNS cutover via Route53 health checks
   - Trade-off: cost vs. continuity — defer formal multi-region until product justifies
   — effort: S
6. [ ] DR runbook in [`runbooks.md`](./runbooks.md) with step-by-step recovery commands — effort: M
7. [ ] DR drill cadence: quarterly Postgres PITR restore, semi-annual Kafka drill, annual sealed-secrets recovery — effort: S

## Deliverables

- Documented RPO/RTO
- Drill results showing actuals within targets
- DR runbook in `runbooks.md`
- Drill calendar in PagerDuty / team calendar

## Exit Criteria

- [ ] Postgres PITR restore completes within 1-hour RTO
- [ ] Sealed Secrets recovery procedure verified on a throwaway cluster
- [ ] Kafka broker loss handled automatically without data loss
- [ ] DR runbook reviewed by on-call lead

## References

- Design doc: §11.4 Rollback Plan (related), §12 Capacity & Scaling

## Risks & Open Questions

- True cross-region active-active is a multi-quarter project. Document the gap explicitly and accept it for MVP with a clear path forward.
- Backup integrity is silent until you restore. Drill regularly.
