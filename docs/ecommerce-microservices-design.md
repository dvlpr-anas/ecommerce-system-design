# Enterprise E-Commerce Microservices Architecture
*(Scalable, Event-Driven, Kubernetes-Native)*

## 1. Executive Summary

This document presents a production-grade, event-driven e-commerce platform built on microservices principles. It is designed to demonstrate Solution Architect-level thinking: justified technology trade-offs, failure-mode design, operational maturity, and security-first architecture.

**Core Patterns:** Microservices, Event Sourcing, CQRS, Choreography-based Sagas, Transactional Outbox, Database-per-Service, Circuit Breakers, Infrastructure as Code.

> For all major technology decisions and trade-off analysis, see [Architecture Decision Records](./adrs/).

---

## 2. Technology Stack

| Layer | Technology | Justification |
|---|---|---|
| **Monorepo** | Taskfile (go-task) | Language-agnostic, works for Go, React Native, Next.js, Vite, and future services. [ADR-001](./adrs/ADR-001-monorepo-tooling.md) |
| **Mobile App** | React Native (Expo) + TypeScript + React Native Paper | Single codebase targeting iOS and Android, native modules where needed, shared TS types with backend OpenAPI. [ADR-008](./adrs/ADR-008-mobile-platform.md) |
| **Customer Web** | Next.js (App Router) + TypeScript + Tailwind/Radix | SSR/ISR for SEO and Core Web Vitals on storefront pages, CSR for cart/checkout, shared OpenAPI client with mobile. [ADR-009](./adrs/ADR-009-web-frontend.md) |
| **Admin Web** | React + Vite + TypeScript + Tailwind/Radix | Auth-walled SPA for ops/admin, no SSR tax, separate deployment from customer web. [ADR-009](./adrs/ADR-009-web-frontend.md) |
| **API Gateway** | Kong (K8s Ingress) | REST routing, JWT validation, rate-limiting. [ADR-002](./adrs/ADR-002-api-gateway.md) |
| **Services** | Go / Gin | High performance, small binaries, strong concurrency. [ADR-003](./adrs/ADR-003-service-language.md) |
| **Primary Database** | PostgreSQL (database-per-service) | Battle-tested ACID, full-text search, event sourcing via append-only tables. [ADR-004](./adrs/ADR-004-database-strategy.md) |
| **Cache** | Redis Cluster | Session state, cart storage, rate-limit counters |
| **Event Backbone** | Apache Kafka | Durable, ordered, replayable event log. [ADR-005](./adrs/ADR-005-event-backbone.md) |
| **Auth** | Keycloak (OIDC/OAuth2) | Centralized identity, RBAC, social login, MFA |
| **Orchestration** | Kubernetes (EKS/GKE) | Industry standard container orchestration |
| **IaC** | Terraform | Declarative, multi-cloud, state-managed infrastructure |
| **CI/CD** | GitHub Actions | Native Git integration, no extra infra. [ADR-006](./adrs/ADR-006-cicd-strategy.md) |
| **Secrets** | Sealed Secrets (Bitnami) | GitOps-compatible, encrypted at rest in Git |
| **Observability** | slog + Prometheus + Grafana | Structured logging, metrics, dashboards. [ADR-007](./adrs/ADR-007-observability.md) |

---

## 3. Architecture Diagrams

### 3.1 C4 Context Diagram, System in its Environment

