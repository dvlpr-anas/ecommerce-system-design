# Rollback Plan

## Purpose

If launch breaks, revert fast and safely. Per service, per layer (web, mobile, backend, DB). Rehearsed before launch, not improvised during incident.

## Inputs / Prerequisites

- All deploys use immutable, SHA-tagged container images
- Argo Rollouts canary in place (web)
- EAS Update channels configured (mobile)
- DB migrations follow expand-and-contract ([`../06-hardening/db-migration-strategy.md`](../06-hardening/db-migration-strategy.md))

## Tasks

1. [ ] **Backend rollback recipe** per service: `kubectl rollout undo deployment/<svc>` (or Argo Rollout abort + promote previous) (effort: S)
2. [ ] **Customer web rollback**: Argo Rollouts abort canary → promotes previous stable. Cloudflare cache purge (effort: S)
3. [ ] **Admin web rollback**: previous asset SHA still hosted (versioned URLs). Switch entrypoint version pointer (effort: S)
4. [ ] **Mobile rollback**:
   - JS-only issue: `eas update --branch production --message "rollback"` republishing the previous JS bundle
   - Native issue: cannot fast-rollback an installed binary. Cope by force-upgrade screen blocking the bad version + emergency Apple/Google submission
 (effort: M)
5. [ ] **DB rollback**:
   - Most migrations have no safe down. Accept-risk and prefer forward-fix (a new migration that corrects state)
   - Down migrations only for additive changes (drop the added column)
   - Document explicitly in each migration's header which strategy applies
 (effort: M)
6. [ ] **Saga rollback**: if Order Service is bad, halt new checkouts (feature flag → 503 on `POST /checkout`) and let in-flight sagas drain. Existing orders unaffected (effort: M)
7. [ ] **Feature flags** for risky launches: launch behind a flag, flip off without redeploy (effort: M)
8. [ ] **Rollback drill**: in staging, deploy a deliberately-broken release, execute the rollback recipe, verify recovery time (effort: M)
9. [ ] **Comms**: status-page update, customer email if customer-impacting > 30 min, postmortem within 5 business days (effort: S)

## Deliverables

- Per-service rollback steps in [`../06-hardening/runbooks.md`](../06-hardening/runbooks.md)
- Mobile force-upgrade gate already in place (built in [`../05-frontends/mobile-app.md`](../05-frontends/mobile-app.md))
- Feature-flag library wired into critical paths (Checkout, Admin mutations)
- Rollback drill report

## Exit Criteria

- [ ] Rollback drill completes within 15 min for backend, 5 min for web
- [ ] Mobile force-upgrade flow tested against a test device
- [ ] Every service runbook contains a rollback section
- [ ] Feature flag for `/checkout` tested on staging

## References

- Design doc: §11.4 Rollback Plan, §11.5 Mobile App Release, §11.6 Web App Release

## Risks & Open Questions

- DB rollback is the hardest. Be conservative on schema changes during launch week. Postpone non-essential migrations.
