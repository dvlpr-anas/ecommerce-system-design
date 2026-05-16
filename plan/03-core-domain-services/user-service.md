# User Service

## Purpose

CRUD for user profiles and shipping addresses. Maps Keycloak `sub` (OIDC subject) → internal `user_id`. Owns `user_db` (PostgreSQL).

## Inputs / Prerequisites

- Phase 02 complete (`pkg/*`, Postgres, Keycloak, Kong)
- OpenAPI codegen pipeline works

## Tasks

1. [ ] Author `services/user-service/api/openapi.yaml`:
   - `GET /users/me`
   - `PATCH /users/me`
   - `GET /users/me/addresses`, `POST`, `PATCH /addresses/{id}`, `DELETE /addresses/{id}`
 (effort: M)
2. [ ] Run `task codegen:openapi` to produce handler stubs (effort: S)
3. [ ] DB migrations under `services/user-service/migrations/`:
   - `users` (id, keycloak_sub UNIQUE, email, display_name, created_at, updated_at)
   - `addresses` (id, user_id FK, line1, line2, city, region, postal_code, country, is_default)
   - `profiles` (user_id PK, preferences JSONB)
 (effort: M)
4. [ ] Implement handlers using `pkg/httpserver` + `pkg/db`. JWT claim `sub` → lazy-upsert `users` row on first authenticated request (effort: M)
5. [ ] Enforce row-level ownership: users can only access their own data. Admin role bypass (effort: M)
6. [ ] Contract tests using generated client against the running service (effort: M)
7. [ ] Kustomize manifests under `k8s-manifests/base/user-service/`, Deployment, Service, HPA (min 2, max 10, CPU 70%), ServiceMonitor (effort: M)
8. [ ] NetworkPolicy: allow ingress from Kong, allow egress to Postgres + Keycloak JWKS (effort: S)

## Deliverables

- Service running on cluster at `users.services.svc`
- OpenAPI spec + generated client
- Migrations applied via K8s Job per `06-hardening/db-migration-strategy.md`
- Grafana dashboard panel for User Service

## Exit Criteria

- [ ] `curl -H "Authorization: Bearer <token>" https://api.example.com/api/v1/users/me` returns the user
- [ ] First call after Keycloak signup lazy-creates a `users` row
- [ ] User A cannot read User B's addresses (403)
- [ ] All standard metrics emit. Logs include `user_id` + `request_id`
- [ ] Contract tests green in CI

## References

- Design doc: §4.1 Service Catalog (User Service row), §9.2 RBAC Model

## Risks & Open Questions

- Email change flow: who updates Keycloak email? Decision: Keycloak owns email. User Service reads `email` from the JWT claim, never stores it.
- GDPR delete: when a user deletes account, delete `users` row, anonymize order history. Coordinate with Order Service before launch.
