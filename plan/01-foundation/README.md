# 01 — Foundation

## Goal

Stand up the empty house: repo scaffolding, local dev environment, cloud infra skeleton, K8s cluster baseline, and CI/CD pipelines. No business logic yet — just the substrate every later phase builds on.

## Scope

**In scope:** monorepo layout, Taskfile, docker-compose dev stack, Terraform modules, K8s namespaces + NetworkPolicies, GitHub Actions workflows, Sealed Secrets, container baseline.

**Out of scope:** Keycloak/Kong/Postgres/Redis/Kafka configuration (that's [`../02-platform-services/`](../02-platform-services/)), any service code, any frontend code.

## Prerequisites

- AWS or GCP account with billing enabled and an IAM user/SA with admin on a dev project
- GitHub repo with Actions enabled and a ghcr.io namespace
- `task`, `docker`, `kubectl`, `terraform`, `kubeseal` installed locally

## Sub-files

- [`monorepo-structure.md`](./monorepo-structure.md) — directory layout per design-doc §14
- [`taskfile.md`](./taskfile.md) — Taskfile.yml mirroring design-doc §13
- [`local-dev.md`](./local-dev.md) — `docker-compose.dev.yml` and `task up`
- [`terraform-skeleton.md`](./terraform-skeleton.md) — VPC, EKS/GKE, RDS, MSK, IAM modules
- [`kubernetes-baseline.md`](./kubernetes-baseline.md) — namespaces, NetworkPolicies, quotas, ingress
- [`cicd-baseline.md`](./cicd-baseline.md) — GitHub Actions lint/test/build/push
- [`sealed-secrets.md`](./sealed-secrets.md) — Bitnami controller + workflow
- [`container-baseline.md`](./container-baseline.md) — distroless, non-root, read-only FS

## Phase exit criteria

- [ ] `task up` boots local Postgres + Redis + Kafka + Keycloak + Kong on the host
- [ ] `kubectl get pods -A` on the dev cluster shows ingress controller + sealed-secrets controller healthy
- [ ] A no-op PR triggers GitHub Actions and runs lint + build green
- [ ] Branch protection enforces required checks on `main`
- [ ] A sample sealed secret round-trips: encrypted in git, decrypted in cluster

## Risks

- Cloud account quotas can block EKS/GKE creation — request limit increases before starting Terraform.
- Local Kafka in KRaft mode is recent; pin to a known-good version (Kafka 3.7+) in `docker-compose.dev.yml`.

## References

- Design doc: §13 Monorepo Management, §14 Directory Structure
- ADR-001 Monorepo tooling, ADR-006 CI/CD strategy
