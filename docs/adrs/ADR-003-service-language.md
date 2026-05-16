# ADR-003: Service Language, Go (Gin)

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
We need a primary language for all microservices. The language must support high concurrency, produce small container images, and have a strong standard library for HTTP and database work.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Go (Gin)** | Goroutines for concurrency, tiny binaries (~10MB), fast startup, strong stdlib, simple deployment | Verbose error handling, no generics until recently |
| **Node.js (Express/Fastify)** | Huge ecosystem, fast development, shared TypeScript with the React Native mobile app | Single-threaded, higher memory per pod, callback complexity |
| **Java (Spring Boot)** | Enterprise mature, massive ecosystem | Heavy JVM, slow cold starts, large container images (~300MB) |
| **Rust (Actix)** | Maximum performance, memory safety | Steep learning curve, slower development velocity |
| **Python (FastAPI)** | Excellent for prototyping, ML integration | GIL limits concurrency, slower runtime performance |

## Decision
**Go with Gin framework**, Go's goroutine model handles thousands of concurrent connections per pod with minimal memory. Container images are ~15MB (distroless). Cold start is <100ms, critical for K8s pod scaling. Gin provides a minimal, performant HTTP framework without the overhead of larger frameworks.

## Consequences
- All 8 microservices are written in Go for operational consistency
- Shared libraries in `pkg/` are reused across services (DRY)
- Hiring consideration: team must be comfortable with Go
- Trade-off accepted: more verbose than Node.js, but better runtime characteristics for this workload
