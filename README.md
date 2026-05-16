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
- `infra/dev/` local docker-compose stack assets
- `infra/docker/` Dockerfile templates
- `terraform/` cloud IaC (phase 07)
- `k8s-manifests/` Kustomize base + overlays (phase 07)
- `docs/` design doc + ADRs
- `plan/` phased implementation plan

## Quickstart

Everything runs inside containers. The host only needs Docker.

Run `./dev` once to drop into a shell inside the toolbox. After that, every command is unprefixed.

```bash
./dev                       # opens a shell in the toolbox (one time per terminal)

# Inside the toolbox, no prefix needed:
task up                     # boot Postgres, Redis, Kafka, Keycloak, Kong
task dev:user-service       # run a service
task test:all               # run every test suite
task docker:build:all       # build every image
task down                   # tear the stack down
task --list                 # list every recipe
go test ./...               # raw toolchain commands also work
pnpm install
exit                        # back to the host shell
```

For one-off commands without opening a shell, `./dev <cmd>` works too (`./dev task up`).

The `./dev` script builds a `sol-arch-tools` image the first time it runs (Go, Node, pnpm, task, goose, golangci-lint, govulncheck, psql, docker CLI baked in), mounts the repo at `/workspace`, forwards the Docker socket so `task up` and `task docker:build:all` drive the host daemon, and joins the dev-stack network so services resolve as `postgres`, `kafka`, `keycloak`, `kong`. Module and pnpm caches persist in named Docker volumes between runs.

## Prerequisites

- Docker Desktop or Colima with at least 12 GB allocated. That's the only host requirement.

Long-running tasks like `./dev task dev:mobile` should be run in a separate terminal so other recipes can run in parallel.

## Documentation

- [`docs/ecommerce-microservices-design.md`](docs/ecommerce-microservices-design.md) the canonical design
- [`docs/adrs/`](docs/adrs/) Architecture Decision Records
- [`plan/`](plan/) phased implementation plan with effort sizing
- [`.agent/rules/rules.md`](.agent/rules/rules.md) project-wide engineering rules
