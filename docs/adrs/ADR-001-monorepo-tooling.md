# ADR-001: Monorepo Tooling, Taskfile (go-task)

**Status:** Accepted  
**Date:** 2026-05-10  
**Decision Makers:** Solution Architect

## Context
The project contains Go microservices, a React Native (Expo) mobile app targeting iOS and Android, a Next.js customer web storefront, a React + Vite admin web app, Terraform configs, and K8s manifests. We need a task runner that works across all languages and frontends and provides a consistent developer experience.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Taskfile (go-task)** | Language-agnostic, YAML syntax, dependency graphs, cross-platform | Less ecosystem than Make |
| **Make** | Universal, zero dependencies | Verbose, tab-sensitive syntax, poor Windows support |
| **Turborepo** | Excellent caching, parallel execution | JavaScript/TypeScript-centric, awkward for Go |
| **Nx** | Polyglot support, dependency graph | Heavy config overhead, steep learning curve |
| **Bazel** | Hermetic builds, massive scale | Extreme complexity, Google-scale solution for a <10 service repo |

## Decision
**Taskfile (go-task)**, it is language-agnostic by design, uses clean YAML syntax, supports task dependencies and parallel execution, and has near-zero setup cost. It handles Go, React Native (Expo / EAS Build), Next.js, Vite, Terraform, and any future language equally well.

## Consequences
- All developers run `task <command>` regardless of the underlying language
- Task definitions are version-controlled in `Taskfile.yml`
- No lock-in: tasks are just shell commands, migration to another runner is trivial
