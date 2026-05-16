# Observability — Metrics

## Purpose

Every service exposes `/metrics` (Prometheus format). Prometheus Operator scrapes via ServiceMonitor CRs. Seven standard metrics from design-doc §10.3 are emitted by every service so dashboards and alerts can be uniform.

## Inputs / Prerequisites

- `shared-go-libs.md`: `pkg/middleware/Metrics` and `pkg/httpserver` expose `/metrics`
- `kubernetes-baseline.md`: `observability` namespace + metrics-server installed

## Tasks

1. [ ] Install kube-prometheus-stack via Helm into `observability` (Prometheus Operator + Alertmanager + Grafana) — effort: M
2. [ ] Author a `ServiceMonitor` template under `k8s-manifests/base/observability/servicemonitor.yaml` referenced by every service — effort: S
3. [ ] Verify each of the seven standard metrics emits correctly from a hello-world service:
   - `http_requests_total` (counter, labels: service, method, path, status)
   - `http_request_duration_seconds` (histogram)
   - `kafka_consumer_lag` (gauge, labels: group, topic, partition)
   - `kafka_messages_processed_total` (counter, labels: event_type)
   - `circuit_breaker_state` (gauge, 0/1/2)
   - `outbox_pending_count` (gauge, labels: service)
   - `db_pool_active_connections` (gauge)
   — effort: M
4. [ ] Configure Alertmanager routes: Slack `#alerts-platform` + PagerDuty for SEV-1 — effort: M
5. [ ] Retention: 15d in Prometheus; long-term storage via Thanos or Mimir deferred to phase 06 — effort: S
6. [ ] Add `PodMonitor` for Kafka consumer pods (sidecar exporters where needed) — effort: M

## Deliverables

- Prometheus stack Helm release
- `ServiceMonitor` and `PodMonitor` templates
- Alertmanager config (sealed-secret API tokens)
- Verified standard metric emission

## Exit Criteria

- [ ] `kubectl get servicemonitors -A` shows the template
- [ ] `curl http://prometheus.example.com/api/v1/targets` shows every service scraped
- [ ] Query `http_requests_total{service="hello-service"}` returns data
- [ ] A test alert fires to Slack within 60s of breach

## References

- Design doc: §10.1 Three Pillars, §10.3 Key Metrics
- ADR-007 Observability

## Risks & Open Questions

- Histogram cardinality can explode if `path` label is high-cardinality (e.g. unbounded IDs). Use `pkg/middleware/Metrics` to normalize paths against the OpenAPI route template, not raw URLs.
