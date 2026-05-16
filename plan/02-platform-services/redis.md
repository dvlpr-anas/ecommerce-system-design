# Redis Cluster

## Purpose

Volatile state store for cart sessions, rate-limit counters, and short-lived caches. Cart Service uses it as its primary store (no Postgres) per design-doc §4.2. Sized for memory, not throughput.

## Inputs / Prerequisites

- `kubernetes-baseline.md` complete (cluster + `data` namespace)
- Decision on managed vs self-hosted: default **managed** (ElastiCache / Memorystore) to avoid HA ops in scope

## Tasks

1. [ ] Provision managed Redis 7 cluster via Terraform (ElastiCache replication group or Memorystore Standard) (effort: M)
2. [ ] Configure eviction policy: `allkeys-lru` (carts are abandoned, rate-limit counters expire) (effort: S)
3. [ ] Configure max-memory and memory alerts at 80% (Prometheus alert) (effort: S)
4. [ ] Set TLS in transit + auth token. Store token via Sealed Secrets (effort: S)
5. [ ] Document keyspace conventions: `cart:{user_id}` TTL 7d, `cart:anon:{cart_id}` TTL 24h, `ratelimit:{consumer}:{bucket}` TTL bucket-window (effort: S)
6. [ ] Decide on Cluster mode (sharded) vs Standalone: start **Standalone with replicas** for simpler ops. Revisit if hot-key issues (effort: S)
7. [ ] Expose a smoke endpoint in cart-service health check that PINGs Redis (effort: S)

## Deliverables

- Terraform-managed Redis instance per env
- Sealed secret with `REDIS_URL` and auth token
- Prometheus rule for memory usage > 80%
- Keyspace convention documented in `docs/` and referenced from cart-service

## Exit Criteria

- [ ] `redis-cli -u $REDIS_URL --tls PING` returns PONG
- [ ] Failover test (managed Redis): primary fails, replica promotes, client reconnects within 30s
- [ ] Memory alert fires when cluster filled past 80% (test with throwaway data)

## References

- Design doc: §2 Technology Stack (Redis row), §4.2 Database-per-Service Strategy (Cart Service)

## Risks & Open Questions

- Cart loss on full cache eviction is acceptable per design (cart is volatile by definition). Confirm with Product that 7-day TTL for authenticated carts is acceptable.
- If multi-region active-active is ever needed, Redis is a hard problem. Out of scope for initial launch.
