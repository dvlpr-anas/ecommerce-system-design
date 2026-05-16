# CI/CD Deployment Workflows

## Purpose

Extend the local-only CI from [`../01-foundation/cicd-baseline.md`](../01-foundation/cicd-baseline.md) with the deploy half: push images to the registry, update manifest tags, promote across `dev` to `staging` to `prod` with a manual gate at prod.

## Inputs / Prerequisites

- [`../01-foundation/cicd-baseline.md`](../01-foundation/cicd-baseline.md) green (build job already runs on `main`)
- [`../07-cloud-infrastructure/container-registry.md`](../07-cloud-infrastructure/container-registry.md) complete (registry exists, CI can auth via OIDC)
- [`service-manifests.md`](./service-manifests.md) drafted (Kustomize overlays exist per env)

## Tasks

1. [ ] Extend `.github/workflows/build.yml` (from phase 01) to push images to the registry on `main` push, tagged `<git-sha>`. Effort: S.
2. [ ] Workflow `.github/workflows/deploy-dev.yml` triggered after build and push: bump image tag in `k8s-manifests/overlays/dev/`, commit and push (GitOps) or `kubectl apply` (push). Effort: M.
3. [ ] Workflow `.github/workflows/deploy-staging.yml` triggered on dev success: same pattern against staging overlay. Effort: M.
4. [ ] Workflow `.github/workflows/deploy-prod.yml` with manual approval gate via GitHub Environments. Effort: M.
5. [ ] Configure GitHub Environments `dev`, `staging`, `production` with appropriate required reviewers or wait timers. Effort: S.
6. [ ] Decide push versus GitOps: if ArgoCD is adopted, workflows only PR manifest changes and ArgoCD reconciles. Record decision in an ADR. Effort: M.
7. [ ] Add rollback workflow (`deploy-rollback.yml`): re-deploy a prior known-good image tag with one click. Effort: M.
8. [ ] (Optional) Sign images with cosign on push, and verify on cluster admission via policy-controller. Effort: L.

## Deliverables

- `.github/workflows/{deploy-dev,deploy-staging,deploy-prod,deploy-rollback}.yml`
- GitHub Environments configured with reviewers
- ADR recording push versus GitOps decision

## Exit Criteria

- [ ] A merge to `main` produces a new image in the registry tagged with the commit SHA
- [ ] Dev cluster receives the new image within roughly 5 min of merge
- [ ] Staging deploy succeeds end-to-end and golden-path checkout passes
- [ ] Prod deploy requires a reviewer click in the GitHub Environments UI
- [ ] Rollback workflow reverts to a prior tag in under 2 min

## References

- Design doc: §11.1 CI/CD Pipeline, §11.4 Rollback Plan
- ADR-006 CI/CD strategy

## Risks & Open Questions

- Push model (`kubectl apply` from CI) is simpler. GitOps (ArgoCD) is auditable and self-healing. Pick before adding the eighth service's manifests, otherwise migration is painful.
- Image signing plus admission verification adds operational complexity. Only adopt if compliance or threat model demands it.
