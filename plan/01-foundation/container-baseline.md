# Container Baseline

## Purpose

Establish image standards every service Dockerfile must satisfy: distroless base, non-root user, read-only filesystem, multi-stage builds, image signing. Codified once here so every service Dockerfile in phases 03/04 follows the same pattern.

## Inputs / Prerequisites

- Docker Buildx available locally and in CI
- `cicd-baseline.md` complete (ghcr.io push works)

## Tasks

1. [ ] Author `infra/docker/Dockerfile.go-service.template` — multi-stage: `golang:1.22-alpine` builder, `gcr.io/distroless/static-debian12:nonroot` runtime — effort: M
2. [ ] Author `infra/docker/Dockerfile.nextjs.template` — multi-stage for `web/`, distroless Node — effort: M
3. [ ] Author `infra/docker/Dockerfile.static.template` — for `admin-web/` (Vite build → nginx-unprivileged or Cloudflare Pages) — effort: S
4. [ ] Enforce non-root `USER 65532:65532` and read-only root FS via Pod `securityContext` template under `k8s-manifests/base/podsecurity/` — effort: M
5. [ ] Enable Buildx cache via GHA cache in `build-push.yml` — effort: S
6. [ ] Integrate trivy scan in CI; fail on HIGH/CRITICAL vulns in scratch base — effort: M
7. [ ] (Optional) Sign images with cosign and verify on cluster admission via policy-controller — effort: L

## Deliverables

- `infra/docker/Dockerfile.*.template`
- Pod `securityContext` template manifest
- Trivy job in build-push workflow
- (Optional) cosign key in Sealed Secrets, verification webhook in `platform`

## Exit Criteria

- [ ] Every service Dockerfile in `services/*/Dockerfile` is a copy of the template
- [ ] `docker inspect <image>` shows non-root user (UID 65532)
- [ ] A pod with the standard `securityContext` running the image works (no write to /tmp without an `emptyDir` volume)
- [ ] Trivy scan blocks a deliberately vulnerable test build, passes on clean builds

## References

- Design doc: §9.4 Security Hardening (Container Security row)

## Risks & Open Questions

- Some Go libs assume a writable `/tmp`. Mount `emptyDir` at `/tmp` in every Pod template to satisfy read-only root FS.
- cosign + policy-controller adds operational complexity; defer to phase 06 if not strictly required for launch.