```mermaid
C4Context
    title E-Commerce Platform, System Context

    Person(customer, "Customer", "Browses products, places orders on iOS/Android app or web storefront")
    Person(admin, "Admin", "Manages products, views analytics from the admin web app")

    System(ecommerce, "E-Commerce Platform", "Event-driven microservices platform")
    System(mobile, "Mobile App (iOS + Android)", "React Native (Expo) client, distributed via App Store and Play Store")
    System(web, "Customer Web Storefront", "Next.js (App Router) with SSR/ISR for SEO and perf")
    System(admin_web, "Admin Web App", "React + Vite SPA, admin/support roles only")

    System_Ext(cloudflare, "Cloudflare", "CDN, WAF, DDoS protection in front of web + API edge")
    System_Ext(payment_gw, "Payment Gateway", "Stripe / Razorpay")
    System_Ext(email, "Email Provider", "Transactional emails")
    System_Ext(push, "Push Provider", "APNs (iOS) / FCM (Android)")
    System_Ext(keycloak, "Keycloak", "OIDC Identity Provider")
    System_Ext(stores, "App Stores", "Apple App Store + Google Play Store")

    Rel(customer, mobile, "Uses")
    Rel(customer, web, "Uses (browser)")
    Rel(admin, admin_web, "Uses (admin/support role)")
    Rel(mobile, cloudflare, "HTTPS (REST API)")
    Rel(web, cloudflare, "HTTPS (SSR + API)")
    Rel(admin_web, cloudflare, "HTTPS (REST API)")
    Rel(cloudflare, ecommerce, "HTTPS (proxied)")
    Rel(mobile, keycloak, "OIDC Authorization Code + PKCE (via in-app browser)")
    Rel(web, keycloak, "OIDC Authorization Code + PKCE (HttpOnly cookie session)")
    Rel(admin_web, keycloak, "OIDC Authorization Code + PKCE (role-gated)")
    Rel(ecommerce, payment_gw, "REST API")
    Rel(ecommerce, email, "SMTP / API")
    Rel(ecommerce, push, "Push notifications (APNs/FCM)")
    Rel(ecommerce, keycloak, "Token validation / service accounts")
    Rel(stores, mobile, "OTA + binary distribution")
```

### 3.2 C4 Container Diagram, Internal Architecture

```mermaid
C4Container
    title E-Commerce Platform, Container Diagram

    Person(customer, "Customer")

    Container_Boundary(client, "Clients") {
        Container(ios, "iOS App", "React Native (Expo) / TS", "Distributed via Apple App Store")
        Container(android, "Android App", "React Native (Expo) / TS", "Distributed via Google Play Store")
        Container(web, "Customer Web", "Next.js (App Router) / TS", "SSR/ISR storefront, CSR for cart/checkout")
        Container(admin_web, "Admin Web", "React + Vite SPA / TS", "Auth-walled admin & support tooling")
    }

    Container_Boundary(edge, "Edge") {
        Container(cdn, "Cloudflare", "CDN/WAF", "DDoS, caching, Anycast for API traffic")
        Container(kong, "Kong Gateway", "K8s Ingress", "JWT validation, rate-limiting, routing")
    }

    Container_Boundary(services, "Microservices (Go/Gin)") {
        Container(user_svc, "User Service", "Go", "User profiles, addresses")
        Container(product_svc, "Product Service", "Go", "Catalog, full-text search (tsvector)")
        Container(pricing_svc, "Pricing Service", "Go", "Promotions, discount rules")
        Container(cart_svc, "Cart Service", "Go", "Session-based cart")
        Container(order_svc, "Order Service", "Go", "Order lifecycle, Event Sourcing, Saga")
        Container(inventory_svc, "Inventory Service", "Go", "Stock management, Event Sourcing")
        Container(payment_svc, "Payment Service", "Go", "Payment processing")
        Container(notification_svc, "Notification Service", "Go", "Email / SMS / Push (APNs + FCM) dispatch")
    }

    Container_Boundary(data, "Data Layer") {
        ContainerDb(pg, "PostgreSQL Cluster", "PostgreSQL 16", "Database-per-service isolation")
        ContainerDb(redis, "Redis Cluster", "Redis 7", "Sessions, carts, rate-limit counters")
        ContainerQueue(kafka, "Apache Kafka", "Kafka 3.x", "Domain events, Saga choreography, DLQs")
    }

    Container_Boundary(obs, "Observability") {
        Container(prometheus, "Prometheus", "Metrics", "Scrapes /metrics endpoints")
        Container(grafana, "Grafana", "Dashboards", "Metrics + logs visualization")
    }

    Rel(customer, ios, "Uses iPhone/iPad")
    Rel(customer, android, "Uses Android device")
    Rel(customer, web, "Uses browser")
    Rel(ios, cdn, "HTTPS")
    Rel(android, cdn, "HTTPS")
    Rel(web, cdn, "HTTPS (SSR origin + browser → API)")
    Rel(admin_web, cdn, "HTTPS")
    Rel(cdn, kong, "REST API calls (proxied)")
    Rel(kong, user_svc, "REST")
    Rel(kong, product_svc, "REST")
    Rel(kong, cart_svc, "REST")
    Rel(kong, order_svc, "REST")

    Rel(order_svc, kafka, "Publishes order events")
    Rel(inventory_svc, kafka, "Consumes/publishes inventory events")
    Rel(payment_svc, kafka, "Consumes/publishes payment events")
    Rel(notification_svc, kafka, "Consumes notification events")

    Rel(user_svc, pg, "user_db")
    Rel(product_svc, pg, "product_db")
    Rel(order_svc, pg, "order_db")
    Rel(inventory_svc, pg, "inventory_db")
    Rel(payment_svc, pg, "payment_db")
    Rel(cart_svc, redis, "Session store")

    Rel(prometheus, services, "Scrapes /metrics")
    Rel(grafana, prometheus, "Queries")
```

