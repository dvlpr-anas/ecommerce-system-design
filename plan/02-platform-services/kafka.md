# Kafka Event Backbone

## Purpose

The durable, ordered, replayable log every domain event flows through. Choreography-based Saga depends on it. Per design-doc §5.1, the topology has four primary topics plus per-topic DLQs.

## Inputs / Prerequisites

- `terraform-skeleton.md`: `modules/kafka/` exists; cluster provisioned (MSK or Confluent Cloud)
- Decision on schema enforcement: JSON Schema at producer/consumer boundary (per ADR-005), not Confluent Schema Registry

## Tasks

1. [ ] Provision Kafka cluster (MSK Serverless or Confluent Cloud Standard) via Terraform — effort: M
2. [ ] Disable topic auto-creation cluster-wide — effort: S
3. [ ] Create primary topics (12 partitions each per design-doc §12.2):
   - `order.events` (retention 14d)
   - `inventory.events` (retention 30d — needed for event sourcing replay)
   - `payment.events` (retention 30d)
   - `notification.commands` (retention 3d)
   — effort: M
4. [ ] Create per-topic DLQs with same partition count, retention 30d — effort: S
5. [ ] Configure topic ACLs: each producer service can only write its own topic; consumers can only read the topics they subscribe to — effort: M
6. [ ] Enable broker-side metrics export (JMX → Prometheus) — effort: M
7. [ ] Document partitioning keys: order events by `order_id`, inventory events by `sku`, payment events by `payment_id`, notification commands by `user_id` — effort: S
8. [ ] CI script `task kafka:topics:apply` reconciles topics against `infra/kafka/topics.yaml` — effort: M

## Deliverables

- Terraform-managed Kafka cluster per env
- `infra/kafka/topics.yaml` declarative topic spec
- `task kafka:topics:apply` reconciler
- Sealed secret with `KAFKA_BOOTSTRAP_SERVERS` and SASL credentials
- Topic ACLs as Terraform resources

## Exit Criteria

- [ ] `kafka-topics --list` shows the 4 primary topics + 4 DLQs
- [ ] Test producer (Go) writes a sample `order.created` event; test consumer reads it back
- [ ] A producer with `user-service` credentials cannot write to `payment.events` (ACL deny)
- [ ] Broker JMX metrics show up in Prometheus

## References

- Design doc: §5 Event Backbone, §6 Distributed Transactions & Saga Flow, §12.2 Bottleneck Analysis (Kafka row)
- ADR-005 Event backbone

## Risks & Open Questions

- 12 partitions per topic per design doc; revisit if Order Service hot-key contention emerges.
- JSON Schema enforcement via `pkg/events/` validators is the boundary control. If services bypass `pkg/events/`, schema invariants break — enforce via golangci-lint custom rule.
