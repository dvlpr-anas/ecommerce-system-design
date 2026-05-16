# Notification Service

## Purpose

Fire-and-forget dispatcher for emails, SMS, and push (APNs + FCM). Pure Kafka consumer — no REST API, no DB. Consumes `notification.commands` and terminal-state events from order/payment topics; sends notifications via SES/SendGrid (email) and Expo push (APNs/FCM).

## Inputs / Prerequisites

- Phase 02 complete; Kafka topics `notification.commands`, `order.events`, `payment.events`
- Email provider (SES recommended for AWS shop) credentials in Sealed Secrets
- Expo push token registration done in mobile app (phase 05) — service is ready in 04 but full flow lights up after 05
- User Service available (to look up email + push tokens by user_id)

## Tasks

1. [ ] Author event contracts in `pkg/events`:
   - `SendEmailCommand{to, template_id, variables}`
   - `SendPushCommand{user_id, title, body, data}`
   — effort: S
2. [ ] Kafka consumers:
   - `notification.commands` → dispatch by command type
   - `payment.events` `PaymentCompleted` → send order-confirmation email
   - `payment.events` `PaymentFailed` → send payment-failure email
   - `order.events` `OrderShipped` (future) → send shipping email + push
   — effort: L
3. [ ] Email templating: Go `html/template` with templates in `services/notification-service/templates/`; fallback plain-text part — effort: M
4. [ ] Push: Expo Push API client (single endpoint for APNs+FCM via Expo) — effort: M
5. [ ] User-preference check: User Service `GET /users/{id}/notification-preferences` (defaults: email on, push on) — effort: M
6. [ ] Idempotent dispatch: `processed_events` keyed on event_id; also dedupe outgoing emails by (event_id, channel) — effort: M
7. [ ] Retry + DLQ: exponential backoff on transient provider errors; route to DLQ after 5 retries — effort: M
8. [ ] Manifests, HPA on consumer lag, ServiceMonitor — effort: M
9. [ ] Tests: golden-file tests for rendered email HTML; mocked Expo + SES clients — effort: M

## Deliverables

- Service deployed
- Email templates checked in
- Expo push integration validated in dev (test device)
- Per-user preference honored

## Exit Criteria

- [ ] `PaymentCompleted` → user receives order-confirmation email within 30s (SES test inbox)
- [ ] Expo push to a registered test device arrives within 10s
- [ ] Duplicate event does not produce a duplicate email
- [ ] User with `email_notifications=false` does not receive email
- [ ] DLQ catches a deliberately bad event after retry exhaustion

## References

- Design doc: §4.1 (Notification row), §5.1 Topic Design, §7.2 Retry, §7.6 DLQ
- ADR-008 Mobile platform (Expo push)

## Risks & Open Questions

- SES sandbox limits — request prod access well before launch.
- Templating localization (i18n): defer to post-launch; design template files to accept a `locale` variable so the schema is forward-compatible.
