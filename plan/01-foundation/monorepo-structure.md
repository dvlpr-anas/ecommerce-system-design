# Monorepo Structure

## Purpose

Lay out the repo so every later phase has an obvious home for its code. The layout follows design-doc §14 verbatim — services in `services/`, shared Go libs in `pkg/`, shared TS packages in `packages/`, clients in `mobile/`, `web/`, `admin-web/`, infra in `terraform/` and `k8s-manifests/`.

## Inputs / Prerequisites

- Empty repo with `docs/` already populated (the design doc and ADRs already exist)
- ADR-001 (monorepo tooling) reviewed

## Tasks

1. [ ] Create top-level directories: `services/`, `mobile/`, `web/`, `admin-web/`, `pkg/`, `packages/`, `terraform/`, `k8s-manifests/`, `api-gateway/`, `.github/workflows/` — effort: S
2. [ ] Create per-service skeleton directories under `services/`: `user-service`, `product-service`, `pricing-service`, `cart-service`, `order-service`, `inventory-service`, `payment-service`, `notification-service`. Each gets `api/`, `cmd/`, `internal/`, `migrations/`, `Dockerfile` placeholders — effort: M
3. [ ] Add root `.editorconfig`, `.gitattributes`, expanded `.gitignore` (node_modules, .terraform, .next, dist, build, .env, *.tfstate) — effort: S
4. [ ] Add root `README.md` describing the monorepo at a high level and pointing to `docs/` and `plan/` — effort: S
5. [ ] Add pnpm workspace config (`pnpm-workspace.yaml`) declaring `packages/*`, `mobile`, `web`, `admin-web` — effort: S
6. [ ] Add Go workspace (`go.work`) listing every `services/*` and `pkg/*` module — effort: S

## Deliverables

- Top-level directory tree matching design-doc §14 exactly
- `pnpm-workspace.yaml` at root
- `go.work` at root
- Updated `.gitignore` and root `README.md`

## Exit Criteria

- [ ] `find . -maxdepth 2 -type d | sort` shows every directory listed in design-doc §14
- [ ] `pnpm install` at root succeeds (even with empty packages)
- [ ] `go work sync` succeeds

## References

- Design doc: §14 Directory Structure
- ADR-001 Monorepo tooling

## Risks & Open Questions

- pnpm vs npm workspaces: design doc implies pnpm via `packages/`. Lock the choice in ADR-001 if not already.
