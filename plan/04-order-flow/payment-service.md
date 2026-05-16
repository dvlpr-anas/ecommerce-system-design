# Payment Service

## Purpose

Charge customers via an external gateway (Stripe initially). Saga participant: charges on `inventory.reserved`, emits `payment.completed` or `payment.failed`. Uses idempotency keys to prevent double-charges. Circuit-breaker wraps the gateway call (design-doc §7.1, §9.4).

## Inputs / Prerequisites

- Phase 02 complete. `pkg/circuitbreaker`, `pkg/idempotency` available
- Stripe account (test mode) with API keys in Sealed Secrets
- PCI scope minimized: card data never touches our servers. Frontend tokenizes via Stripe Elements / Stripe SDK. We only handle PaymentIntent IDs

## Tasks

1. [ ] OpenAPI:
   - `POST /payments/intents` (called by frontend to create PaymentIntent, returns client_secret)
   - `GET /payments/{id}`
   - Admin: `POST /payments/{id}/refund`
 (effort: M)
2. [ ] DB migrations:
   - `payments` (id, order_id FK, gateway, gateway_payment_id, amount, currency, status, idempotency_key UNIQUE, created_at)
   - `refunds` (id, payment_id FK, amount, reason, status, created_at)
   - `outbox`, `processed_events`
 (effort: M)
3. [ ] Provider-agnostic `internal/gateway/` interface (`Charge`, `Refund`, `WebhookVerify`). Stripe adapter implements it (effort: L)
4. [ ] Kafka consumer `inventory.events`:
   - `inventory.reserved` → confirm PaymentIntent (already created by frontend in step 1). Emit `payment.completed` or `payment.failed`
 (effort: L)
5. [ ] Idempotency keys passed to Stripe based on `order_id` so retries are safe (effort: S)
6. [ ] Stripe webhook endpoint `/webhooks/stripe`. Signature-verified. Updates `payments.status` on async events (e.g., chargebacks). Webhook is the source of truth for terminal states (effort: M)
7. [ ] Refund flow: admin endpoint triggers gateway refund, emits `payment.refunded` for Order Service projection (effort: M)
8. [ ] Compensation: on `OrderCancelled` after a successful charge, auto-issue refund (effort: M)
9. [ ] Manifests, HPA, ServiceMonitor, strict NetworkPolicy (egress to Stripe API + Kafka + Postgres only) (effort: M)
10. [ ] Tests using Stripe's test mode + mock-time clock for retries (effort: L)

## Deliverables

- Service deployed
- Stripe adapter validated against test mode
- Webhook endpoint reachable from Stripe (use Stripe CLI in dev)
- Refund path demoable

## Exit Criteria

- [ ] End-to-end test: create intent → confirm → `payment.completed` emitted → Order CONFIRMED
- [ ] Simulated gateway error (Stripe test card `4000 0000 0000 0341`) → `payment.failed` emitted → Inventory releases stock
- [ ] Duplicate `inventory.reserved` does not double-charge (idempotency key)
- [ ] Webhook with bad signature is rejected with 400
- [ ] Refund triggers `payment.refunded` and Stripe-side refund confirmed

## References

- Design doc: §4.1 (Payment row), §7.4 Idempotency, §9.4 Mobile/Web Token Storage and idempotency

## Risks & Open Questions

- PCI scope: stay SAQ-A by never seeing card numbers. Have an external compliance review pre-launch.
- Multi-provider (Stripe + Razorpay) is in scope per design-doc Tech Stack. Razorpay adapter deferred to post-launch unless India market is M1.
