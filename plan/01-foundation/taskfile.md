# Taskfile

## Purpose

Single entry point for every dev workflow. Mirrors design-doc §13 command list so every engineer (and CI job) runs the same recipes. Go-task chosen per ADR-001 for being language-agnostic across Go, RN, Next.js, Vite.

## Inputs / Prerequisites

- `monorepo-structure.md` complete
- `go-task` installed locally (`brew install go-task/tap/go-task` on macOS)

## Tasks

1. [ ] Create root `Taskfile.yml` with includes for per-service Taskfiles (effort: S)
2. [ ] Add `dev:*` namespace: `dev:mobile`, `dev:mobile:ios`, `dev:mobile:android`, `dev:web`, `dev:admin-web`, `dev:user-service` (and one per service) (effort: M)
3. [ ] Add `build:*` namespace: `build:all`, `build:mobile:ios`, `build:mobile:android`, `build:web`, `build:admin-web`, `build:<service>` (effort: M)
4. [ ] Add `test:all` and `test:integration` aggregating per-service `task test` (effort: S)
5. [ ] Add `codegen:openapi` running the OpenAPI → TS client + Go server stub generator across every service spec (effort: M)
6. [ ] Add `docker:build:all` building every service image plus the Next.js image (effort: S)
7. [ ] Add `db:migrate:all` running goose migrations for every service against the local docker-compose Postgres (effort: M)
8. [ ] Add `lint:all` running `golangci-lint` on Go and `eslint` + `tsc --noEmit` on TS (effort: S)
9. [ ] Add `up` and `down` shortcuts wrapping `docker compose -f docker-compose.dev.yml up/down` (see [`local-dev.md`](./local-dev.md)) (effort: S)

## Deliverables

- Root `Taskfile.yml`
- One `Taskfile.yml` per service under `services/<svc>/`
- One under `mobile/`, `web/`, `admin-web/`

## Exit Criteria

- [ ] `task --list` prints every command listed in design-doc §13
- [ ] `task lint:all` runs without errors on an empty repo (no-op pass)
- [ ] CI workflows from [`cicd-baseline.md`](./cicd-baseline.md) invoke `task` commands rather than raw scripts

## References

- Design doc: §13 Monorepo Management
- ADR-001 Monorepo tooling

## Risks & Open Questions

- Long-running tasks (Expo dev server) should not block other tasks. Document `task dev:mobile &` usage in root README.
