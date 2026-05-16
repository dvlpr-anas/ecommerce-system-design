# Kubernetes Baseline

## Purpose

Stand up cluster-level primitives that every service in later phases depends on: namespaces, default-deny network policies, resource quotas, ingress controller. No service deployments yet.

## Inputs / Prerequisites

- `terraform-skeleton.md` applied for the dev environment (cluster exists)
- `kubectl` context pointed at the dev cluster
- `helm` 3.x installed

## Tasks

1. [ ] Create `k8s-manifests/base/` and `k8s-manifests/overlays/{dev,staging,prod}/` (Kustomize layout) — effort: S
2. [ ] Create namespaces: `platform` (Keycloak, Kong, Sealed Secrets), `services` (Go services), `observability` (Prometheus, Grafana, Loki), `data` (Postgres operator if self-hosted, Redis cluster) — effort: S
3. [ ] Apply default-deny `NetworkPolicy` in `services` and `data` namespaces; allow-list policies live with each service in later phases — effort: M
4. [ ] Set `ResourceQuota` per namespace (CPU/memory limits) — effort: S
5. [ ] Install Kong ingress controller via Helm into `platform` namespace (config deferred to `02-platform-services/kong-gateway.md`) — effort: M
6. [ ] Install cert-manager into `platform` namespace; configure ClusterIssuer for Let's Encrypt (DNS-01 via Route53/Cloud DNS) — effort: M
7. [ ] Install metrics-server (required for HPA later) — effort: S
8. [ ] Document `kubectl` access via SSO (AWS IAM Identity Center or GCP IAM) in root README — effort: S

## Deliverables

- `k8s-manifests/base/namespaces.yaml`
- `k8s-manifests/base/network-policies.yaml` (default-deny)
- `k8s-manifests/base/resource-quotas.yaml`
- Helm releases recorded in `k8s-manifests/base/helm-releases/` (use Helmfile or ArgoCD app manifests)

## Exit Criteria

- [ ] `kubectl get ns` shows `platform`, `services`, `observability`, `data`
- [ ] `kubectl get networkpolicy -n services` shows the default-deny policy
- [ ] `kubectl get pods -n platform` shows Kong + cert-manager pods Running
- [ ] `kubectl get clusterissuer` shows letsencrypt-prod issuer Ready
- [ ] A test deployment without an explicit allow-list NetworkPolicy cannot reach the internet (verifies default-deny works)

## References

- Design doc: §2 Technology Stack (Orchestration), §9.4 NetworkPolicies, §11 Deployment Strategy

## Risks & Open Questions

- Kustomize vs Helm vs ArgoCD App-of-Apps for manifest management — pick one before phases 03/04 add 8 services worth of manifests.
