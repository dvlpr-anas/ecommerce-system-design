# Effort Legend

Every task in every sub-file ends with an effort tag. These are rough sizes assuming one experienced engineer working uninterrupted.

| Tag | Bound | Examples |
|---|---|---|
| **S** | ≤ ½ day | Add a YAML config file, write a single migration, configure a Grafana panel |
| **M** | ≤ 2 days | Stand up one service skeleton, write a docker-compose file, set up one CI workflow |
| **L** | ≤ 1 week | Implement Order Service end-to-end with outbox poller, build Keycloak realm + clients + tests |
| **XL** | > 1 week | Implement full Saga across four services, build the mobile app shell, full load + chaos test suite |

## How to size

- Default to one size larger if any of: external dependency you haven't used before, no ADR yet exists, requires writing tests *and* docs, or involves more than two services.
- If a task is XL, consider splitting it into smaller tasks within the same sub-file.
- Sizes are estimates, not contracts. Track actuals as you go and revise sub-files when reality diverges.
