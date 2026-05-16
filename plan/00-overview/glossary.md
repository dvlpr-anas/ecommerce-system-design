# Glossary

| Term | Definition |
|---|---|
| **ADR** | Architecture Decision Record. Markdown document capturing one significant decision, its context, and consequences. See [`../../docs/adrs/`](../../docs/adrs/). |
| **Bulkhead** | Resource isolation pattern. Each service gets bounded CPU/memory and bounded connection pools so a runaway component cannot starve others. |
| **Circuit Breaker** | State machine wrapping a remote call. Opens after N consecutive failures, fails fast for a cooldown, probes via half-open. Prevents cascading failure. |
| **CQRS** | Command Query Responsibility Segregation. Write model and read model are separate. E.g., Product Service writes to canonical tables, reads from a tsvector search projection. |
| **CSP** | Content Security Policy. HTTP header that restricts which scripts/styles a browser will execute. |
| **DLQ** | Dead Letter Queue. Per-topic Kafka topic (`*.dlq`) that captures messages which failed all retry attempts. |
| **Expand-and-Contract** | Two-release pattern for breaking schema/API changes. Release N adds the new shape alongside the old. Release N+1 removes the old. |
| **Idempotency Key** | Client-supplied unique key on a request so the server can detect retries and return the previous result rather than re-executing. |
| **ISR** | Incremental Static Regeneration (Next.js). Static pages regenerated on demand via webhook from backend events. |
| **OIDC** | OpenID Connect. Identity layer on top of OAuth 2.0. What Keycloak speaks. |
| **Outbox (Transactional)** | Pattern that writes domain events to an `outbox` table in the same DB transaction as state changes, then a poller publishes them to Kafka. Guarantees atomicity without two-phase commit. |
| **PKCE** | Proof Key for Code Exchange. OAuth 2.0 extension required for public clients (mobile, SPA) to prevent code interception. |
| **RBAC** | Role-Based Access Control. `customer`, `support`, `admin`, `service` roles in Keycloak. |
| **RPO** | Recovery Point Objective. Maximum tolerated data loss measured in time (e.g., "RPO = 5 minutes"). |
| **RTO** | Recovery Time Objective. Maximum tolerated downtime measured in time (e.g., "RTO = 30 minutes"). |
| **Saga (Choreography)** | Distributed transaction pattern. No central coordinator. Services react to events from a Kafka topic and emit compensation events on failure. See design-doc §6.2. |
| **SLO** | Service Level Objective. Measurable target (e.g., "99.9% of checkout p95 < 500ms over 28 days"). |
| **tsvector** | PostgreSQL full-text search type. Used by Product Service as the search projection. |

## References

- Design doc: §1 Core Patterns
- All ADRs
