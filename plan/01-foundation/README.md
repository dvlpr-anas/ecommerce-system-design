# 01: Foundation (Local)

## Goal

Stand up the local developer substrate: repo scaffolding, Taskfile, docker-compose dev stack, container baseline, and a CI pipeline that lints, tests, and builds. **No cloud, no Kubernetes, and no Terraform in this phase.** All of that is deferred to phase 07.

## Scope

**In scope:** monorepo layout, Taskfile, docker-compose dev stack, container baseline (distroless, non-root, read-only FS), GitHub Actions for lint, test, and build (no deploy steps).

**Out of scope:**
- Cloud infrastructure, K8s cluster, Sealed Secrets (see [`../07-cloud-infrastructure/`](../07-cloud-infrastructure/))
- Deploy workflows: push to registry, apply manifests (see [`../08-cloud-deployment/`](../08-cloud-deployment/))
- Keycloak, Kong, Postgres, Redis, Kafka configuration (see [`../02-platform-services/`](../02-platform-services/))
- Any service or frontend code

## Prerequisites

- `docker` and `docker compose` installed locally (and `git`). No `task`, `go`, `node`, or `pnpm` on the host. The repo ships a `./dev` wrapper that runs every command inside a `sol-arch-tools` container.
- GitHub repo with Actions enabled (no cloud account required yet)

## Sub-files

- [`monorepo-structure.md`](./monorepo-structure.md): directory layout per design-doc §14
- [`taskfile.md`](./taskfile.md): Taskfile.yml mirroring design-doc §13
- [`local-dev.md`](./local-dev.md): `docker-compose.dev.yml` and `task up`
- [`container-baseline.md`](./container-baseline.md): distroless, non-root, read-only FS. Images are built locally and only pushed to a registry in phase 08.
- [`cicd-baseline.md`](./cicd-baseline.md): GitHub Actions for lint, test, and build only. Deploy workflows live in phase 08.

## Phase exit criteria

- [ ] `task up` boots local Postgres, Redis, Kafka, Keycloak, and Kong on the host
- [ ] `task down` cleanly tears the stack down
- [ ] A no-op PR triggers GitHub Actions and runs lint, test, and build green
- [ ] Branch protection enforces required checks on `main`
- [ ] Every service Dockerfile builds successfully with `task docker:build:all` against a local Docker daemon

## Risks

- Local Kafka in KRaft mode is recent. Pin to a known-good version (Kafka 3.7 or newer) in `docker-compose.dev.yml`.
- Resource budget on dev laptops can be tight once all platform services plus 8 microservices are running. Document recommended Docker Desktop memory allocation (12 GB or more).

## References

- Design doc: §13 Monorepo Management, §14 Directory Structure
- ADR-001 Monorepo tooling, ADR-006 CI/CD strategy
