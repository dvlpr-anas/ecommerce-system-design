# 03: Core Domain Services (Browse Path)

## Goal

Deliver the four services that power browse + cart: User, Product, Pricing, Cart. End state: a customer can sign up, browse the catalog, search, get a price, add to cart. All through Kong, all observable, all behind contracts.

## Scope

**In scope:** services 1-4 from design-doc §4.1, their OpenAPI specs, their DB schemas, their `pkg/*` integration, contract tests, shared service tooling.

**Out of scope:** Order, Inventory, Payment, Notification (those are [`../04-order-flow/`](../04-order-flow/)), any frontend code.

## Prerequisites

- Phase 02 complete: Kong validates JWTs, `pkg/*` libs work, OpenAPI codegen works, Postgres + Redis available, Kafka topics exist (Cart/User don't publish, but Product publishes catalog change events for ISR)

## Sub-files

- [`user-service.md`](./user-service.md)
- [`product-service.md`](./product-service.md)
- [`pricing-service.md`](./pricing-service.md)
- [`cart-service.md`](./cart-service.md)
- [`shared-tooling.md`](./shared-tooling.md)

## Phase exit criteria

- [ ] A customer can: sign up via Keycloak → list products → search → get a price → add to cart, all through Kong
- [ ] Every service appears on the Service Health Grafana dashboard with non-zero traffic
- [ ] Per-service OpenAPI spec + generated TS client lands in `packages/api-client-ts`
- [ ] Contract tests run in CI for each service
- [ ] Zero per-service code duplication for HTTP/DB plumbing. Every service uses `pkg/httpserver`, `pkg/db`

## Risks

- Product Service catalog import (bulk) is unbounded. Set a hard cap and stream from S3/GCS to avoid OOMing.
- Cart merge on login (anonymous → authenticated) is a classic edge-case farm. Cover with explicit tests.

## References

- Design doc: §4 Core Microservices, §8 API Design Strategy
- ADR-003 Service language, ADR-004 Database strategy
