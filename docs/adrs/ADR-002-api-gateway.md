# ADR-002: API Gateway, Kong

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
We need an API Gateway that handles JWT validation, rate limiting, SSL termination, and routing to internal services. It must run as a Kubernetes Ingress Controller.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Kong** | K8s-native Ingress, rich plugin ecosystem (JWT, rate-limit, CORS), declarative config, battle-tested | Slightly heavier than Traefik |
| **Traefik** | Lightweight, auto-discovery, Let's Encrypt built-in | Plugin ecosystem smaller, JWT validation requires middleware chains |
| **AWS ALB + Lambda Authorizer** | Fully managed, no infra to run | Cloud vendor lock-in, can't run locally |
| **NGINX Ingress** | Ultra lightweight, well-known | No built-in JWT validation, needs custom Lua scripts |
| **Custom Go reverse proxy** | Full control | Reinventing the wheel, maintenance burden |

## Decision
**Kong**, it provides JWT validation, rate limiting, CORS, and request transformation as first-class plugins. It runs as a K8s Ingress Controller with declarative configuration (CRDs). The plugin model means we add capabilities without custom code.

## Consequences
- Kong is deployed as a K8s Deployment + Service
- All routing, auth, and rate-limiting is configured via Kong CRDs (version-controlled)
- No protocol translation needed, pure REST throughout
- Plugin-based extensibility for future needs (IP whitelisting, request logging, etc.)
