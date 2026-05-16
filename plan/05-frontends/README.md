# 05: Frontends

## Goal

Ship the three client apps: React Native mobile (iOS + Android via Expo), Next.js customer web storefront, React + Vite admin SPA. All three consume the same generated OpenAPI TS client and the same Keycloak OIDC + PKCE flow.

## Scope

**In scope:** mobile app, customer web, admin web, shared TS packages, OpenAPI codegen pipeline integration, web/mobile security (CSP, cert pinning, deep links, CSRF, SSRF).

**Out of scope:** new backend functionality (phases 03/04), production hardening (phase 06).

## Prerequisites

- Phases 03 + 04 complete. APIs are stable enough to integrate against
- ADRs 008 (mobile) and 009 (web) reviewed
- Expo account + EAS access. Apple Developer + Google Play Console accounts
- DNS for `www.example.com`, `admin.example.com` cut over to Cloudflare → Kong

## Sub-files

- [`mobile-app.md`](./mobile-app.md)
- [`customer-web.md`](./customer-web.md)
- [`admin-web.md`](./admin-web.md)
- [`shared-frontend-packages.md`](./shared-frontend-packages.md)
- [`openapi-codegen.md`](./openapi-codegen.md)
- [`web-security.md`](./web-security.md)

## Phase exit criteria

- [ ] Customer can complete checkout on iOS, Android, and web with the same backend
- [ ] Admin can manage products and view orders on the admin SPA
- [ ] Lighthouse storefront score ≥ 90 on `/`, `/p/[slug]`, `/c/[slug]`
- [ ] CSP `report-only` mode shows zero violations on critical flows
- [ ] Mobile builds (iOS + Android) submitted to TestFlight + Play Internal Testing

## Risks

- Apple review for first submission can take 24h+. Budget buffer.
- ISR cache invalidation timing. First product page after an admin update may serve stale content briefly. Document expected behavior.

## References

- Design doc: §3 Architecture Diagrams, §9 Security Architecture, §11.5 Mobile App Release, §11.6 Web Release
- ADR-008 Mobile platform, ADR-009 Web frontend