---

## 4. Core Microservices

### 4.1 Service Catalog

| # | Service | Database | Key Responsibility | Patterns |
|---|---|---|---|---|
| 1 | **User Service** | `user_db` (PG) | User profiles, addresses | CRUD, REST |
| 2 | **Product Service** | `product_db` (PG) | Catalog, search | CQRS (tsvector read-model) |
| 3 | **Pricing Service** | `pricing_db` (PG) | Promotions, discount rules | Config-driven rule engine |
| 4 | **Cart Service** | Redis Cluster | Session-based cart | Volatile state, TTL-based expiry |
| 5 | **Order Service** | `order_db` (PG) | Order lifecycle | Event Sourcing, Saga coordinator |
| 6 | **Inventory Service** | `inventory_db` (PG) | Stock management | Event Sourcing, Saga participant |
| 7 | **Payment Service** | `payment_db` (PG) | Payment processing | Saga participant, idempotency keys |
| 8 | **Notification Service** | None | Email / SMS / Push (APNs + FCM) dispatch | Kafka consumer, fire-and-forget |

### 4.2 Database-per-Service Strategy

One PostgreSQL cluster, **strict database-level isolation**. Services **never** query another service's database. Cross-service data flows only through Kafka events or synchronous REST calls.

| Service | Database | Key Tables |
|---|---|---|
| User Service | `user_db` | `users`, `addresses`, `profiles` |
| Product Service | `product_db` | `products`, `categories`, search index (`tsvector`) |
| Cart Service | **Redis only** |, |
| Order Service | `order_db` | `orders`, `order_items`, `events`, `outbox` |
| Payment Service | `payment_db` | `payments`, `refunds`, `outbox` |
| Inventory Service | `inventory_db` | `events`, `inventory_snapshot` |
| Pricing Service | `pricing_db` | `promotions`, `discount_rules` |
| Notification Service | None |, |

**Why one cluster, not N clusters?** See [ADR-004](./adrs/ADR-004-database-strategy.md).

---

## 5. Event Backbone & Kafka Topology

### 5.1 Topic Design

| Topic | Producer | Consumers | Purpose |
|---|---|---|---|
| `order.events` | Order Service | Inventory, Payment, Notification | Order lifecycle events |
| `inventory.events` | Inventory Service | Order, Notification | Stock reservation/release |
| `payment.events` | Payment Service | Order, Notification | Payment success/failure |
| `notification.commands` | Various | Notification Service | Email / SMS / Push (APNs + FCM) dispatch commands |
| `*.dlq` | Kafka consumers | Ops dashboard | Dead letter queues per topic |

### 5.2 Schema Enforcement
Shared Go structs in `pkg/events/` define all event contracts. JSON Schema validation occurs at the producer and consumer boundaries. See [ADR-005](./adrs/ADR-005-event-backbone.md) for why we chose this over Confluent Schema Registry.

---

## 6. Distributed Transactions & Saga Flow

### 6.1 Transactional Outbox Pattern
Services write domain events to an `outbox` table within the **same database transaction** as the state change. A lightweight Go **outbox poller** (per service) reads uncommitted outbox rows and publishes them to Kafka, then marks them as published.

```
BEGIN TRANSACTION
  INSERT INTO orders (id, status, ...) VALUES (...);
  INSERT INTO outbox (event_type, payload, published) VALUES ('order.created', '{...}', false);
COMMIT
```

This guarantees **atomicity** between database writes and event publishing without two-phase commits.

### 6.2 Choreography-based Saga, Checkout Flow

