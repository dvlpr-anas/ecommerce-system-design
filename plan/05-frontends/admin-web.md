# Admin Web (React + Vite)

## Purpose

Auth-walled SPA for admin and support roles. No SSR (no SEO need, no public surface). Strictly internal: IP allowlist + `SameSite=Strict` cookies + WAF rules. Admin code never ships in customer bundles per design-doc §9.2.

## Inputs / Prerequisites

- ADR-009 confirmed
- `packages/api-client-ts`, `packages/ui-web` ready
- Keycloak `admin-web` client configured with `admin` / `support` role gating
- DNS for `admin.example.com` resolved to Cloudflare

## Tasks

1. [ ] `admin-web/` Vite + React + TS project (effort: S)
2. [ ] React Router v6 with role-gated routes. `support` sees order ops, `admin` sees everything (effort: M)
3. [ ] OIDC PKCE: tokens in memory only (no localStorage), refresh via silent renew in iframe to Keycloak (or via HttpOnly cookie pattern like customer web. Preferred) (effort: L)
4. [ ] App shell rejects render if JWT does not contain `admin` or `support` role (effort: S)
5. [ ] Views (MVP):
   - Dashboard (orders today, revenue, top SKUs)
   - Products list / create / edit (image upload via presigned URL)
   - Categories
   - Promotions / discount rules
   - Orders list (filter by status, search by id/email)
   - Order detail (timeline of saga events, refund button for admin)
   - Users list (read-only for support, edit roles for admin)
   - Inventory restock screen
 (effort: XL)
6. [ ] TanStack Table for data grids, TanStack Query for fetches (effort: M)
7. [ ] Strict CSP `script-src 'self'`. Admin has no third-party scripts at all (effort: S)
8. [ ] Cloudflare config:
   - WAF managed rule set
   - IP allowlist (office IPs + VPN egress) where feasible
   - Stricter rate limits than customer web
 (effort: M)
9. [ ] Build artifact: either Cloudflare Pages or nginx-unprivileged container in K8s. Versioned by commit SHA in asset paths so old sessions don't break (effort: M)
10. [ ] Audit log: every admin mutation logged with `actor_user_id`, `action`, `target_id`, `before/after` snapshot. Implemented via a middleware on admin-scoped endpoints, viewable in admin UI (effort: L)

## Deliverables

- `admin-web/` deployed at `admin.example.com`
- Audit log surface in UI and queryable in DB
- IP allowlist enforced at edge

## Exit Criteria

- [ ] `customer` role cannot reach `admin.example.com` (Kong rejects 403)
- [ ] Asset URLs include commit SHA. Deploying does not break an open admin session mid-action
- [ ] Every admin mutation produces an audit log entry
- [ ] Lighthouse: 90+ on Performance + Accessibility (admin tooling is no excuse for poor a11y)
- [ ] CSP zero violations

## References

- Design doc: §3 (Admin Web), §9.2 RBAC, §9.4 Security (Admin token storage / IP allowlist / SameSite=Strict), §11.6 Web Release (Admin Web)
- ADR-009 Web frontend

## Risks & Open Questions

- IP allowlist breaks remote workers without VPN. Decide: VPN-required vs. permissive WAF + strong auth. Default: WAF + MFA on Keycloak + admin role.
- Image upload via presigned URLs: bucket must reject objects > N MB and validate content-type server-side after upload.
