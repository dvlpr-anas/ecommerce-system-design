# CI/CD Baseline

## Purpose

Define the GitHub Actions pipelines that every PR and merge to `main` will trigger: lint, test, build, container publish, manifest update. Detailed promotion logic (staging → prod with manual gate) is built in this phase; the manifests it updates are filled in by later phases.

## Inputs / Prerequisites

- `taskfile.md` complete (workflows call `task` commands)
- GitHub Actions enabled on the repo
- ghcr.io namespace available; PAT or GITHUB_TOKEN scopes confirmed
- `terraform-skeleton.md` applied to dev (the deploy target exists)

## Tasks

1. [ ] Workflow `.github/workflows/ci.yml` triggered on PRs: matrix lint + unit tests for Go services and TS packages via `task lint:all` + `task test:all` — effort: M
2. [ ] Workflow `.github/workflows/build-push.yml` triggered on push to `main`: `task docker:build:all`, tag with Git SHA, push to ghcr.io — effort: M
3. [ ] Workflow `.github/workflows/deploy-staging.yml` triggered after build-push succeeds: update image tags in `k8s-manifests/overlays/staging/`, open PR or kubectl apply — effort: M
4. [ ] Workflow `.github/workflows/deploy-prod.yml` with manual approval gate (GitHub Environments protection rules) — effort: M
5. [ ] Add `terraform validate` + `tflint` + `tfsec` job to PR CI for any change touching `terraform/` — effort: S
6. [ ] Add `govulncheck` + `npm audit` jobs gated by severity threshold — effort: M
7. [ ] Configure branch protection on `main`: require ci.yml green, require 1 review, dismiss stale approvals, no force-push — effort: S
8. [ ] Configure GitHub Environments `staging` and `production` with required reviewers — effort: S
9. [ ] Cache key tuning: pnpm, Go modules, Docker buildx — effort: M

## Deliverables

- `.github/workflows/{ci,build-push,deploy-staging,deploy-prod}.yml`
- `.github/CODEOWNERS` for `services/`, `web/`, `mobile/`, `terraform/`, `plan/`
- Branch protection rules configured (document the JSON via `gh api`)

## Exit Criteria

- [ ] A no-op PR triggers `ci.yml` and goes green
- [ ] A merge to `main` produces a new image in ghcr.io tagged with the commit SHA
- [ ] Force-push to `main` is rejected
- [ ] Prod deploy requires a reviewer click in the GitHub Environments UI
- [ ] `govulncheck` job fails CI when an obviously vulnerable dep is introduced (test with a deliberately old `gopkg.in/yaml.v2` pin, then revert)

## References

- Design doc: §11.1 CI/CD Pipeline
- ADR-006 CI/CD strategy

## Risks & Open Questions

- GitHub Actions minutes can balloon on big matrix builds — measure after phase 03 and prune the matrix if needed.
- Deploy workflows currently use `kubectl apply` (push model). If ArgoCD is adopted later, these become PR-only manifest updates and ArgoCD reconciles. Decide before phase 05.