```mermaid
sequenceDiagram
    participant Client as Client (Mobile / Web)
    participant Kong as Kong Gateway
    participant Order as Order Service
    participant Kafka as Kafka
    participant Inventory as Inventory Service
    participant Payment as Payment Service
    participant Notify as Notification Service

    Client->>Kong: POST /api/v1/orders/checkout
    Kong->>Kong: Validate JWT (Keycloak)
    Kong->>Order: Forward REST request

    Order->>Order: Write order + outbox event (single TX)
    Order-->>Client: 202 Accepted (order_id)

    Order->>Kafka: order.created (via outbox poller)
    Kafka->>Inventory: order.created
    Inventory->>Inventory: Reserve stock (append StockReserved event)
    Inventory->>Kafka: inventory.reserved (via outbox)

    Kafka->>Payment: inventory.reserved
    Payment->>Payment: Charge customer (idempotency key)
    Payment->>Kafka: payment.completed (via outbox)

    Kafka->>Order: payment.completed
    Order->>Order: Update order status → CONFIRMED

    Kafka->>Notify: payment.completed
    Notify->>Notify: Send confirmation email

    Note over Payment,Inventory: COMPENSATION PATH (payment fails)
    Payment->>Kafka: payment.failed
    Kafka->>Inventory: payment.failed
    Inventory->>Inventory: Release stock (append StockReleased event)
    Kafka->>Order: payment.failed
    Order->>Order: Update order status → CANCELLED
    Kafka->>Notify: payment.failed
    Notify->>Notify: Send failure notification
```

---

## 7. Resilience Patterns

### 7.1 Circuit Breakers
Every synchronous outbound call (e.g., Order Service → Pricing Service REST call, Payment Service → Stripe API) is wrapped in a **circuit breaker** (using `sony/gobreaker`).

| State | Behavior |
|---|---|
| **Closed** | Requests flow normally. Failures are counted. |
| **Open** | All requests fail-fast immediately. No load on downstream. |
| **Half-Open** | A single probe request is allowed. Success → Closed. Failure → Open. |

**Config:** 5 consecutive failures → Open. 30s timeout → Half-Open. 3 successes → Closed.

### 7.2 Retry Policy with Exponential Backoff + Jitter
All Kafka consumers and HTTP clients implement retries with exponential backoff and **jitter** to prevent thundering herd:

```
delay = min(base * 2^attempt + random_jitter, max_delay)
```

**Config:** base=100ms, max_delay=30s, max_retries=5.

### 7.3 Timeouts & Deadlines
Every REST call has a **context timeout**:
- Internal service-to-service: 3s
- External APIs (Stripe/Razorpay): 10s
- Database queries: 5s

### 7.4 Idempotency
All Kafka consumers are **idempotent**. Each event carries a unique `event_id`. Consumers maintain a `processed_events` table and skip duplicates:

```
INSERT INTO processed_events (event_id) VALUES ($1) ON CONFLICT DO NOTHING;
-- If rowsAffected == 0, event was already processed → skip
```

Payment Service uses **idempotency keys** for external gateway calls to prevent double-charging.

### 7.5 Backpressure & Consumer Lag
- Kafka consumers use **manual offset commits** (commit only after successful processing).
- **Consumer lag** is exposed as a Prometheus metric. Grafana alerts fire when lag exceeds threshold (e.g., >10,000 messages for 5 minutes).
- Horizontal scaling: increase consumer group instances to match partition count.

### 7.6 Dead Letter Queues (DLQ)
After max retries, unprocessable messages are routed to a per-topic DLQ (e.g., `order.events.dlq`). DLQ messages retain full headers and metadata for debugging and replay.

### 7.7 Bulkhead Isolation
Each service runs in its own K8s Deployment with **resource limits** (CPU/memory). A runaway service cannot starve others. HTTP thread pools are bounded per downstream dependency.

---

## 8. API Design Strategy

### 8.1 Contract-First Development
All APIs are designed **contract-first** using **OpenAPI 3.0** specifications. The spec is written before implementation and serves as the single source of truth.

```
/services/user-service/api/openapi.yaml    ← Contract
/services/user-service/internal/handler/    ← Generated server stubs
```

### 8.2 Versioning Strategy
- **URL path versioning:** `/api/v1/orders`, `/api/v2/orders`
- New versions are only created for **breaking changes**.
- Non-breaking additions (new optional fields) are added to the current version.
- Old versions are supported for **2 release cycles** with deprecation headers.

### 8.3 Standard Response Envelope

```json
{
  "data": { ... },
  "meta": { "request_id": "uuid", "timestamp": "ISO8601" },
  "errors": [{ "code": "INSUFFICIENT_STOCK", "message": "...", "field": "quantity" }]
}
```

### 8.4 Pagination
Cursor-based pagination for all list endpoints (not offset-based, offset degrades at scale):

```
GET /api/v1/products?cursor=eyJpZCI6MTAwfQ&limit=25
```

---

## 9. Security Architecture

### 9.1 Authentication Flow

