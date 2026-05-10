# ADR-007: Observability, slog + Prometheus + Grafana

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
A distributed system with 8 services, Kafka, and PostgreSQL requires observability to diagnose issues, monitor health, and alert on anomalies. We need to balance operational maturity with infrastructure complexity.

## Options Considered

### Logging

| Option | Pros | Cons |
|---|---|---|
| **Go `slog` (structured JSON to stdout)** | Zero dependencies, K8s-native (container logs), structured | No centralized search without additional tooling |
| **ELK Stack** | Powerful search, Kibana dashboards | 3 heavy Java services, significant operational burden |
| **Grafana Loki** | Lightweight, Grafana-integrated, label-based | Less powerful query language than Elasticsearch |

### Metrics

| Option | Pros | Cons |
|---|---|---|
| **Prometheus + Grafana** | Industry standard, K8s-native service discovery, rich ecosystem | Requires running Prometheus in-cluster |
| **Datadog/New Relic** | Fully managed, powerful | Expensive, cloud vendor dependency |
| **No metrics** | Zero overhead | Blind to performance issues, unacceptable for production |

### Distributed Tracing

| Option | Pros | Cons |
|---|---|---|
| **OpenTelemetry + Tempo/Jaeger** | End-to-end request tracing, excellent debugging | SDK instrumentation in every service, Tempo/Jaeger to operate |
| **Request ID propagation** | Simple, zero infra, correlate logs across services | No visual trace waterfall, manual log correlation |

## Decision
1. **Logging:** Go `slog` with structured JSON output to stdout. K8s collects container logs natively. Centralized log aggregation (Loki) can be added later.
2. **Metrics:** Prometheus + Grafana. Each service exposes `/metrics`. Prometheus scrapes via K8s service discovery.
3. **Tracing:** `X-Request-ID` propagation (generated at Kong, forwarded through all services). No OpenTelemetry SDK, saves complexity. Upgrade path to OTel exists.

## Consequences
- Lightweight observability stack: Prometheus + Grafana only (2 components)
- Structured logs with `request_id` enable cross-service log correlation without a tracing backend
- No visual trace waterfall, accepted trade-off, `request_id` grep across logs is sufficient at this scale
- Clear upgrade path: add Loki for centralized logs, add OTel for tracing when the team/scale demands it
