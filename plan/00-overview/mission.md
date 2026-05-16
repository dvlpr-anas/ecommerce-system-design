# Mission

Build a production-grade, event-driven e-commerce platform on Kubernetes that demonstrates Solution Architect-level thinking: justified technology trade-offs (one ADR per major decision), failure-mode design (Saga, Outbox, circuit breakers, DLQs), operational maturity (SLOs, runbooks, DR drills), and security-first architecture (OIDC + PKCE, strict CSP, expand-and-contract migrations).

The platform serves three clients — a React Native mobile app (iOS + Android), a Next.js customer web storefront, and a React + Vite admin SPA — all backed by eight Go microservices behind a Kong API gateway, communicating asynchronously over Kafka and synchronously over REST.

## Target outcomes

- Customers can browse, add to cart, and checkout end-to-end on mobile and web, with Stripe payments.
- Admins can manage catalog, view orders, and issue refunds.
- Platform sustains the design-doc §12.3 load profile: steady ~1k concurrent / ~200 orders/min, peak ~10k / ~2k.
- All services have SLOs, runbooks, dashboards, and alerts.
- Zero-downtime deployments via rolling updates + expand-and-contract migrations.

## References

- Design doc: §1 Executive Summary, §2 Technology Stack
