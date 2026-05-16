# Launch Sign-Off

## Purpose

Explicit, dated, named approval from each stakeholder area before the rollout starts. No verbal "looks good" — write it down.

## Inputs / Prerequisites

- [`pre-launch-checklist.md`](./pre-launch-checklist.md) 100% green

## Sign-off table

Fill in name + date as each stakeholder signs.

| Area | Sign-off criteria | Signer | Date |
|---|---|---|---|
| **Engineering** | All phases 01-06 exit criteria met; load test green; rollback drill passed | | |
| **Security** | Threat model addressed; pen test remediations closed; ASVS Level 2 pass | | |
| **Operations / SRE** | Runbooks reviewed; on-call schedule live; alerts wired to PagerDuty; DR drill within 90 days | | |
| **Product** | Pre-launch checklist items in scope; comms plan approved; rollout cadence agreed | | |
| **Legal / Compliance** | ToS, privacy policy, cookie banner live; PCI scope confirmed (SAQ-A) | | |
| **Marketing** | Launch comms scheduled; status page configured; press embargo (if any) understood | | |

## War-room

- **Channel**: `#launch-room` (Slack)
- **Voice bridge**: <link>
- **Attendees**: on-call primary + secondary, eng lead, ops lead, product lead, security on standby
- **Hours**: T-1h through T+72h, 24/7 with shift rotation

## Comms plan

- T-1d: internal heads-up in `#general`
- T+0h: status-page post "Launching today"
- After each ramp step: status-page update
- T+72h: status-page "Launch complete"
- Day +7: public launch retrospective summary

## Exit Criteria

- [ ] All six sign-off rows filled with names + dates
- [ ] War-room created with confirmed attendees
- [ ] Comms plan executed at T-1d milestone

## References

- All of phases 06 + 07
