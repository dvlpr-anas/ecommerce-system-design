# 07: Cloud Infrastructure

## Goal

First cloud phase. Provision the cloud substrate the locally-built system will be deployed onto: VPC, Kubernetes cluster, managed Postgres plus Kafka, IAM, DNS, K8s namespaces and NetworkPolicies, Sealed Secrets, and container registry. **No service deployments in this phase.** Those happen in phase 08.

## Scope

**In scope:** Terraform modules (network, K8s cluster, Postgres, Kafka, IAM, DNS), cluster baseline (namespaces, default-deny NetworkPolicies, ingress controller, cert-manager, metrics-server), Sealed Secrets controller, container registry setup (ghcr.io or cloud-native).

**Out of scope:** service manifests, deploy workflows, chaos, DR, SLO, alerting (all in phase 08), business logic, frontends.

## Prerequisites

- Phases 01 through 06 complete (system runs end-to-end locally, hardened to local-feasible bar)
- Cloud account chosen (AWS or GCP) with billing enabled, IAM admin user or SA on a dev project
- `terraform` 1.7 or newer, `kubectl`, `helm` 3.x, and `kubeseal` installed locally
- Remote state backend decided (S3 plus DynamoDB lock, or GCS)

## Sub-files

- [`terraform-skeleton.md`](./terraform-skeleton.md): VPC, EKS or GKE, RDS, MSK, IAM modules. `envs/{dev,staging,prod}/`.
- [`kubernetes-baseline.md`](./kubernetes-baseline.md): namespaces, NetworkPolicies, quotas, ingress controller, cert-manager
- [`sealed-secrets.md`](./sealed-secrets.md): Bitnami controller, encryption workflow, CI guard against raw secrets
- [`container-registry.md`](./container-registry.md): registry chosen (ghcr.io, ECR, or Artifact Registry), CI auth, retention policy

## Phase exit criteria

- [ ] `terraform apply` against `envs/dev/` brings up VPC, K8s cluster, managed Postgres, managed Kafka, IAM bindings, DNS zone
- [ ] `kubectl get pods -A` shows ingress controller, cert-manager, and Sealed Secrets controller all Running
- [ ] A sample sealed secret round-trips: encrypted in git, decrypted to a native `Secret` in cluster
- [ ] Container registry exists and CI can authenticate to it (push not yet wired, that arrives in phase 08)
- [ ] `tfsec` reports zero high-severity findings on every env

## Risks

- Cloud account quotas (EKS or GKE node counts, MSK brokers, RDS instance class) can block creation. Request limit increases before starting Terraform.
- Workload Identity (GCP) versus IRSA (AWS) differ. The `iam-roles` module likely needs cloud-specific submodules. Pick one cloud first.
- Sealed Secrets locks secrets to a single cluster's key. Multi-env requires separate sealed copies per cluster. Document in the workflow.

## References

- Design doc: §2 Technology Stack, §9.4 Security Hardening, §11 Deployment Strategy
- ADR-007 Observability (Secrets adjacent)
