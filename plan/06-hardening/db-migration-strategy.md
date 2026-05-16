# DB Migration Strategy

## Purpose

Codify the expand-and-contract migration pattern from design-doc §11.3 across every service so breaking schema changes never cause downtime. Also documents the migration runner (goose) and how it executes on deploy.

## Inputs / Prerequisites

- `pkg/db` provides the goose-based migration runner ([`../02-platform-services/shared-go-libs.md`](../02-platform-services/shared-go-libs.md))
- Per-service `migrations/` directories exist

## Tasks

1. [ ] Document the expand-and-contract policy in this file + `services/<svc>/migrations/README.md`:
   - **Expand** release: add nullable column / new table → deploy code that writes to both old and new → backfill in a job
   - **Contract** release (separate deploy, after all consumers updated): drop old column / old table
   Document explicitly that **no single release does both**
 (effort: S)
2. [ ] Migration runner: K8s Job per service runs `task db:migrate` before the Deployment rolls. Init-container pattern OR pre-deploy Job (effort: M)
3. [ ] Migration safety rules (enforced via CI lint):
   - No `DROP COLUMN` in same migration as `ADD COLUMN`
   - No `ALTER TABLE ... ADD COLUMN ... NOT NULL` without default (locks table)
   - No `CREATE INDEX` without `CONCURRENTLY` on large tables
 (effort: M)
4. [ ] Down-migration required for every migration. Verify down works locally before merging (effort: S)
5. [ ] Backfill jobs as separate K8s Jobs (not embedded in migrations) so they can be paused/resumed (effort: M)
6. [ ] Rollback recipe in [`runbooks.md`](./runbooks.md): `kubectl rollout undo deployment/<svc>` reverts code. Migration down only if explicitly safe (most are not) (effort: M)
7. [ ] Database migration drill quarterly: simulate a rollback during deploy to verify the recipe works (effort: M)

## Deliverables

- Per-service migration runbook + READMEs
- CI lint rules for migration safety
- K8s Job templates for migrate + backfill
- Rollback recipe in service runbooks

## Exit Criteria

- [ ] CI rejects a migration with `DROP COLUMN` + `ADD COLUMN` in the same file
- [ ] CI rejects `CREATE INDEX` without `CONCURRENTLY` on tables flagged "large" in a manifest
- [ ] A migration drill (expand → backfill → contract over three releases) completes without downtime in staging
- [ ] Rollback recipe successfully reverts a deploy in a drill

## References

- Design doc: §11.3 Database Migration Strategy, §11.4 Rollback Plan

## Risks & Open Questions

- Long-running backfills can block follow-on releases. Track each backfill as a planned task with explicit completion gate before the contract release ships.
- API changes follow the same pattern (see [`../02-platform-services/api-contracts.md`](../02-platform-services/api-contracts.md)). Keep both in sync to avoid breaking older mobile clients.
