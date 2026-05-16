# Shared Service Tooling

## Purpose

Codify the patterns every browse-path service applies on top of `pkg/*`: contract test harness, OpenAPI spec lint baseline, migration runner conventions, manifest scaffold generator. Reduces friction when adding service number five (and beyond) in phase 04.

## Inputs / Prerequisites

- `../02-platform-services/shared-go-libs.md` complete
- `../02-platform-services/api-contracts.md` complete

## Tasks

1. [ ] Contract test harness: a small Go library `services/internal/contracttest/` that boots the service in-process, runs OpenAPI examples through it, asserts schemas (effort: L)
2. [ ] Migration runner convention: `task db:migrate` per service uses `goose` with versioned SQL under `migrations/`. One migration per logical change. Down migrations mandatory (effort: M)
3. [ ] Spectral ruleset extension `api-gateway/.spectral.yaml` covering service-specific rules (e.g., every list endpoint must accept cursor + limit) (effort: S)
4. [ ] Manifest scaffold generator: `task scaffold:service NAME=foo-service` copies a template (Dockerfile, Kustomize manifests, OpenAPI stub, main.go, Taskfile) (effort: L)
5. [ ] Per-service `README.md` template with sections: Purpose, Endpoints, Events, DB, Runbook link (effort: S)
6. [ ] Integration test pattern using `task up`: docker-compose-backed black-box tests in `services/<svc>/test/integration/` run by `task test:integration` (effort: M)

## Deliverables

- `services/internal/contracttest/` package
- `task scaffold:service` working end-to-end
- Spectral ruleset extended
- Integration test pattern documented

## Exit Criteria

- [ ] Running `task scaffold:service NAME=stub` produces a buildable, deployable service in one command
- [ ] Contract tests run for each of the four browse-path services in CI
- [ ] Spectral CI rejects a list endpoint missing cursor pagination

## References

- Design doc: §8 API Design Strategy
- ADR-001 Monorepo tooling

## Risks & Open Questions

- Scaffold generator drifts from reality fast. Add a CI check that scaffolds a temp service and `task build`s it. Keeps the template honest.
