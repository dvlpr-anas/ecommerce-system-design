# Rollout Plan

## Purpose

Progressive ramp-up of customer-facing traffic so problems surface at small blast radius. Web via Argo Rollouts canary. Mobile via EAS production channel with staged rollout in App Store / Play Store. Admin via instant cutover (internal users only).

## Inputs / Prerequisites

- [`pre-launch-checklist.md`](./pre-launch-checklist.md) 100% green
- Argo Rollouts installed in cluster (set up in [`../05-frontends/customer-web.md`](../05-frontends/customer-web.md))

## Tasks

1. [ ] **Dark launch** (T-1d): deploy to prod, no public traffic, internal test transactions only (effort: M)
2. [ ] **1% canary** (T+0h): Cloudflare splits 1% of customer-web traffic to new release. Mobile staged rollout at 1% in Play Console + iOS phased release on
   - Watch: SLO dashboards, error rate, Stripe success rate, saga p95, alert pages
   - Stop-loss: any SEV-1 alert OR error rate > 0.5% → halt and roll back
 (effort: M)
3. [ ] **10% rollout** (T+2h if 1% is green for 2h): bump canary weight, bump mobile staged rollout to 10% (effort: M)
4. [ ] **50% rollout** (T+24h if 10% is green): bump to 50% (effort: S)
5. [ ] **100% rollout** (T+48h if 50% is green) (effort: S)
6. [ ] **Admin web**: instant cutover at T+0h (internal users only. Small population, low risk) (effort: S)
7. [ ] **Mobile rollout cadence**: respect Apple's phased release schedule (7-day default). Play Console: 1% → 5% → 20% → 50% → 100% over a week (effort: S)
8. [ ] **Comms**: status-page update at each step. Slack post in `#launch-room`. PagerDuty banner (effort: S)
9. [ ] **Gating metric** per step: SLO breach rate, error rate, Stripe success rate, saga p95. Automated check before bumping to next step (effort: M)

## Deliverables

- Argo Rollouts manifests with canary stages
- EAS production submission with staged rollout enabled
- Status page (Statuspage.io / Atlassian / OSS alternative)
- Comms plan in [`signoff.md`](./signoff.md)

## Exit Criteria

- [ ] 100% rollout reached without rollback
- [ ] SLOs intact for 72h post-100%
- [ ] No SEV-1 in launch window

## References

- Design doc: §11.2 Deployment Model, §11.5 Mobile Release, §11.6 Web Release

## Risks & Open Questions

- Cloudflare-level traffic splitting is coarser than service-level canary. If needed, use header-based canary at Kong for finer control.
- Apple phased release is opaque (you cannot pause once started without an emergency request). Play Console is more controllable.
