# Web & Mobile Security

## Purpose

Codify the client-side security posture from design-doc §9.4 so the three frontends apply consistent controls: strict CSP, CSRF, SSRF lockdown, cert pinning, Universal/App Links, no tokens in `localStorage`.

## Inputs / Prerequisites

- [`mobile-app.md`](./mobile-app.md), [`customer-web.md`](./customer-web.md), [`admin-web.md`](./admin-web.md) scaffolded
- Kong CSRF / `Sec-Fetch-Site` enforcement live ([`../02-platform-services/kong-gateway.md`](../02-platform-services/kong-gateway.md))

## Tasks

1. [ ] CSP audit checklist for both web apps:
   - `script-src 'self'` + nonces, no inline, no `unsafe-eval`
   - `style-src 'self'` (Tailwind + Radix produce deterministic classes)
   - Stripe Elements exemption (`script-src https://js.stripe.com`, `frame-src https://js.stripe.com`)
   - `connect-src` limited to Kong + Keycloak
   - `frame-ancestors 'none'` (no embedding)
   - CSP report URI to a small backend endpoint
   — effort: M
2. [ ] CSRF: state-changing routes use double-submit token (Next.js issues cookie + form field) + Kong enforces `Sec-Fetch-Site` / `Origin` — effort: M
3. [ ] SSRF lockdown in Next.js: server-side `fetch` wrapper restricts target host to `KONG_INTERNAL_HOST`; rejects all other URLs — effort: S
4. [ ] Token storage:
   - Mobile: `expo-secure-store` only — never `AsyncStorage`
   - Web: HttpOnly cookies — never `localStorage`/`sessionStorage`
   - Admin: same as web; in-memory access tokens, refresh via cookie
   Enforce via ESLint rule banning `localStorage.setItem` patterns related to auth — effort: M
5. [ ] Certificate pinning (mobile): pin Kong's TLS leaf + intermediate. Document rotation procedure (pin both old and new during cert rotation window) — effort: M
6. [ ] Universal Links (iOS) + App Links (Android): no custom-scheme fallback for OIDC callback; verify domain ownership via `apple-app-site-association` and `assetlinks.json` published on the web origin — effort: M
7. [ ] Mobile jailbreak/root detection via `jail-monkey`; show a warning + restrict checkout if detected (configurable per market) — effort: M
8. [ ] Cloudflare-level controls: bot management on customer web; strict managed rules on admin — effort: S
9. [ ] Pen-test prep: an isolated security-scan environment running both web apps + mobile binaries (TestFlight) provided to security review in phase 06 — effort: M

## Deliverables

- CSP enforced in `Content-Security-Policy` (not just `-Report-Only`) on both web apps
- CSRF + SSRF protections live and tested
- Cert pinning verified via MITM test on a rooted device
- Universal/App Links verified via `aasa-validator` / `App Links Assistant`

## Exit Criteria

- [ ] OWASP ZAP baseline scan against both web apps produces zero HIGH findings (verified again in phase 06)
- [ ] MITM via mitmproxy on a rooted device blocks the mobile app (pin works)
- [ ] CSP report endpoint receives zero reports for 1 week of internal testing
- [ ] CSRF attack from `https://evil.com` is rejected

## References

- Design doc: §9.4 Security Hardening (every web/mobile row)

## Risks & Open Questions

- Cert pinning + outage risk: a misissued cert can brick the app. Mitigation: pin to intermediate, not leaf; ship a circuit-breaker config that disables pinning if `MIN_SUPPORTED_VERSION` bumps.
- Bot management on customer web can false-positive legitimate users on aggressive settings; start permissive, tighten with telemetry.
