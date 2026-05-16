# Customer Web (Next.js App Router)

## Purpose

SEO-optimized storefront. SSR/ISR for `/`, `/p/[slug]`, `/c/[slug]` (Core Web Vitals matter). CSR for cart/checkout/account (auth-walled, dynamic). HttpOnly cookie session issued by a Next.js route handler after OIDC PKCE callback. Cloudflare CDN in front.

## Inputs / Prerequisites

- ADR-009 confirmed
- `packages/api-client-ts`, `packages/ui-web` ready
- Keycloak `customer-web` client configured (PKCE, redirect URI `/api/auth/callback`)
- Product Service publishes catalog-change events for ISR invalidation ([`../03-core-domain-services/product-service.md`](../03-core-domain-services/product-service.md))

## Tasks

1. [ ] `web/` Next.js 14+ project, App Router, TypeScript, Tailwind, Radix Primitives — effort: M
2. [ ] Route layout per design-doc §14:
   - `(storefront)/page.tsx` (home, ISR)
   - `(storefront)/c/[slug]/page.tsx` (category, ISR)
   - `(storefront)/p/[slug]/page.tsx` (product, ISR with `revalidate`)
   - `cart/page.tsx` (CSR)
   - `checkout/page.tsx` (CSR + Stripe Elements)
   - `account/page.tsx` (SSR auth-required)
   - `api/auth/login/route.ts` (initiates PKCE)
   - `api/auth/callback/route.ts` (exchanges code, sets HttpOnly cookie)
   - `api/auth/logout/route.ts`
   - `api/revalidate/route.ts` (token-protected ISR webhook target)
   — effort: L
3. [ ] OIDC PKCE flow in route handlers; session = signed HttpOnly cookie `__Host-sid` (encrypted JWT or opaque ID with server-side store) — effort: L
4. [ ] SSR data-fetching: server components call backend via Kong using a server-side fetch wrapper that adds Bearer token from the cookie session — effort: M
5. [ ] CSR data: TanStack Query + the generated client, cookie attached automatically — effort: M
6. [ ] Strict CSP per design-doc §9.4: `script-src 'self' 'nonce-...'`, no inline, no `unsafe-eval`; Tailwind + Radix output deterministic classes — effort: M
7. [ ] CSRF for state-changing routes: double-submit token + `Sec-Fetch-Site` enforcement at Kong (see [`../02-platform-services/kong-gateway.md`](../02-platform-services/kong-gateway.md)) — effort: M
8. [ ] SSRF lockdown: server-side `fetch` restricted to internal Kong hostname; no user-supplied URLs ever — effort: S
9. [ ] ISR revalidation: `/api/revalidate?path=...` accepts a token, calls `revalidatePath` — effort: M
10. [ ] SEO: `sitemap.xml`, OpenGraph tags, JSON-LD product schema on PDPs — effort: M
11. [ ] Cloudflare config: CDN cache rules, WAF managed rule set, rate limit on `/api/*` routes — effort: M
12. [ ] Core Web Vitals budget: LCP < 2.5s, CLS < 0.1, INP < 200ms; performance budget in CI via Lighthouse CI — effort: M
13. [ ] Argo Rollouts canary (5% → 25% → 100%) on deploy per design-doc §11.6 — effort: M
14. [ ] `min_client_version` header check → soft reload prompt — effort: M

## Deliverables

- `web/` deployed as a Node server image on K8s
- ISR-revalidation pipeline working end-to-end (admin edit → page updates within ~1 min)
- Cloudflare zone configured
- Lighthouse CI green on critical pages

## Exit Criteria

- [ ] PDP loads SSR with LCP < 2.5s on cold cache
- [ ] OAuth login flow round-trip works
- [ ] Checkout completes against Stripe test cards
- [ ] CSP report-only mode shows zero violations on all happy paths
- [ ] Admin edits a product → storefront PDP reflects change within revalidate window
- [ ] CSRF attack from external origin is rejected

## References

- Design doc: §3 (Customer Web), §9.4 Security (CSP/CSRF/SSRF), §11.6 Web Release Pipelines
- ADR-009 Web frontend

## Risks & Open Questions

- ISR + Cloudflare edge cache double-layer: revalidation invalidates Next.js ISR but not Cloudflare edge — purge Cloudflare via API on the same webhook.
- Stripe Elements + strict CSP: requires `script-src https://js.stripe.com` and `frame-src https://js.stripe.com`. Document the exemptions.