```mermaid
sequenceDiagram
    participant Client as Client (Mobile / Web)
    participant KC as Keycloak
    participant Kong as Kong Gateway
    participant Svc as Microservice

    Client->>KC: Login via in-app browser (OIDC Authorization Code + PKCE, expo-auth-session)
    KC-->>Client: Access Token (JWT) + Refresh Token (stored in iOS Keychain / Android Keystore)

    Client->>Kong: API Request + Bearer Token
    Kong->>Kong: Validate JWT signature (Keycloak public key)
    Kong->>Kong: Check token expiry, audience, issuer
    Kong->>Svc: Forward request + decoded JWT claims

    Svc->>Svc: Extract user_id, roles from JWT claims
    Svc->>Svc: Enforce RBAC based on roles
```

### 9.2 RBAC Model

| Role | Permissions |
|---|---|
| `customer` | Browse products, manage own cart/orders/profile (mobile + customer web) |
| `support` | Read customer orders/profiles, issue refunds (admin web only) |
| `admin` | All customer + support permissions + manage products, view all orders, manage promotions (admin web only) |
| `service` | Service-to-service calls (service accounts in Keycloak) |

`admin` and `support` tokens are issued by a Keycloak realm role and **rejected at the admin-web app shell** if missing. The customer mobile app and customer web app refuse to render admin views even if a privileged token is presented. Admin code does not ship in customer bundles.

### 9.3 Service-to-Service Authentication
Internal REST calls between services carry a **service account JWT** obtained from Keycloak's client credentials flow. Kong validates these tokens the same way it validates user tokens, no special treatment.

### 9.4 Security Hardening

| Concern | Mitigation |
|---|---|
| **Input Validation** | All request bodies validated against OpenAPI schema before handler logic |
| **SQL Injection** | Parameterized queries only (Go `database/sql` with `$1` placeholders) |
| **Mobile Token Storage** | Tokens stored in iOS Keychain / Android Keystore via `expo-secure-store`. Never in AsyncStorage |
| **Web Token Storage** | Access/refresh tokens in **HttpOnly, Secure, SameSite=Lax cookies** issued by the Next.js auth handler. Never in `localStorage`. Admin web uses the same pattern with `SameSite=Strict` and a stricter cookie domain |
| **Certificate Pinning** | Mobile app pins Kong's TLS leaf/intermediate to defeat on-device MITM proxies |
| **Deep Link Hijacking** | Universal Links (iOS) + App Links (Android) only. No plain custom schemes for auth callbacks |
| **CSRF** | Mobile uses `Authorization` header (immune). Web uses HttpOnly cookies, so all state-changing routes require a double-submit CSRF token or an `Origin`/`Sec-Fetch-Site` check at Kong |
| **CSP / XSS** | Strict CSP on both web apps: `script-src 'self'` + nonces, no inline scripts, no `unsafe-eval`. Tailwind + Radix output deterministic class names, no runtime style injection |
| **SSRF (Next.js SSR)** | Server-side `fetch` calls in Next.js are restricted to the internal Kong hostname. No user-supplied URLs are ever fetched from the server runtime |
| **Rate Limiting** | Kong rate-limiting plugin per consumer + per IP. Admin endpoints get a stricter bucket and IP allowlist where feasible |
| **Secrets** | Never in env vars or code, Sealed Secrets decrypted only in K8s cluster. Mobile and customer web ship **no** server secrets. Only the public Keycloak client_id for PKCE. Next.js Node runtime holds only a backend-API service token for ISR revalidation webhooks |
| **Transport** | TLS everywhere, Cloudflare → Kong is HTTPS, K8s internal via NetworkPolicies |
| **Dependency Scanning** | `govulncheck` (Go) and `npm audit` (mobile + web + admin-web) in CI pipeline |
| **Container Security** | Distroless base images, non-root containers, read-only filesystems |
| **Mobile Hardening** | Jailbreak/root detection (`jail-monkey`), disable Reanimated debug builds in release, ProGuard/R8 obfuscation on Android |

---

## 10. Observability

### 10.1 Three Pillars

| Pillar | Tool | Implementation |
|---|---|---|
| **Logging** | Go `slog` (structured JSON) | Every service writes structured JSON logs to stdout. K8s collects via container runtime. |
| **Metrics** | Prometheus + Grafana | Each service exposes `/metrics` endpoint. Prometheus scrapes, Grafana visualizes. |
| **Health** | `/healthz` + `/readyz` | K8s liveness and readiness probes per service |

