# ADR-005: Event Backbone, Apache Kafka

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
Microservices need asynchronous, reliable communication for domain events, Saga choreography, and decoupling. The event backbone must support durable, ordered, replayable message delivery.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Apache Kafka** | Durable log, ordered partitions, replayable, massive throughput, consumer groups | Operational complexity (ZooKeeper/KRaft), overkill for simple pub/sub |
| **RabbitMQ** | Simple setup, flexible routing (exchanges), low latency | Messages deleted after consumption, no replay, less suited for event sourcing |
| **AWS SQS + SNS** | Fully managed, zero ops | Cloud lock-in, no ordering guarantees (standard), no replay |
| **NATS JetStream** | Lightweight, fast, built-in persistence | Smaller ecosystem, less battle-tested at enterprise scale |
| **Redis Streams** | Already running Redis, lightweight | Not purpose-built, limited consumer group semantics |

## Decision
**Apache Kafka**, domain events are the backbone of our architecture (Sagas, CQRS projections, audit trails). Kafka's durable, ordered, replayable log is essential. Consumer groups enable independent scaling of consumers. Topic partitioning allows parallel processing while maintaining per-partition ordering.

### Why not Schema Registry?
We chose **shared Go structs with JSON schema validation** over Confluent Schema Registry:
- Schema Registry is a separate service to deploy, monitor, and manage
- Our event contracts are all in Go, shared structs in `pkg/events/` provide compile-time type safety
- JSON schema validation at producer/consumer boundaries catches contract violations
- At our scale (<10 services), the overhead of Avro + Schema Registry isn't justified

## Consequences
- Kafka is deployed via Terraform (AWS MSK or self-managed on K8s)
- All async communication flows through Kafka topics
- Event schemas are Go structs, changes require updating the shared `pkg/events/` package
- Trade-off: Kafka is heavier than RabbitMQ, but we need durability and replay for event sourcing
