# Implementation Plan

Implementation roadmap for the e-commerce microservices platform designed in [`../docs/ecommerce-microservices-design.md`](../docs/ecommerce-microservices-design.md) and the ADRs in [`../docs/adrs/`](../docs/adrs/).

This folder turns the architecture-on-paper into an executable plan. It does **not** duplicate the design doc. Each sub-file links back to the relevant design-doc section and ADR.

## How to read this folder

Phases are numbered. Each phase is a folder with its own `README.md` (phase summary, scope, exit criteria, sub-file index) and one sub-`.md` per discrete concern.

Work top-to-bottom: a phase's exit criteria must be met before the next phase starts.

## Status legend

Tracked inline in checklists across sub-files:

- `[ ]` todo
- `[~]` in progress
- `[x]` done
- `[!]` blocked

## Build approach: local-first, deploy last

The plan is ordered so the entire system is built and validated on a developer laptop (Docker Compose plus Taskfile) before any cloud infrastructure is provisioned. Phases 01 through 06 require zero cloud accounts. Cloud infrastructure, deployment automation, and production-only hardening (chaos, DR, SLOs in prod, alerting) are deferred to phases 07 through 09.

## Phases

| # | Phase | Folder | Environment |
|---|---|---|---|
| 00 | Overview, principles, glossary | [`00-overview/`](./00-overview/) | n/a |
| 01 | Monorepo, Taskfile, docker-compose, container baseline, local CI | [`01-foundation/`](./01-foundation/) | Local |
| 02 | Auth, gateway, data, events, observability (all via docker-compose) | [`02-platform-services/`](./02-platform-services/) | Local |
| 03 | Browse path: User, Product, Pricing, Cart | [`03-core-domain-services/`](./03-core-domain-services/) | Local |
| 04 | Checkout path: Order, Inventory, Payment, Notification plus Saga | [`04-order-flow/`](./04-order-flow/) | Local |
| 05 | Mobile, Customer Web, Admin Web | [`05-frontends/`](./05-frontends/) | Local |
| 06 | Local hardening: threat model, security scanning, load test, runbook drafts, migration policy | [`06-hardening/`](./06-hardening/) | Local |
| 07 | Cloud infra: Terraform, K8s baseline, Sealed Secrets, registry | [`07-cloud-infrastructure/`](./07-cloud-infrastructure/) | Cloud |
| 08 | Cloud deployment plus prod hardening: deploy workflows, manifests, SLOs, alerting, chaos, DR | [`08-cloud-deployment/`](./08-cloud-deployment/) | Cloud |
| 09 | Go-live checklist, rollout, rollback | [`09-launch/`](./09-launch/) | Cloud |

## Milestones

- **M1, Platform skeleton runs locally**: phases 01 plus 02
- **M2, Full checkout works end-to-end locally**: phases 03 plus 04
- **M3, Customer and admin clients ship (local)**: phase 05
- **M4, Local hardening complete**: phase 06
- **M5, Cloud-deployed and production-ready**: phases 07 plus 08
- **M6, Launched**: phase 09

## Per-sub-file template

Every actionable sub-file uses the same shape:

```
## Purpose
## Inputs / Prerequisites
## Tasks         (numbered checklist with effort: S/M/L/XL)
## Deliverables
## Exit Criteria (checkboxes)
## References    (design doc §, ADR-NNN)
## Risks & Open Questions
```

See [`00-overview/effort-legend.md`](./00-overview/effort-legend.md) for sizing.
