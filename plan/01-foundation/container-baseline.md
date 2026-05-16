# Container Baseline

## Purpose

Establish image standards every service Dockerfile must satisfy: distroless base, non-root user, read-only filesystem, multi-stage builds, image signing. Codified once here so every service Dockerfile in phases 03/04 follows the same pattern.

## Inputs / Prerequisites

- Docker Buildx available locally and in CI
- [`cicd-baseline.md`](./cicd-baseline.md) complete (`task docker:build:all` runs in CI. Images stay local until phase 08 adds registry push)

## Tasks

1. [ ] Author `infra/docker/Dockerfile.go-service.template`. Multi-stage: `golang:1.22-alpine` builder, `gcr.io/distroless/static-debian12:nonroot` runtime (effort: M)
2. [ ] Author `infra/docker/Dockerfile.nextjs.template`. Multi-stage for `web/`, distroless Node (effort: M)
3. [ ] Author `infra/docker/Dockerfile.static.template`. For `admin-web/` (Vite build → nginx-unprivileged or Cloudflare Pages) (effort: S)
4. [ ] Enforce non-root `USER 65532:65532` in every Dockerfile (Pod `securityContext` template lives with K8s baseline in [`../07-cloud-infrastructure/kubernetes-baseline.md`](../07-cloud-infrastructure/kubernetes-baseline.md)) (effort: M)
5. [ ] Enable Buildx cache via GHA cache in `build.yml` (effort: S)
6. [ ] Integrate trivy scan in CI. Fail on HIGH/CRITICAL vulns in scratch base (effort: M)
7. [ ] (Deferred) Image signing with cosign and admission verification. Added in phase 08 alongside deploy workflows (effort: L)

## Deliverables

- `infra/docker/Dockerfile.*.template`
- Trivy job in `build.yml` workflow

## Exit Criteria

- [ ] Every service Dockerfile in `services/*/Dockerfile` is a copy of the template
- [ ] `docker inspect <image>` shows non-root user (UID 65532)
- [ ] Containers run cleanly under `docker compose` with the standard non-root user
- [ ] Trivy scan blocks a deliberately vulnerable test build, passes on clean builds

## References

- Design doc: §9.4 Security Hardening (Container Security row)

## Risks & Open Questions

- Some Go libs assume a writable `/tmp`. Mount a tmpfs at `/tmp` (docker-compose `tmpfs:`. In K8s, `emptyDir` in the Pod template added in phase 07).
- cosign + policy-controller adds operational complexity. Deferred to phase 08 (cloud deployment) and only adopted if required for launch.