### 10.2 Standard Log Format

```json
{
  "time": "2026-05-10T05:30:00Z",
  "level": "INFO",
  "msg": "order created",
  "service": "order-service",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "usr_123",
  "order_id": "ord_456",
  "duration_ms": 42
}
```

Every request gets a unique `request_id` (generated at Kong, propagated via `X-Request-ID` header) for end-to-end tracing across services.

### 10.3 Key Metrics (Prometheus)

| Metric | Type | Description |
|---|---|---|
| `http_requests_total` | Counter | Total requests by service, method, path, status |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `kafka_consumer_lag` | Gauge | Messages behind per consumer group/topic |
| `kafka_messages_processed_total` | Counter | Events processed by type |
| `circuit_breaker_state` | Gauge | 0=closed, 1=open, 2=half-open |
| `outbox_pending_count` | Gauge | Unpublished outbox events |
| `db_pool_active_connections` | Gauge | Database connection pool utilization |

### 10.4 Grafana Dashboards
- **Service Health:** Request rate, error rate (5xx), p50/p95/p99 latency per service
- **Kafka Health:** Consumer lag, throughput, DLQ message count
- **Infrastructure:** Pod CPU/memory, PG connection pool, Redis memory usage

---

## 11. Deployment Strategy

### 11.1 CI/CD Pipeline (GitHub Actions)

```mermaid
flowchart LR
    A[Push to main] --> B[Lint + Unit Tests]
    B --> C[Build Docker Images]
    C --> D[Push to Container Registry]
    D --> E[Update K8s Manifests]
    E --> F{Environment}
    F -->|staging| G[Deploy to Staging]
    G --> H[Integration Tests]
    H --> I[Manual Approval Gate]
    I -->|approved| J[Deploy to Production]
    F -->|hotfix| J
```

### 11.2 Deployment Model, Rolling Updates with Readiness Gates
- **Strategy:** `RollingUpdate` with `maxSurge=1, maxUnavailable=0` (zero-downtime).
- New pods must pass **readiness probes** (`/readyz`, checks DB connection, Kafka producer health) before receiving traffic.
- Old pods are drained gracefully (K8s `preStop` hook + connection draining).

### 11.3 Database Migration Strategy
- Migrations run as **Kubernetes Jobs** (init-containers) before the service Deployment rolls out.
- **Expand-and-Contract pattern:** Breaking schema changes are split into two releases:
  1. **Expand:** Add new column (nullable) → deploy code that writes to both old and new → backfill.
  2. **Contract:** Next release drops the old column after all consumers are updated.
- This guarantees zero-downtime schema evolution.

### 11.4 Rollback Plan
- K8s native: `kubectl rollout undo deployment/<service>`
- Container images are immutable and tagged with Git SHA, rollback = redeploy a known-good SHA.
- Database rollbacks: each migration has a corresponding `down` migration.

### 11.5 Mobile App Release Pipeline
The mobile app follows a separate release cadence from backend services since native binaries must be reviewed by Apple/Google.

- **Build:** **EAS Build** (Expo Application Services) produces signed `.ipa` (iOS) and `.aab` (Android) artifacts in CI.
- **Channels:** `development` (local dev clients), `preview` (internal QA via TestFlight + Play Internal Testing), `production` (App Store + Play Store).
- **JS-only updates:** Shipped via **EAS Update** (OTA) for non-native changes. Bypasses store review for bug fixes and copy changes, gated by runtime version compatibility.
- **Native updates:** Require a new store submission and review (Apple ~24h, Google ~few hours). Plan for a 1-2 day review buffer before any deadline.
- **Backwards-compat constraint:** **API contracts must remain backward-compatible for at least N,2 mobile versions** (older app installs cannot be force-upgraded). Expand-and-Contract applies to API changes just as it does to schemas.
- **Forced upgrade:** A `/api/v1/clients/check` endpoint returns a `minimum_supported_version`. The app shows a blocking "update required" screen when its build is below it.

### 11.6 Web App Release Pipelines
Customer web and admin web ship independently and far more often than the mobile app (no store review).

- **Customer Web (Next.js):**
  - Built in CI as a Node server image, deployed to EKS/GKE behind Cloudflare (CDN/WAF) with HPA.
  - **ISR revalidation:** Product/Pricing services publish events. A small consumer fires `revalidatePath` / `revalidateTag` webhooks at the Next.js instance to invalidate cached storefront pages.
  - Progressive rollout via Kubernetes `Deployment` + Argo Rollouts (canary 5% → 25% → 100%). Rollback = redeploy a known-good SHA.
