# CI/CD Baseline (Local CI Only)

## Purpose

Define the GitHub Actions pipelines that every PR and merge to `main` will trigger for **lint, test, and local Docker build**. Deploy workflows (push to registry, apply K8s manifests, environment promotion) are deliberately deferred to [`../08-cloud-deployment/cicd-deploy.md`](../08-cloud-deployment/cicd-deploy.md), since there is no cloud target to deploy to until phase 07.

## Inputs / Prerequisites

- [`taskfile.md`](./taskfile.md) complete (workflows call `task` commands)
- GitHub Actions enabled on the repo

## Tasks

1. [ ] Workflow `.github/workflows/ci.yml` triggered on PRs: matrix lint plus unit tests for Go services and TS packages via `task lint:all` and `task test:all`. Effort: M.
2. [ ] Workflow `.github/workflows/build.yml` triggered on push to `main`: `task docker:build:all` (build only, do not push, since there is no registry yet). Effort: S.
3. [ ] Add `govulncheck` and `npm audit` jobs gated by severity threshold. Effort: M.
4. [ ] Configure branch protection on `main`: require `ci.yml` green, require 1 review, dismiss stale approvals, no force-push. Effort: S.
5. [ ] Cache key tuning: pnpm, Go modules, Docker buildx local cache. Effort: M.
6. [ ] `CODEOWNERS` for `services/`, `web/`, `mobile/`, `plan/`. Effort: S.

## Deliverables

- `.github/workflows/{ci,build}.yml`
- `.github/CODEOWNERS`
- Branch protection rules configured

## Exit Criteria

- [ ] A no-op PR triggers `ci.yml` and goes green
- [ ] A merge to `main` produces a successful `docker build` for every service (image stays local to the runner, no push)
- [ ] Force-push to `main` is rejected
- [ ] `govulncheck` job fails CI when an obviously vulnerable dep is introduced (test with a deliberately old `gopkg.in/yaml.v2` pin, then revert)

## References

- Design doc: §11.1 CI/CD Pipeline (build half. The deploy half lives in phase 08.)
- ADR-006 CI/CD strategy

## Risks & Open Questions

- GitHub Actions minutes can balloon on big matrix builds. Measure after phase 03 and prune the matrix if needed.
- Deploy automation (registry push, manifest update, environment promotion) is intentionally not built here. It is added in [`../08-cloud-deployment/cicd-deploy.md`](../08-cloud-deployment/cicd-deploy.md) once a cluster and registry exist.
