# Product Service

## Purpose

Catalog and search. Owns `product_db` with a CQRS read model: canonical product/category tables for writes, a `tsvector`-backed search projection for reads. Publishes catalog-change events for Next.js ISR revalidation. Read-heavy; uses the Postgres read replica.

## Inputs / Prerequisites

- Phase 02 complete
- Read replica configured per [`../02-platform-services/postgres.md`](../02-platform-services/postgres.md)
- S3/GCS bucket for product images (provisioned in Terraform)

## Tasks

1. [ ] Author `services/product-service/api/openapi.yaml`:
   - `GET /products` (cursor pagination, filter, sort)
   - `GET /products/{id}`
   - `GET /products/search?q=...`
   - `GET /categories`, `GET /categories/{slug}/products`
   - Admin-scoped: `POST /products`, `PATCH /products/{id}`, `DELETE /products/{id}`
   — effort: M
2. [ ] DB migrations:
   - `products` (id, sku UNIQUE, title, description, brand, attrs JSONB, image_urls[], status, created_at, updated_at)
   - `categories` (id, slug UNIQUE, name, parent_id)
   - `product_categories` (m:n)
   - `product_search` materialized view OR `tsvector` GENERATED column on `products(title, description, brand)`
   - `outbox` table per [`../04-order-flow/transactional-outbox.md`](../04-order-flow/transactional-outbox.md)
   — effort: L
3. [ ] Implement read handlers against the read replica; writes against the primary — effort: M
4. [ ] Implement search handler using `to_tsquery` with `plainto_tsquery` fallback; cursor pagination over `(rank DESC, id ASC)` — effort: M
5. [ ] Bulk import CLI `cmd/import/` reading CSV/JSONL from S3 in batches, with progress logging and resume — effort: L
6. [ ] On every write, append an event to `outbox` (`product.created`, `product.updated`, `product.deleted`). `pkg/outbox` poller publishes to `notification.commands` (or a dedicated `catalog.events` topic if scope grows) — effort: M
7. [ ] ISR webhook target: a small consumer of catalog events that calls `POST https://www.example.com/api/revalidate?path=/p/<slug>` (token-protected) — built in [`../05-frontends/customer-web.md`](../05-frontends/customer-web.md); produce the events here — effort: M
8. [ ] Redis caching for hot product pages: `product:{id}` 10-min TTL, invalidated on update — effort: M
9. [ ] Kustomize manifests, HPA, ServiceMonitor, NetworkPolicy — effort: M

## Deliverables

- Service deployed; reads served from replica
- Bulk import CLI demoable with a 10k-row sample
- Catalog-change events publishing
- Redis caching with measurable hit rate

## Exit Criteria

- [ ] `GET /api/v1/products/search?q=shoes` returns ranked results in < 100ms p95 on a 100k-product catalog (verified during phase 06 load test, smoke-test here)
- [ ] Admin creates a product; ISR webhook fires; storefront page reflects within seconds
- [ ] Cache hit ratio > 50% under read load
- [ ] All standard metrics emit

## References

- Design doc: §4.1 Service Catalog (Product Service), §4.2 (CQRS), §12.2 Bottleneck Analysis (Search load row)

## Risks & Open Questions

- `tsvector` is fine to ~1M products; beyond that, Meilisearch / OpenSearch becomes attractive. Track as a future ADR.
- Image upload: who does it? Default — admin web uploads directly to S3 via presigned URL issued by Product Service.
