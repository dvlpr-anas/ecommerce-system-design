# Service Manifests

## Purpose

Author Kubernetes manifests for every service built in phases 03, 04, and 05. The local docker-compose stack from phase 02 is the reference for env vars, ports, and dependencies. Manifests translate that into K8s-native primitives and swap local endpoints for managed cloud endpoints (RDS, MSK, ElastiCache).

## Inputs / Prerequisites

- [`../07-cloud-infrastructure/kubernetes-baseline.md`](../07-cloud-infrastructure/kubernetes-baseline.md) complete (namespaces, default-deny NetworkPolicies, ingress, and cert-manager exist)
- All eight services plus three frontends building cleanly in CI (phase 01 build job green)
- Per-service env-var contract documented in each service's README

## Tasks

1. [ ] Per service: `Deployment` (3 replicas dev and staging, 5 prod), `Service` (ClusterIP), `HorizontalPodAutoscaler` (CPU plus custom metrics), `PodDisruptionBudget` (minAvailable = 1). Effort: L.
2. [ ] Per service: allow-list `NetworkPolicy` opening only the egress it needs (its DB, Kafka, Redis, dependent services). Effort: L.
3. [ ] Pod `securityContext` template: non-root UID 65532, read-only root FS, `emptyDir` at `/tmp`, drop all capabilities. Effort: M.
4. [ ] Ingress or Kong route per public service. TLS via cert-manager ClusterIssuer. Effort: M.
5. [ ] Kustomize overlays per env (`dev`, `staging`, `prod`): replica counts, resource requests and limits, image tags, env-var values pointing at managed Postgres, MSK, and ElastiCache. Effort: L.
6. [ ] ConfigMaps for non-secret config. SealedSecrets for credentials (via [`../07-cloud-infrastructure/sealed-secrets.md`](../07-cloud-infrastructure/sealed-secrets.md)). Effort: M.
7. [ ] ServiceAccount plus IRSA or Workload Identity binding per service (scoped IAM, no shared node IAM role). Effort: M.
8. [ ] Liveness and readiness probes match the `/healthz` and `/readyz` endpoints already in services from phase 02 shared libs. Effort: S.

## Deliverables

- `k8s-manifests/base/services/<service>/` with Deployment, Service, HPA, PDB, NetworkPolicy, ServiceAccount
- `k8s-manifests/overlays/{dev,staging,prod}/` with patches per env
- `k8s-manifests/base/podsecurity/` with the securityContext template referenced by every Deployment

## Exit Criteria

- [ ] `kubectl apply -k k8s-manifests/overlays/dev` brings every service up healthy in dev
- [ ] Default-deny NetworkPolicy holds: removing a service's allow-list rule breaks only its declared dependencies
- [ ] Golden-path checkout completes end-to-end against dev cluster using managed Postgres, MSK, and ElastiCache
- [ ] HPA scales a service up under synthetic load and back down when load drops

## References

- Design doc: §3 Architecture Diagrams, §9.4 Security Hardening, §11 Deployment Strategy

## Risks & Open Questions

- Managed Kafka (MSK) auth differs from the local PLAINTEXT broker. Services need to handle IAM-SASL or SCRAM. Test in dev before staging.
- HPA on custom metrics requires the metrics adapter (Prometheus adapter). Install in phase 07 if not already.
