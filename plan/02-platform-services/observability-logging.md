# Observability — Logging

## Purpose

Every service emits structured JSON logs (Go `slog`) to stdout. Container runtime ships logs to Loki. Each log line carries `request_id`, `user_id`, `service`, `duration_ms` per design-doc §10.2, enabling end-to-end correlation across services.

## Inputs / Prerequisites

- `shared-go-libs.md`: `pkg/middleware/Logger` exists
- `kubernetes-baseline.md`: `observability` namespace exists

## Tasks

1. [ ] Install Loki via Helm into `observability` (single-binary mode for dev, distributed for prod) — effort: M
2. [ ] Install Promtail (or Grafana Alloy) as DaemonSet to scrape container stdout — effort: M
3. [ ] Configure log labels: `service`, `namespace`, `pod`, `request_id` (extracted from JSON) — effort: M
4. [ ] Set retention: 7d dev, 14d staging, 30d prod — effort: S
5. [ ] Enforce JSON log format by linting `pkg/middleware/Logger` config (no `text` handlers in prod) — effort: S
6. [ ] Add Loki datasource to Grafana — effort: S
7. [ ] Document a `request_id` → cross-service trace recipe in `06-hardening/runbooks.md` template — effort: S

## Deliverables

- Loki Helm release with persistent volume (or S3 backend for prod)
- Promtail DaemonSet
- Grafana datasource manifest
- Log retention policy as code

## Exit Criteria

- [ ] `kubectl logs <service-pod>` shows JSON-formatted lines
- [ ] Grafana Explore tab queries Loki and returns logs filtered by `service`
- [ ] A `request_id` filter shows logs from multiple services for the same end-to-end request

## References

- Design doc: §10.1 Three Pillars, §10.2 Standard Log Format
- ADR-007 Observability

## Risks & Open Questions

- Loki at scale needs object storage backend (S3/GCS) — single-binary FS-backed is dev-only.
- PII in logs is a compliance risk. Add a `pkg/middleware/Logger` filter that redacts known PII keys (email, phone, address) — track as ADR if scope grows.
