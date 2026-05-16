# Resilience Patterns

## Purpose

Apply the resilience patterns from design-doc §7 across every Saga participant. Circuit breakers on outbound calls. Retry with exponential backoff + jitter. Context timeouts. Idempotent consumers. Backpressure via manual offset commits. This sub-file is the integration checklist. The building blocks live in `pkg/circuitbreaker`, `pkg/idempotency`, and Kafka client config.

## Inputs / Prerequisites

- `pkg/circuitbreaker` and `pkg/idempotency` complete ([`../02-platform-services/shared-go-libs.md`](../02-platform-services/shared-go-libs.md))
- Per-service Kafka consumer + HTTP client wired through `pkg/*` helpers

## Tasks

1. [ ] Every outbound HTTP call (service → service, service → Stripe) wrapped in `pkg/circuitbreaker` with config 5/30s/3 per design-doc §7.1 (effort: M)
2. [ ] Retry policy on transient errors: exponential backoff `base=100ms`, `max_delay=30s`, `max_retries=5`, jitter (full-jitter algorithm) (effort: M)
3. [ ] Context timeouts on every call:
   - Internal REST: 3s
   - External API (Stripe): 10s
   - DB queries: 5s
   Implement via `context.WithTimeout` wrapper in `pkg/httputil` and `pkg/db` (effort: S)
4. [ ] Kafka consumer config:
   - `enable.auto.commit=false` (manual commits after successful processing)
   - `max.poll.interval.ms` tuned to typical processing time + 50%
   - per-event idempotency via `processed_events` table
 (effort: M)
5. [ ] Backpressure: HPA on Kafka consumer pods triggered by `kafka_consumer_lag > 10k for 5m` (effort: M)
6. [ ] Per-downstream HTTP pool (`MaxConnsPerHost`) bounded so one slow downstream cannot exhaust the whole pool (effort: S)
7. [ ] Smoke test: introduce 50% packet loss to Stripe (via toxiproxy in dev). Circuit breaker opens after the threshold. Retries succeed once loss removed (effort: M)
8. [ ] Document the patterns in `services/<svc>/README.md` so on-call engineers know what to expect under failure (effort: S)

## Deliverables

- All outbound calls wrapped. Verified via `circuit_breaker_state` metric having entries
- Toxiproxy-based resilience test in `tests/resilience/`
- Per-service documentation of resilience config

## Exit Criteria

- [ ] `circuit_breaker_state` metric shows transitions during the toxiproxy test
- [ ] No-op load test (10k requests with happy backend) shows zero retries
- [ ] Inducing 100% downstream failure causes circuit to open within 5 calls and fail-fast thereafter
- [ ] Replaying the same Kafka event twice does not produce two side-effects (idempotency)

## References

- Design doc: §7.1, §7.2, §7.3, §7.4, §7.5

## Risks & Open Questions

- Retries amplify load during partial outages. Combine with circuit breaker (above) and cap concurrent retries via a semaphore in `pkg/circuitbreaker`.
- Manual offset commits + at-least-once semantics + idempotent consumers = effectively-once. Document this in the on-boarding for the team.
