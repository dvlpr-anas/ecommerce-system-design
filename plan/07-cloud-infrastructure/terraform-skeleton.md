# Terraform Skeleton

## Purpose

Author the IaC modules that will provision the cloud substrate (VPC, K8s cluster, managed Postgres, managed Kafka, IAM, DNS). Modules are written and validated in this phase but **not applied to production**. Applying happens incrementally as later phases need real infrastructure.

## Inputs / Prerequisites

- Cloud account chosen (AWS or GCP) and credentials configured locally
- Terraform 1.7+ installed
- Remote state backend decided (S3 + DynamoDB lock, or GCS)

## Tasks

1. [ ] Create `terraform/` layout: `modules/`, `envs/dev/`, `envs/staging/`, `envs/prod/`, `backend.tf` (effort: M)
2. [ ] Module: `modules/network/`, VPC, public/private subnets across 3 AZs, NAT gateways, route tables (effort: L)
3. [ ] Module: `modules/k8s-cluster/`, EKS (or GKE) with managed node groups, IRSA / Workload Identity enabled (effort: L)
4. [ ] Module: `modules/postgres/`, RDS or Cloud SQL Postgres 16 with parameter group, automated backups, PITR enabled (effort: M)
5. [ ] Module: `modules/kafka/`, MSK (or Confluent Cloud provider) with topic auto-creation disabled (effort: L)
6. [ ] Module: `modules/iam-roles/`, IRSA / Workload Identity bindings for each service (allows scoped access to Secrets Manager, S3 image bucket) (effort: M)
7. [ ] Module: `modules/dns/`, Route53 / Cloud DNS zone, ACM/Managed certificates for `*.example.com` (effort: M)
8. [ ] Configure remote state in `backend.tf` with state locking (effort: S)
9. [ ] Wire `envs/dev/main.tf` to call every module with dev-sized inputs (effort: M)
10. [ ] Add `terraform fmt` + `tflint` + `tfsec` to CI (extend the workflow from [`../01-foundation/cicd-baseline.md`](../01-foundation/cicd-baseline.md) with a `terraform` job gated on paths under `terraform/`) (effort: S)

## Deliverables

- `terraform/modules/*` for network, k8s-cluster, postgres, kafka, iam-roles, dns
- `terraform/envs/{dev,staging,prod}/main.tf` calling the modules
- Remote state backend configured
- CI step that runs `terraform validate` on every module

## Exit Criteria

- [ ] `terraform validate` passes for every module
- [ ] `terraform plan` against the dev env produces a plan without errors
- [ ] `tfsec` reports zero high-severity findings
- [ ] State backend works: two engineers can `terraform plan` from different machines without conflict

## References

- Design doc: §2 Technology Stack (IaC = Terraform), §11 Deployment Strategy

## Risks & Open Questions

- MSK is expensive in small environments. Confluent Cloud or self-hosted Strimzi on EKS may be cheaper for dev/staging. Decide in an ADR before applying to dev.
- Workload Identity (GCP) and IRSA (AWS) differ enough that the `iam-roles` module probably needs separate AWS and GCP submodules. Pick one cloud first.
