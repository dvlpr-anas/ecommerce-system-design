# Alerting & On-Call

## Purpose

Every SLO has a burn-rate alert. Every infra failure mode has an alert. Every alert links to a runbook. No silent failures. Page only what humans must act on within minutes.

## Inputs / Prerequisites

- [`slos.md`](./slos.md) complete
- [`../06-hardening/runbooks.md`](../06-hardening/runbooks.md) drafts in place (finalized after on-call review here)
- Prometheus/Alertmanager deployed in cluster ([`../07-cloud-infrastructure/kubernetes-baseline.md`](../07-cloud-infrastructure/kubernetes-baseline.md)) and wired to Slack + PagerDuty (config pattern from [`../02-platform-services/observability-metrics.md`](../02-platform-services/observability-metrics.md), credentials via Sealed Secrets)

## Tasks

1. [ ] Alert categorization:
   - **PAGE** (immediate): SEV-1 (revenue blocked, saga stuck, broker down, prod DB down, auth down)
   - **TICKET** (next business day): degraded performance, DLQ non-empty < threshold, cert expiring in < 14d
   - **INFO** (Slack only): capacity headroom getting tight, dependency vuln found
 (effort: M)
2. [ ] Author Prometheus alerting rules covering:
   - SLO burn-rate per service (fast 1h + slow 24h windows)
   - `kafka_consumer_lag > 10k for 5m`
   - `outbox_pending_count > 1000 OR oldest unpublished > 60s`
   - `circuit_breaker_state == open for 5m`
   - DLQ message count > threshold
   - Pod restart loop (CrashLoopBackOff)
   - Postgres connection pool saturation
   - Redis memory > 80%
   - Cert expiring < 14d
   - HPA at max replicas for 15m
 (effort: L)
3. [ ] Every alert annotation includes a `runbook_url` pointing into `06-hardening/runbooks.md` (effort: M)
4. [ ] On-call rotation: primary + secondary, weekly handoff, documented in PagerDuty schedule (effort: M)
5. [ ] Quarterly alert review: tune thresholds, remove noise, add gaps surfaced by recent incidents (effort: M)
6. [ ] Synthetic checks: a "browse → add to cart → checkout" probe runs every 5 minutes against staging and prod via k6/Checkly (effort: M)

## Deliverables

- `infra/observability/alerts.yaml` with all rules
- PagerDuty schedule + escalation policy
- Synthetic check running and graphed
- Quarterly review calendar

## Exit Criteria

- [ ] Every Prometheus alert has a `runbook_url`
- [ ] Synthetic check fails when staging is intentionally broken. Recovers automatically when fixed
- [ ] PagerDuty escalation tested with a non-prod alert
- [ ] Alert noise budget: < 1 false page per week sustained over a month before launch

## References

- Design doc: §10 Observability, §12 Capacity & Scaling

## Risks & Open Questions

- Alert fatigue kills on-call effectiveness. Start with the minimum set of pages and add only after observed need.
