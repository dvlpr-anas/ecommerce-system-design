# Engineering Principles

These principles govern every phase. When a sub-file's tasks conflict with one of these, the principle wins. Update the plan, don't bypass it.

## 1. ADR-driven decisions

Every non-trivial tech choice is justified by an ADR in [`../../docs/adrs/`](../../docs/adrs/). The plan **references** ADRs. It does not re-debate them. If a decision needs revisiting, write a new ADR that supersedes the old one before changing the plan.

## 2. Smallest viable slice first

Each phase's exit criteria target a demoable, end-to-end slice. Not feature-completeness. Browse before promotions. Checkout before refunds. Observability before optimization.

## 3. Observability before features

A service is not "done" until it emits structured logs (slog), exposes `/metrics`, has `/healthz` + `/readyz`, and shows up on the Service Health Grafana dashboard. This applies to every service in phases 03 and 04.

## 4. Security from day one

JWT validation, RBAC, CSP, HttpOnly cookies, idempotency keys, sealed secrets, distroless containers. All baked in during their phase, never bolted on in phase 06. Phase 06 is verification, not implementation.

## 5. Expand-and-contract for schema and API changes

Breaking changes are forbidden in a single release. Database migrations and API contracts evolve in two steps: add new (backwards-compatible) → migrate consumers → remove old. Mobile apps amplify this. Back-compat for at least N-2 mobile versions per design-doc §11.5.

## 6. Contract-first APIs

OpenAPI YAML is written before handler code. Server stubs and TS clients are generated, never hand-written. See design-doc §8.1.

## 7. Idempotency everywhere asynchronous

Every Kafka consumer is idempotent (`processed_events` table). Every external call that mutates state uses an idempotency key. The Saga depends on this.

## 8. Database-per-service, hard isolation

No service queries another service's database. Cross-service data flows over Kafka events or REST. See ADR-004.

## References

- ADR-001 through ADR-009
- Design doc: §7 Resilience, §8 API Design, §9 Security, §11.3 Migration Strategy
