# ADR-006: CI/CD Strategy, GitHub Actions

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
We need a CI/CD pipeline that builds, tests, and deploys all services to Kubernetes. The pipeline must support staging → production promotion with a manual approval gate.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **GitHub Actions** | Native Git integration, no extra infra, YAML workflows, marketplace actions | Less powerful than dedicated CD tools for K8s |
| **ArgoCD** | True GitOps (pull-based), drift detection, K8s-native UI | Extra cluster component to deploy and manage, adds operational overhead |
| **Jenkins** | Highly customizable, plugin-rich | Heavy, requires dedicated infra, maintenance-intensive |
| **GitLab CI** | Integrated with GitLab, good K8s support | Tied to GitLab, not applicable if using GitHub |

## Decision
**GitHub Actions**, source code is on GitHub. Actions provide native CI/CD without additional infrastructure. Workflows handle lint, test, build, push to container registry, and `kubectl apply` to deploy manifests.

### Why not ArgoCD?
ArgoCD provides genuine GitOps benefits (pull-based sync, drift detection). However:
- It's an additional component to deploy, secure, and monitor in the cluster
- For a project of this size (<10 services), the operational overhead outweighs the benefits
- GitHub Actions achieves the same declarative deployment by applying versioned K8s manifests
- **Migration path:** ArgoCD can be adopted later if the team/project grows

## Consequences
- CI/CD is defined in `.github/workflows/`, version-controlled, reviewable
- Deployments are push-based (Actions pushes to K8s), not pull-based (ArgoCD polls Git)
- Manual approval gate for production deployments via GitHub Environments
- No drift detection, accepted trade-off at this scale
