# Observability — Dashboards

## Purpose

Three default Grafana dashboards from design-doc §10.4 provisioned as code so every service inherits visibility on day one: Service Health (RED metrics), Kafka Health, Infrastructure. Per-service dashboards extend these as needed.

## Inputs / Prerequisites

- `observability-metrics.md` complete (Prometheus scraping works)
- `observability-logging.md` complete (Loki datasource added)

## Tasks

1. [ ] Author **Service Health** dashboard JSON:
   - Request rate (per service)
   - Error rate (5xx as % of total)
   - p50 / p95 / p99 latency
   - In-flight requests
   - Circuit breaker state heatmap
   — effort: M
2. [ ] Author **Kafka Health** dashboard JSON:
   - Consumer lag per group/topic
   - Throughput (msgs/sec) in + out
   - DLQ count per topic
   - Broker disk usage
   — effort: M
3. [ ] Author **Infrastructure** dashboard JSON:
   - Pod CPU/memory per service
   - Postgres connection pool utilization
   - Redis memory usage + hit/miss ratio
   - Node-level resource pressure
   — effort: M
4. [ ] Provision dashboards via Grafana sidecar discovery: ConfigMaps labeled `grafana_dashboard=1` under `k8s-manifests/base/dashboards/` — effort: S
5. [ ] Add a "drill-down to logs" link from each panel via the Loki datasource (`{service="$service",request_id=~".*"}`) — effort: M
6. [ ] Define dashboard versioning: dashboards stored in Git, never edited in Grafana UI directly. Document this in a panel note — effort: S

## Deliverables

- Three dashboard JSON files under `k8s-manifests/base/dashboards/`
- ConfigMap-based provisioning that survives Grafana restart
- "View logs" link from every panel

## Exit Criteria

- [ ] Three dashboards appear in Grafana after a fresh install
- [ ] All panels show data for the hello-world service
- [ ] Clicking a metric panel deep-links to filtered Loki logs

## References

- Design doc: §10.4 Grafana Dashboards
- ADR-007 Observability

## Risks & Open Questions

- Dashboards drift fast as services evolve. Add a CI check that opens `dashboard JSON` and lints panel queries against current metric names — bug-prone but valuable.
