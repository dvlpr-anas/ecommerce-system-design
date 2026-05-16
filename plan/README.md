# Implementation Plan

Implementation roadmap for the e-commerce microservices platform designed in [`../docs/ecommerce-microservices-design.md`](../docs/ecommerce-microservices-design.md) and the ADRs in [`../docs/adrs/`](../docs/adrs/).

This folder turns the architecture-on-paper into an executable plan. It does **not** duplicate the design doc — each sub-file links back to the relevant design-doc section and ADR.

## How to read this folder

Phases are numbered. Each phase is a folder with its own `README.md` (phase summary, scope, exit criteria, sub-file index) and one sub-`.md` per discrete concern.

Work top-to-bottom: a phase's exit criteria must be met before the next phase starts.

## Status legend

Tracked inline in checklists across sub-files:

- `[ ]` todo
- `[~]` in progress
- `[x]` done
- `[!]` blocked

## Phases

| # | Phase | Folder |
|---|---|---|
| 00 | Overview, principles, glossary | [`00-overview/`](./00-overview/) |
| 01 | Repo, infra, CI/CD, K8s baseline | [`01-foundation/`](./01-foundation/) |
| 02 | Auth, gateway, data, events, observability | [`02-platform-services/`](./02-platform-services/) |
| 03 | Browse path: User, Product, Pricing, Cart | [`03-core-domain-services/`](./03-core-domain-services/) |
| 04 | Checkout path: Order, Inventory, Payment, Notification + Saga | [`04-order-flow/`](./04-order-flow/) |
| 05 | Mobile, Customer Web, Admin Web | [`05-frontends/`](./05-frontends/) |
| 06 | Security, SLOs, load/chaos, DR, runbooks | [`06-hardening/`](./06-hardening/) |
| 07 | Go-live checklist, rollout, rollback | [`07-launch/`](./07-launch/) |

## Milestones

- **M1 — Platform skeleton runs**: phases 01 + 02
- **M2 — Full checkout works end-to-end**: phases 03 + 04
- **M3 — Customer & admin clients ship**: phase 05
- **M4 — Production-ready**: phases 06 + 07

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
