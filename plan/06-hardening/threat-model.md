# Threat Model

## Purpose

Systematic STRIDE pass per trust boundary to surface attacks the design has not addressed. Output drives [`security-scanning.md`](./security-scanning.md) and any remediation issues.

## Inputs / Prerequisites

- C4 diagrams from design-doc §3 (trust boundaries derive from them)
- All services + frontends deployed (staging)

## Tasks

1. [ ] Identify trust boundaries:
   - Internet ↔ Cloudflare
   - Cloudflare ↔ Kong
   - Kong ↔ Service (intra-cluster)
   - Service ↔ Postgres / Redis / Kafka
   - Service ↔ External (Stripe, SES, Expo Push, Keycloak)
   - Mobile binary ↔ Backend
   — effort: M
2. [ ] STRIDE per boundary: enumerate Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege threats — effort: L
3. [ ] Rate each finding (Low / Med / High / Critical) by likelihood × impact — effort: M
4. [ ] Map findings to existing mitigations (design-doc §9.4 mitigations table) — effort: M
5. [ ] File issues for unaddressed HIGH/CRITICAL; track in [`runbooks.md`](./runbooks.md) until remediated — effort: M
6. [ ] Sign-off: security review + eng lead acknowledge each accepted-risk item with a written rationale — effort: S
7. [ ] Schedule annual re-review; trigger ad-hoc on new external integration — effort: S

## Deliverables

- `06-hardening/threat-model-output.md` (or in a security tracker) with every threat → mitigation/status
- Sign-off record in [`../07-launch/signoff.md`](../07-launch/signoff.md)

## Exit Criteria

- [ ] Every trust boundary has a documented STRIDE pass
- [ ] Zero unaddressed HIGH/CRITICAL findings (everything is remediated, accepted-with-owner, or scheduled)
- [ ] Sign-off recorded

## References

- Design doc: §3 Architecture Diagrams, §9 Security Architecture

## Risks & Open Questions

- Mobile binary tampering (re-signing, repackaging) — out of scope for full mitigation; accept-risk with detection telemetry.
