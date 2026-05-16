# Pre-Launch Checklist

## Purpose

A single list whose every box must be ticked before traffic ramps. If any item is unchecked, launch is deferred.

## Inputs / Prerequisites

- Phase 06 complete

## Tasks

1. [ ] **DNS**: `www.example.com`, `admin.example.com`, `api.example.com`, `auth.example.com` resolve to Cloudflare. Cloudflare proxies to Kong (effort: S)
2. [ ] **TLS**: cert-manager issued certs valid > 60 days. Renewal automation tested (effort: S)
3. [ ] **Stripe live mode**: keys in Sealed Secrets, webhook endpoint registered in Stripe Dashboard with the right events, signature secret stored (effort: S)
4. [ ] **Mobile App Store**: iOS submitted to App Review, Android submitted to Play Console. Release notes finalized (effort: M)
5. [ ] **Legal & marketing**: ToS, privacy policy, cookie banner, marketing assets live (effort: S)
6. [ ] **On-call**: PagerDuty schedule covers launch week with primary + secondary. War-room channel created (effort: S)
7. [ ] **SLOs green** for last 7 days in staging at peak load (effort: S)
8. [ ] **Latest load test** within last 30 days passed (effort: S)
9. [ ] **DR drill** completed in last 90 days (effort: S)
10. [ ] **Pen test** report received and HIGH/CRITICAL findings remediated (effort: S)
11. [ ] **Runbooks** reviewed and acknowledged by on-call lead (effort: S)
12. [ ] **Backups verified**: latest Postgres restore drill < 30 days old (effort: S)
13. [ ] **Cloudflare WAF** + rate limits dialed in, not in learning mode (effort: S)
14. [ ] **Sealed Secrets backup**: private key in offline storage, restore procedure verified (effort: S)
15. [ ] **`min_client_version` set** for mobile and web so future N-2 deprecation works (effort: S)
16. [ ] **Capacity headroom**: HPA min replicas sized for 2× expected day-1 traffic (effort: S)
17. [ ] **Postmortem template** + retro calendar slot booked for launch + 7d (effort: S)

## Deliverables

- This checklist with every box ticked
- War-room link in [`signoff.md`](./signoff.md)

## Exit Criteria

- [ ] Every box above is checked
- [ ] War-room created, attendees confirmed
- [ ] Stripe live-mode test transaction (small amount, internal card) completes end-to-end

## References

- Design doc: §11 Deployment Strategy

## Risks & Open Questions

- App Store review can hold up launch. Build a 5-day buffer. Have a desktop-web-only launch fallback if needed.