- **Admin Web (Vite SPA):**
  - Built in CI as static assets, deployed to Cloudflare Pages (or Nginx in K8s).
  - Versioned by commit SHA in the asset URL. Old bundles remain available so in-flight admin sessions don't break mid-action.
  - WAF rules and (where feasible) an IP allowlist gate access to `admin.example.com`.
- **Backwards-compat constraint:** Same N,2 API rule applies. Web clients can be force-refreshed via a `min_client_version` header check from the server, which prompts the user to reload. Softer than mobile's blocking screen.

---

## 12. Capacity & Scaling Strategy

### 12.1 Horizontal Scaling

| Service | Scaling Trigger | Strategy |
|---|---|---|
| **All Go services** | CPU > 70% or RPS > threshold | K8s HPA (Horizontal Pod Autoscaler) |
| **Kafka consumers** | Consumer lag > 10k for 5min | Scale pods up to partition count |
| **PostgreSQL** | Connection pool saturation | Read replicas for read-heavy services (Product) |
| **Redis** | Memory > 80% | Cluster resharding |

### 12.2 Bottleneck Analysis

| Bottleneck | Location | Mitigation |
|---|---|---|
| **Write contention** | Inventory Service (stock updates) | Event Sourcing = append-only writes (no row locks) |
| **Search load** | Product Service | PostgreSQL `tsvector` index + read replicas + Redis caching for hot queries |
| **Payment latency** | External gateway (Stripe) | Async via Kafka, circuit breaker prevents cascade, 10s timeout |
| **Kafka throughput** | Topic partition count | Start with 12 partitions per topic, increase as consumer count grows |

### 12.3 Load Profile (Target)
- **Steady state:** ~1,000 concurrent users, ~200 orders/min
- **Peak (sale events):** ~10,000 concurrent users, ~2,000 orders/min
- **Scaling ceiling:** Kafka partitions + HPA pods. Horizontal scaling is linear up to PostgreSQL write limits.

---

## 13. Monorepo Management (Taskfile)

All build, test, run, and deploy tasks are managed via **Taskfile (go-task)**.

```bash
task dev:mobile             # Start Expo dev server (Metro bundler)
task dev:mobile:ios         # Run iOS simulator build
task dev:mobile:android     # Run Android emulator build
task dev:web                # Start Next.js storefront dev server
task dev:admin-web          # Start Vite admin dev server
task dev:user-service       # Start user service locally
task build:all              # Build all services + all frontends
task build:mobile:ios       # EAS Build → iOS .ipa
task build:mobile:android   # EAS Build → Android .aab
task build:web              # Next.js production build (Node server image)
task build:admin-web        # Vite static build (admin SPA assets)
task codegen:openapi        # Regenerate TS client in pkg/api-client-ts from all OpenAPI specs
task docker:build:all       # Build all Docker images (services + Next.js)
task test:all               # Run all tests across services, mobile, web, admin-web
task test:integration       # Run integration tests
task db:migrate:all         # Run all database migrations
task lint:all               # Lint Go + TypeScript (services, mobile, web, admin-web)
```

---

## 14. Directory Structure

