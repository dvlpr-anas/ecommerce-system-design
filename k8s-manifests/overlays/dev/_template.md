# Dev overlays

One Deployment + Service per Go microservice, all driven by Tilt. Each manifest:

- Pulls the image tag Tilt populates (`<service>:dev` via the in-cluster
  registry `k3d-sol-arch-registry:5005`).
- Mounts `sol-arch-env` ConfigMap (projected from `infra/dev/.env.dev`).
- Exposes `/healthz` and `/readyz` probes wired to the listening port.
- Stays minimal — production hardening (resource limits, PDBs, HPAs,
  NetworkPolicies, ServiceAccounts with RBAC) lives in `overlays/prod/`
  (phase 07). The shared bits will move to `k8s-manifests/base/` then.

Files in this folder are intentionally repetitive rather than templated;
Kustomize handles the prod base/overlay collapse in phase 07.
