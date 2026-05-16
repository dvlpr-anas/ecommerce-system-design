# Container Registry

## Purpose

Pick and provision the registry that will hold all service images once cloud deployment starts. Until phase 08 wires push into CI, the registry exists only as a target. Images are still built locally in CI (phase 01).

## Inputs / Prerequisites

- Cloud account chosen (AWS or GCP), or org-level ghcr.io namespace available
- IAM roles from [`terraform-skeleton.md`](./terraform-skeleton.md) include registry push and pull permissions

## Tasks

1. [ ] Pick the registry: ghcr.io (default), ECR (AWS), or Artifact Registry (GCP). Decide via short ADR. Effort: S.
2. [ ] Provision the registry (Terraform: `aws_ecr_repository` per service, or `google_artifact_registry_repository`. ghcr.io needs no provisioning). Effort: M.
3. [ ] Configure CI authentication: OIDC federation from GitHub Actions to AWS or GCP (preferred over long-lived PATs). For ghcr.io, the workflow's `GITHUB_TOKEN` suffices. Effort: M.
4. [ ] Define image naming convention: `<registry>/<org>/<service>:<git-sha>` and `:<git-sha>-<env>` for promoted images. Effort: S.
5. [ ] Set retention policy: keep tagged `main` builds 90 days, untagged builds 7 days. Effort: S.
6. [ ] Configure image pull credentials in the cluster (IRSA or Workload Identity binding, or imagePullSecret as fallback). Effort: M.
7. [ ] Smoke test: manually `docker push` a hello-world image and `kubectl run` it on the dev cluster. Effort: S.

## Deliverables

- Registry provisioned (Terraform or ghcr.io org namespace)
- CI OIDC trust policy configured (no static credentials in GitHub secrets)
- Image naming plus retention policy documented in `infra/registry/README.md`
- Cluster can pull from the registry without imagePullSecret hacks

## Exit Criteria

- [ ] Manual `docker push` succeeds from a developer laptop using short-lived creds
- [ ] `kubectl run smoke --image=<registry>/<org>/hello:v1` succeeds on the dev cluster
- [ ] Untagged images older than 7 days are auto-pruned (verify via lifecycle policy)

## References

- Design doc: §11 Deployment Strategy
- ADR-006 CI/CD strategy

## Risks & Open Questions

- ghcr.io is simplest but ties registry availability to GitHub. ECR and Artifact Registry colocate with the cluster (faster pulls, no egress) but add Terraform surface area.
- Avoid long-lived registry tokens in GitHub secrets. Always prefer OIDC federation.
