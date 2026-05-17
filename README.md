# sol_arch_proj

Production-grade, event-driven e-commerce platform. Eight Go microservices behind Kong, three clients (React Native mobile, Next.js web, React + Vite admin), Kafka event backbone, Postgres database-per-service, Redis for cart, deployed to Kubernetes.

## Layout

See [`docs/ecommerce-microservices-design.md`](docs/ecommerce-microservices-design.md) §14 for the full directory map. High-level:

- `services/` Go microservices (one folder per service)
- `pkg/` shared Go libraries
- `packages/` shared TypeScript packages (pnpm workspace)
- `mobile/` React Native + Expo app
- `web/` Next.js storefront
- `admin-web/` React + Vite admin SPA
- `api-gateway/` Kong declarative config
- `infra/dev/` shared dev env (`.env.dev`), Postgres/Kafka/Keycloak seed data
- `infra/k3d/` k3d cluster config + raw k8s manifests (`manifests/`) for the inner-loop infra (postgres, redis, kafka, keycloak). Same upstream images as the compose stack.
- `infra/docker/` Dockerfile templates (prod) and dev image (`Dockerfile.go-service.dev`)
- `terraform/` cloud IaC (phase 07)
- `k8s-manifests/` Kustomize base + overlays (`overlays/dev` for the inner loop)
- `docs/` design doc + ADRs
- `plan/` phased implementation plan

## Quickstart

The host only needs **Docker**. Everything else runs in a devcontainer.

### Path A — VS Code / JetBrains / Codespaces (recommended)

1. Open the repo in VS Code with the *Dev Containers* extension installed.
2. *Reopen in Container*. First boot installs the pinned toolchain via `mise` (Go, Node, pnpm, task, tilt, kubectl, k3d, helm, goose, golangci-lint, air, ...).
3. Inside the devcontainer terminal:

   ```bash
   make dev
   ```

   This creates a local k3s cluster (k3d), deploys Postgres / Redis / Kafka / Keycloak via Helm, runs migrations, builds and deploys all eight services with hot live-update, and starts the two web frontends.

4. Open the Tilt UI: <http://localhost:10350>. Every service, every log, every dependency, one screen.

### Path B — `devcontainer` CLI (any editor)

```bash
docker run -it --rm \
  -v "$PWD":/workspace -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/devcontainers/cli devcontainer up --workspace-folder /workspace
docker exec -it $(docker ps -lq) bash
make dev
```

### Path C — GitHub Codespaces

Click *Code → Codespaces → Create*. The devcontainer spec boots the same env in the cloud; `make dev` and the Tilt UI port-forward work identically.

## Day-to-day endpoints

After `make dev` everything is reachable on `localhost`:

| Component   | URL                                              |
|-------------|--------------------------------------------------|
| Tilt UI     | <http://localhost:10350>                         |
| Kong proxy  | <http://localhost:8000>                          |
| Keycloak    | <http://localhost:8080> &nbsp; admin/admin       |
| Grafana     | <http://localhost:3001> &nbsp; admin/admin       |
| Prometheus  | <http://localhost:9090>                          |
| Postgres    | `postgres://postgres:postgres@localhost:5432`    |
| Redis       | `redis://localhost:6379`                         |
| Kafka       | `localhost:29092`                                |
| Service `N` | `http://localhost:808N/healthz` (8081..8088)     |

## Other entry points

| Goal                                    | Command                          |
|-----------------------------------------|----------------------------------|
| Run a single Go service standalone      | `cd services/<svc> && air -c ../../infra/dev/air.toml` |
| Run a verb (test/lint/build/migrate)    | `task --list`                    |
| Bring up infra only (no k8s, fastest)   | `task up`                        |
| Stop the cluster, keep state            | `make stop`                      |
| Wipe the cluster entirely               | `make nuke`                      |
| Run mobile (Expo) — host only           | `task mobile:dev` on the host    |

Mobile dev (`task mobile:dev:ios|android`) needs Xcode / Android Studio on the host and is intentionally not wired into the devcontainer or Tilt.

## Prerequisites

- Docker Desktop, OrbStack, or Colima with at least **12 GB** allocated.
- VS Code + *Dev Containers* extension (Path A) **or** the `devcontainer` CLI (Path B) **or** a GitHub Codespaces seat (Path C).

That's it. No host installs of Go, Node, kubectl, Helm, Tilt, or anything else.

## First-boot timing & order

First `make dev` is slow: k3d pulls k3s, Helm pulls four Bitnami charts, Docker builds 8 service images. Plan for ~5–10 minutes on a warm Docker cache. Subsequent boots reuse everything and the Tilt UI is up in seconds.

Tilt brings things up in this order so dependencies are satisfied before consumers start:

```
env / postgres-init / keycloak-realm ConfigMaps
       │
       ▼
postgres ── redis ── kafka ── keycloak    (raw k8s manifests, upstream images)
       │
       ▼
migrations (goose against port-forwarded postgres)
       │
       ▼
8 Go services + 2 frontends     (live-update on every save)
```

The infra layer uses the same `postgres:16-alpine`, `redis:7-alpine`, `confluentinc/cp-kafka:7.6.1`, `quay.io/keycloak/keycloak:24.0` images as the compose stack. Phase 07 promotes these to **CloudNativePG** (postgres), **Strimzi** (kafka), and the **Keycloak Operator** for production parity.

## Notes & known caveats

- **Postgres init scripts only run on a fresh PVC.** If you add a new role/DB to `infra/dev/postgres-init.sql`, run `make nuke` (deletes cluster + PVs) and re-run `make dev`. Same behavior as the compose stack on a fresh volume.
- **`go.work` references `pkg/*` modules that are still empty.** Service builds will fail until each `pkg/<x>/` has at least a `go.mod`. Land that with the shared-pkg work.
- **Mobile (`mobile/`) is host-only.** Expo needs Xcode / Android Studio on the host; it is intentionally not wired into the devcontainer or Tilt. Run `task mobile:dev` from a host shell with `mise` installed if you want to keep tool versions pinned.
- **Image versions are pinned in `infra/k3d/manifests/*.yaml`.** To bump, edit the manifest and let Tilt reapply.
- **Compose stack (`task up`) is the fast-path alternative** when you only need infra (no k8s, no services in-cluster). Useful for running a single service with `air` against the host port-forwards. Migrations from the Taskfile target the same `localhost`-mapped Postgres.

## Documentation

- [`docs/ecommerce-microservices-design.md`](docs/ecommerce-microservices-design.md) — the canonical design
- [`docs/adrs/`](docs/adrs/) — Architecture Decision Records
- [`plan/`](plan/) — phased implementation plan with effort sizing
- [`.agent/rules/rules.md`](.agent/rules/rules.md) — project-wide engineering rules
