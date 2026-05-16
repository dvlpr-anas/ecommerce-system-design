# Runbooks

## Purpose

Every alert links here. Every service has one. On-call should be able to triage and act from a phone in the middle of the night.

## Inputs / Prerequisites

- All services deployed
- Alerts authored ([`alerting.md`](./alerting.md))

## Tasks

1. [ ] Author template at `services/<svc>/RUNBOOK.md`:
   - **What this service does** (1 paragraph)
   - **Owner team** + escalation chain
   - **Dashboards**: Grafana + Loki links
   - **Common alerts** (table: alert name → likely cause → diagnostic steps → remediation)
   - **Restart procedure** (`kubectl rollout restart deployment/<svc>`)
   - **Scale procedure** (`kubectl scale ...`)
   - **Database migration rollback** (link to [`db-migration-strategy.md`](./db-migration-strategy.md))
   - **Tunable knobs** (env vars, config maps)
   - **Recent incidents** (link to postmortems)
 (effort: M)
2. [ ] One runbook per service: user, product, pricing, cart, order, inventory, payment, notification (effort: L)
3. [ ] Platform runbooks:
   - "Kafka broker down"
   - "Postgres failover"
   - "Keycloak unavailable"
   - "Kong returning 5xx"
   - "Sealed Secrets controller stuck"
   - "ISR not invalidating"
   - "DLQ replay procedure" (links to [`../04-order-flow/dlq-and-replay.md`](../04-order-flow/dlq-and-replay.md))
 (effort: L)
4. [ ] Cross-service incidents:
   - "Order stuck in PENDING_*"
   - "Inventory drift detected"
   - "Payment-to-Order projection lag"
 (effort: M)
5. [ ] On-call cheat sheet: top 10 `kubectl` / `psql` / `kafka-console-consumer` commands per service (effort: S)
6. [ ] Runbook freshness check: quarterly review. Auto-flag runbooks with no edits in 6 months (effort: S)
7. [ ] Postmortem template at `docs/postmortems/TEMPLATE.md`. Link from each runbook (effort: S)

## Deliverables

- Per-service `RUNBOOK.md` in every service directory
- Platform runbooks under `docs/runbooks/`
- Cheat sheet pinned in the on-call channel
- Postmortem template

## Exit Criteria

- [ ] Every Prometheus alert annotation resolves to an existing runbook section
- [ ] On-call lead can walk through the "Order stuck in PENDING_*" runbook from scratch and resolve a simulated incident
- [ ] All eight services have a runbook reviewed by their team

## References

- Design doc: §10 Observability, §11 Deployment Strategy (rollback)

## Risks & Open Questions

- Runbooks rot. Tie freshness to release process: any incident updates the relevant runbook before the postmortem closes.
