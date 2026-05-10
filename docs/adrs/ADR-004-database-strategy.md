# ADR-004: Database Strategy, PostgreSQL (Database-per-Service)

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
Microservices require data isolation to ensure loose coupling and independent deployability. We must decide on (a) the database engine, (b) isolation model, and (c) whether to use specialized stores for event sourcing and search.

## Options Considered

### Database Engine

| Option | Pros | Cons |
|---|---|---|
| **PostgreSQL** | Battle-tested, ACID, full-text search (tsvector), JSON support, excellent tooling | Single-region by default, manual replication setup |
| **CockroachDB** | Distributed SQL, multi-region active-active | Operational complexity, overkill for this scale, different SQL dialect edge cases |
| **MySQL** | Widely used, good performance | Weaker full-text search, less feature-rich than PG |

### Isolation Model

| Option | Pros | Cons |
|---|---|---|
| **One cluster, separate databases** | True isolation at DB level, one cluster to manage, services can't cross-query | Shared resource pool (CPU/memory) |
| **Separate clusters per service** | Complete physical isolation | 7 PostgreSQL instances to operate, excessive for this scale |
| **Shared database, separate schemas** | Easiest to manage | Risk of cross-schema queries, weaker isolation |

### Specialized Stores

| Option | Pros | Cons |
|---|---|---|
| **EventStoreDB for event sourcing** | Purpose-built, projections built-in | Extra infra, separate operational burden, team must learn new tool |
| **PostgreSQL append-only events table** | No new infra, same ACID guarantees, familiar tooling | Must build projection logic ourselves |
| **Elasticsearch for search** | Purpose-built full-text search, aggregations | Extra cluster, data sync complexity (CDC/dual-write) |
| **PostgreSQL tsvector** | Built-in, no sync needed, GIN indexes are fast | Less powerful than ES for complex aggregations |

## Decision
1. **PostgreSQL** as the sole database engine
2. **One cluster, database-per-service isolation**, each service gets its own database (`user_db`, `order_db`, etc.) within a single PG cluster
3. **Event sourcing via PG `events` table**, append-only table with `event_type`, `aggregate_id`, `payload`, `created_at`
4. **Full-text search via `tsvector`**, GIN-indexed search column on the products table

## Consequences
- Single database engine to operate, monitor, and back up
- Database-level isolation prevents accidental cross-service queries
- Event sourcing tables are simple to understand and debug with standard SQL
- Full-text search is "good enough" for this scale, migration to Elasticsearch is possible later if needed
- Trade-off: we lose CockroachDB's automatic multi-region replication, but this is not needed at our target scale
