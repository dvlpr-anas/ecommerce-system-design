# 07 — Launch

## Goal

Ship to production with eyes open: pre-launch checklist complete, rollout plan rehearsed, rollback plan tested, sign-offs collected, post-launch monitoring window staffed.

## Scope

**In scope:** pre-launch checklist, progressive rollout, rollback procedure, sign-off, post-launch monitoring window.

**Out of scope:** anything that should have been done in phase 06.

## Prerequisites

- Phase 06 complete (security, SLOs, load + chaos, DR, runbooks)
- App Store + Play Store submissions accepted (or scheduled)
- Marketing + legal approvals confirmed
- Stripe in live mode with prod keys in Sealed Secrets

## Sub-files

- [`pre-launch-checklist.md`](./pre-launch-checklist.md)
- [`rollout-plan.md`](./rollout-plan.md)
- [`rollback-plan.md`](./rollback-plan.md)
- [`signoff.md`](./signoff.md)
- [`post-launch-monitoring.md`](./post-launch-monitoring.md)

## Phase exit criteria

- [ ] Pre-launch checklist 100% green
- [ ] Sign-offs from engineering, security, ops, and product recorded
- [ ] Rollout completed to 100% with SLOs intact
- [ ] No SEV-1 incident in first 72h
- [ ] Post-launch retrospective scheduled

## Risks

- Launch surprises tend to be in integrations not exercised in staging (real DNS, real Cloudflare WAF tuning, real Stripe webhook delivery). Treat the 1% rollout as the real test.

## References

- Design doc: §11 Deployment Strategy (esp. §11.4 Rollback, §11.5 Mobile, §11.6 Web)
