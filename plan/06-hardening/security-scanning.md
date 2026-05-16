# Security Scanning

## Purpose

Automated continuous scanning that catches regressions: dependency vulns, container vulns, secret leaks, basic web vulns. Threat model handles the architectural attacks; this sub-file handles the constant grind.

## Inputs / Prerequisites

- CI pipelines in place ([`../01-foundation/cicd-baseline.md`](../01-foundation/cicd-baseline.md))
- Trivy + govulncheck already wired (phase 01)

## Tasks

1. [ ] `govulncheck` in CI, fail on HIGH/CRITICAL — effort: S
2. [ ] `npm audit` (mobile, web, admin, packages) in CI, fail on HIGH/CRITICAL — effort: S
3. [ ] Trivy container scan on every image push; fail on HIGH/CRITICAL in non-base layers — effort: S
4. [ ] Secret scanning: `gitleaks` on every PR; pre-commit hook in repo template — effort: S
5. [ ] OWASP ZAP baseline scan against customer-web and admin-web staging URLs nightly — effort: M
6. [ ] OWASP ASVS Level 2 checklist walkthrough — produce a pass/fail row per control in a tracking sheet — effort: L
7. [ ] Pen test by external firm before launch (engagement scheduling here; results inform remediation) — effort: XL (external)
8. [ ] Suppress / accept findings only via a documented entry in `security/suppressions.yaml` with owner + expiry — effort: S

## Deliverables

- CI scans wired and gating
- Nightly ZAP report archived
- OWASP ASVS Level 2 checklist with status
- External pen-test report + remediation plan

## Exit Criteria

- [ ] CI blocks an introduced HIGH-severity vuln (verified with a deliberate bad pin then reverted)
- [ ] ZAP baseline produces zero HIGH findings on either web app
- [ ] ASVS Level 2 controls 100% pass (or documented accept-risk)
- [ ] Pen test remediation tracked to closure

## References

- Design doc: §9.4 Security Hardening (Dependency Scanning, Container Security rows)

## Risks & Open Questions

- Pen test lead time is weeks — book early in phase 06.
- ZAP false-positives on dynamic SPAs are common; tune the rules and document exclusions.
