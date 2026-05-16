# Kong API Gateway

## Purpose

Single ingress for all client traffic. Validates JWTs against Keycloak's JWKS, applies rate limits, injects `X-Request-ID` for tracing, routes to per-service ClusterIP services. Replaces ad-hoc auth + rate limiting in every service.

## Inputs / Prerequisites

- `keycloak.md` complete (JWKS endpoint reachable)
- `kubernetes-baseline.md` complete (Kong controller installed)

## Tasks

1. [ ] Author declarative config `api-gateway/kong.yaml` listing every backend service route (`/api/v1/users`, `/api/v1/products`, `/api/v1/cart`, `/api/v1/orders`, etc.) — effort: M
2. [ ] Enable JWT plugin pointing at Keycloak JWKS URL with cache TTL 1h — effort: M
3. [ ] Enable rate-limiting plugin: per-consumer (authenticated) and per-IP (anonymous) buckets; stricter bucket for `/api/v1/admin/*` routes — effort: M
4. [ ] Enable request-ID plugin generating `X-Request-ID` header if absent — effort: S
5. [ ] Enable CORS plugin scoped to the storefront, mobile, and admin origins — effort: S
6. [ ] Enable Prometheus plugin so Kong itself shows up on the metrics dashboard — effort: S
7. [ ] Add `Origin` / `Sec-Fetch-Site` enforcement plugin (or custom Lua) for state-changing routes used by web (CSRF mitigation per design-doc §9.4) — effort: M
8. [ ] Wire IngressClass + TLS via cert-manager for `api.example.com` and `auth.example.com` — effort: M
9. [ ] Add `KongConsumer` per service account so internal calls can be rate-limited separately from user traffic — effort: M
10. [ ] CI lint Kong config with `decK validate` — effort: S

## Deliverables

- `api-gateway/kong.yaml` declarative config
- Kustomize manifests for IngressClass + Ingresses under `k8s-manifests/base/ingress/`
- Cert-manager Certificate resources for the two hostnames
- Prometheus ServiceMonitor for Kong's `/metrics`

## Exit Criteria

- [ ] `curl -H "Authorization: Bearer <expired-token>" https://api.example.com/api/v1/users/me` returns 401
- [ ] Same call with a valid token returns 200 (against a hello-world service)
- [ ] 100 rapid requests from one IP without auth eventually hit rate-limit and receive 429
- [ ] `X-Request-ID` header appears on responses and propagates to backend logs
- [ ] Kong metrics show up on Grafana

## References

- Design doc: §9.1 Authentication Flow, §9.4 Security Hardening (CSRF, Rate Limiting), §10.2 Standard Log Format (request_id)
- ADR-002 API Gateway

## Risks & Open Questions

- Kong DBless mode requires a config reload to add routes. CI gates on `decK diff` to prevent stale configs.
- `Origin`/`Sec-Fetch-Site` enforcement may break legitimate cross-origin tools (Postman, mobile app on emulator). Allow-list as needed.
