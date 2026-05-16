# Keycloak

## Purpose

Centralized identity for the entire platform: OIDC for human users (customer, support, admin), service-account JWTs for service-to-service calls. All three frontends use Authorization Code + PKCE; Kong validates issued JWTs.

## Inputs / Prerequisites

- Phase 01 complete (Sealed Secrets + cluster available)
- Postgres available for Keycloak's backing store (created by [`postgres.md`](./postgres.md))
- DNS entry for `auth.example.com` pointing at Kong ingress

## Tasks

1. [ ] Install Keycloak (latest stable) via the Bitnami Helm chart into `platform` namespace with PG backing — effort: M
2. [ ] Create realm `ecom` via `keycloak-realm.json` import — effort: M
3. [ ] Define roles in `ecom` realm: `customer`, `support`, `admin`, `service` — effort: S
4. [ ] Create OIDC clients:
   - `mobile-app` (public, PKCE required, redirect URI `myapp://auth/callback` + Universal Link)
   - `customer-web` (confidential, PKCE, redirect URI `https://www.example.com/api/auth/callback`)
   - `admin-web` (confidential, PKCE, redirect URI `https://admin.example.com/auth/callback`)
   - `kong` (bearer-only, used for JWKS discovery)
   - `service-accounts` (client credentials per backend service, role `service`)
   — effort: L
5. [ ] Configure password policy (min 12, mixed case, special, breach check via `Have I Been Pwned` Keycloak SPI optional) — effort: S
6. [ ] Enable email-based account verification + password reset flows — effort: M
7. [ ] Expose JWKS endpoint publicly via Kong route `/auth/realms/ecom/protocol/openid-connect/certs` — effort: S
8. [ ] Bootstrap users for dev/staging via `keycloak-realm.json`; production users self-register — effort: S
9. [ ] Configure token lifetimes: access 5 min, refresh 30 days for mobile / 24h for web — effort: S
10. [ ] Document role-claim mapping in JWT (`realm_access.roles[]`) for services to consume — effort: S

## Deliverables

- Helm release `keycloak` in `platform` namespace
- `infra/keycloak/ecom-realm.json` checked in
- Sealed secret containing admin password + DB password
- Public JWKS URL routed through Kong

## Exit Criteria

- [ ] `curl https://auth.example.com/realms/ecom/.well-known/openid-configuration` returns the OIDC config
- [ ] Authorization Code + PKCE flow completes via a CLI test (use `oidc-client-cli` or a small Go test)
- [ ] Issued JWT contains `realm_access.roles` claim with the user's roles
- [ ] Service-account JWT obtained via client credentials grant validates against the same JWKS
- [ ] Account lockout triggers after configured failed attempts

## References

- Design doc: §9.1 Authentication Flow, §9.2 RBAC Model, §9.3 Service-to-Service Authentication

## Risks & Open Questions

- Keycloak HA needs >= 2 replicas + shared cache (Infinispan). Single replica is fine for dev/staging; bump for prod in `06-hardening/disaster-recovery.md`.
- Social login (Google, Apple) — defer; not in MVP scope per design doc.
