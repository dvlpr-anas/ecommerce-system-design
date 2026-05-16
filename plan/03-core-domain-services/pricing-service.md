# Pricing Service

## Purpose

Compute the effective price for a (sku, user, context) tuple by evaluating a stack of configured promotion rules. Owns `pricing_db`. Synchronously called by Cart, Order, and the storefront. Wrapped in a circuit breaker per design-doc §7.1.

## Inputs / Prerequisites

- Phase 02 complete
- `pkg/circuitbreaker` consumed by callers

## Tasks

1. [ ] Author `services/pricing-service/api/openapi.yaml`:
   - `GET /price?sku=...&user_id=...&qty=...` → `{ base, discounts: [...], total, currency }`
   - `POST /prices/batch` (for cart/order summaries)
   - Admin: CRUD `/promotions`, `/discount-rules`
 (effort: M)
2. [ ] DB migrations:
   - `promotions` (id, code, name, starts_at, ends_at, rule JSONB, priority, active)
   - `discount_rules` (id, promotion_id FK, rule_type ENUM, params JSONB)
 (effort: M)
3. [ ] Rule engine: config-driven evaluator supporting rule types `percentage_off`, `fixed_off`, `tiered_qty`, `bxgy`, `category_discount`. Pure-function evaluator, easy to test (effort: L)
4. [ ] Cache evaluated prices for (sku, promo-set-version) in Redis with short TTL (60s) (effort: M)
5. [ ] Publish version bumps on promotion CRUD so callers can bust their caches (effort: S)
6. [ ] Idempotent admin writes via `pkg/idempotency` (effort: S)
7. [ ] Kustomize manifests, HPA, ServiceMonitor, NetworkPolicy (effort: M)
8. [ ] Unit tests achieve > 90% coverage of the rule evaluator (this is where bugs hide) (effort: M)

## Deliverables

- Service running. Rule engine library inside `internal/pricing/`
- Admin endpoints behind `admin` role check
- Redis cache for evaluated prices

## Exit Criteria

- [ ] `GET /api/v1/price?sku=ABC&user_id=...&qty=2` returns price + discount breakdown
- [ ] Adding a promotion via admin endpoint changes the returned price within 60s (cache TTL)
- [ ] Rule evaluator unit tests cover every rule type
- [ ] Circuit breaker opens after 5 simulated downstream errors (verified via Pricing client in another service)

## References

- Design doc: §4.1 Service Catalog (Pricing Service row), §7.1 Circuit Breakers

## Risks & Open Questions

- Rule evaluation order is tricky (stacking discounts). Define and document precedence rules in `internal/pricing/README.md`. Lock with tests.
- Currency: assume single currency for MVP. Multi-currency is a future ADR.