```
/sol_arch_proj
├── Taskfile.yml                # Monorepo task runner
├── docs/
│   ├── ecommerce-microservices-design.md   # This document
│   └── adrs/                              # Architecture Decision Records
│       ├── ADR-001-monorepo-tooling.md
│       ├── ADR-002-api-gateway.md
│       ├── ADR-003-service-language.md
│       ├── ADR-004-database-strategy.md
│       ├── ADR-005-event-backbone.md
│       ├── ADR-006-cicd-strategy.md
│       ├── ADR-007-observability.md
│       ├── ADR-008-mobile-platform.md
│       └── ADR-009-web-frontend.md
├── terraform/                  # IaC: AWS VPC, EKS, RDS, MSK
├── k8s-manifests/
│   ├── base/                   # Deployments, Services, ConfigMaps, HPA
│   └── overlays/               # staging, production
├── .github/
│   └── workflows/              # CI/CD pipelines
├── api-gateway/                # Kong configuration + rate-limit policies
├── pkg/                        # Shared Go libraries
│   ├── events/                 # Event structs + JSON schema validation
│   ├── outbox/                 # Transactional outbox poller library
│   ├── circuitbreaker/         # Circuit breaker wrapper (sony/gobreaker)
│   ├── middleware/             # Auth, request-ID, logging, metrics middleware
│   └── httputil/               # Standard response envelope, pagination helpers
├── packages/                   # Shared TypeScript packages (pnpm workspace)
│   ├── api-client-ts/          # OpenAPI-generated TS client + Zod schemas (mobile + web + admin-web)
│   ├── ui-web/                 # Tailwind config + Radix-based primitives (web + admin-web)
│   └── events-ts/              # TS mirrors of Go event structs (for any client SSE/WS consumer)
├── services/
│   ├── user-service/
│   │   ├── api/openapi.yaml    # OpenAPI 3.0 contract
│   │   ├── cmd/main.go
│   │   ├── internal/           # handler, service, repository layers
│   │   ├── migrations/
│   │   └── Dockerfile
│   ├── product-service/        # PostgreSQL (product_db, tsvector search)
│   ├── pricing-service/        # PostgreSQL (pricing_db, rule engine)
│   ├── cart-service/           # Redis Cluster
│   ├── inventory-service/      # PostgreSQL (inventory_db, Event Sourced)
│   ├── order-service/          # PostgreSQL (order_db, Event Sourced, Saga)
│   ├── payment-service/        # PostgreSQL (payment_db, idempotency)
│   └── notification-service/   # Kafka consumer, email/SMS dispatch
├── mobile/                      # React Native (Expo) app, single codebase for iOS + Android
│   ├── package.json
│   ├── app.config.ts             # Expo config (bundle id, scheme, deep links, plugins)
│   ├── eas.json                  # EAS Build profiles (development, preview, production)
│   ├── src/
│   │   ├── screens/              # Screen components (React Navigation routes)
│   │   ├── components/           # Shared UI components (React Native Paper)
│   │   ├── navigation/           # Stack/tab navigators, deep-link config
│   │   ├── api/                  # Consumes packages/api-client-ts + TanStack Query hooks
│   │   ├── auth/                 # expo-auth-session (OIDC PKCE) + expo-secure-store
│   │   └── notifications/        # expo-notifications (APNs/FCM) setup
│   ├── ios/                      # Native iOS project (Xcode), generated by Expo prebuild
│   └── android/                  # Native Android project (Gradle), generated by Expo prebuild
├── web/                         # Customer web storefront (Next.js App Router)
│   ├── package.json
│   ├── next.config.mjs           # Image domains, headers/CSP, revalidate config
│   ├── app/                      # App Router routes (RSC + server actions)
│   │   ├── (storefront)/         # SSG/ISR product, category, PDP routes
│   │   ├── account/              # SSR account/order history (auth required)
│   │   ├── cart/                 # CSR cart + checkout
│   │   ├── api/auth/             # OIDC PKCE callback, HttpOnly cookie issuance
│   │   └── api/revalidate/       # Webhook target for ISR invalidation from backend
│   └── Dockerfile                # Node runtime image deployed to K8s
└── admin-web/                   # Admin SPA (React + Vite)
    ├── package.json
    ├── vite.config.ts
    ├── src/
    │   ├── routes/               # React Router v6 admin/support views
    │   ├── components/           # Data grids (TanStack Table), forms, dashboards
    │   ├── api/                  # Consumes packages/api-client-ts + TanStack Query hooks
    │   └── auth/                 # OIDC PKCE, role-gating (admin/support)
    └── nginx.conf                # Static asset serving (when not on Cloudflare Pages)
```

---

## 15. Key Architectural Patterns Demonstrated

| Pattern | Where | Why It Matters |
|---|---|---|
| **Database-per-Service** | All services | Loose coupling, independent deployability |
| **Event Sourcing** | Order + Inventory | Full audit trail, temporal queries, no data loss |
| **CQRS** | Product Service (tsvector) | Optimized read-model, decoupled from writes |
| **Transactional Outbox** | Order, Inventory, Payment | Atomic DB write + event publish without 2PC |
| **Choreography Saga** | Checkout flow | Distributed transaction with compensating actions |
| **Circuit Breaker** | All outbound HTTP calls | Prevents cascading failures |
| **Idempotent Consumers** | All Kafka consumers | Safe at-least-once delivery |
| **Contract-First API** | All REST services | OpenAPI spec before code, backward compatibility |
| **Infrastructure as Code** | Terraform | Reproducible, auditable infrastructure |
| **GitOps-style CI/CD** | GitHub Actions | Declarative deployments, no manual cluster access |