# Cart Service

## Purpose

Session-based cart, Redis-only (no Postgres) per design-doc §4.2. Anonymous and authenticated carts; merges anon → auth on login. Volatile state with TTLs.

## Inputs / Prerequisites

- Phase 02 complete; Redis configured
- Pricing Service available (cart endpoints return current totals)

## Tasks

1. [ ] Author `services/cart-service/api/openapi.yaml`:
   - `GET /cart` (auto-creates if absent)
   - `POST /cart/items`, `PATCH /cart/items/{sku}`, `DELETE /cart/items/{sku}`
   - `POST /cart/merge` (called by web/mobile after login with anonymous cart ID)
   - `DELETE /cart` (clear)
   — effort: M
2. [ ] Redis schema:
   - `cart:{user_id}` → Hash {sku → qty}, TTL 7d
   - `cart:anon:{cart_id}` → Hash, TTL 24h
   - `cart:meta:{user_id}` → Hash {currency, updated_at}
   — effort: S
3. [ ] On `GET /cart`, call Pricing Service `POST /prices/batch` and return per-line + total — effort: M
4. [ ] Anonymous cart: client provides `X-Anon-Cart-ID` header (UUID). Service trusts it for anon-only routes — effort: S
5. [ ] Merge endpoint: idempotent merge of anon items into auth cart, last-write-wins per SKU — effort: M
6. [ ] Validate SKUs exist by calling Product Service `GET /products/{sku}` (circuit-breaker wrapped) — cache the existence check 60s — effort: M
7. [ ] Kustomize manifests, HPA on QPS, ServiceMonitor, NetworkPolicy (egress to Redis, Product, Pricing) — effort: M
8. [ ] Tests for merge edge cases: duplicate SKU, expired anon, hostile `X-Anon-Cart-ID` — effort: M

## Deliverables

- Service deployed; cart round-trip works via curl with both anon and auth flows
- Merge semantics documented in OpenAPI spec
- Redis keyspace conventions enforced

## Exit Criteria

- [ ] Anon flow: get cart ID → add items → expired in 24h
- [ ] Auth flow: items survive 7d
- [ ] Merge: anon cart with 3 items merges into auth cart, totals via Pricing match expectations
- [ ] All standard metrics emit; circuit breaker open when Product Service down (cart still readable from cache)

## References

- Design doc: §4.1 Service Catalog (Cart Service row), §4.2 (Cart = Redis only), §7.1 Circuit Breakers

## Risks & Open Questions

- Hostile `X-Anon-Cart-ID` could let an attacker poison someone else's anon cart. Mitigation: anon cart IDs are UUIDv4, never logged, rotate on `Cart-Cleared` events.
- Cart abandonment events for marketing — out of scope MVP; Notification Service could later consume periodic `cart.abandoned` synthetic events.
