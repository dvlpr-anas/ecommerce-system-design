# ADR-008: Mobile Platform, React Native (Expo) for iOS + Android

**Status:** Accepted
**Date:** 2026-05-16
**Decision Makers:** Solution Architect
**Relates to:** [ADR-009](./ADR-009-web-frontend.md) (web storefront + admin)

## Context
The platform must reach customers on iOS and Android in addition to the web storefront covered in [ADR-009](./ADR-009-web-frontend.md). Native apps are required because customers expect push notifications, biometric/Keychain-backed sessions, native payment SDKs, and store-discoverable installs that a PWA cannot match. We need a mobile client strategy that:

- Ships one codebase to both Apple App Store and Google Play Store
- Reuses the TypeScript types already generated from our OpenAPI specs
- Supports push notifications, secure on-device token storage, and offline-tolerant UX
- Stays operable by a small team (no parallel iOS + Android teams)
- Allows OTA updates for non-native bug fixes (store review for every typo is unacceptable)

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **React Native (Expo)** | Single TypeScript codebase, large ecosystem, Expo managed workflow handles signing/builds/OTA via EAS, native modules available when needed, hot reload, shares types with backend OpenAPI clients | Bridge overhead for animation-heavy UI, some native APIs need config plugins, two store submissions still required |
| **React Native (bare CLI, no Expo)** | Full native control from day one | Manual signing, build infra, OTA setup. Months of yak-shaving for a small team |
| **Flutter** | Excellent performance, consistent rendering, single codebase | Dart language (no TS sharing with backend OpenAPI clients), smaller ecosystem for our domain, would force us to maintain two type systems |
| **Native iOS (Swift) + Native Android (Kotlin)** | Best performance, full platform fidelity, no bridge | Two codebases, two teams (or 2× delivery time for one team), no OTA, duplicated business logic |
| **PWA** | Single web codebase, no store review | Limited push on iOS (improving but inconsistent), no proper Keychain access, store-discoverability story is weak, payment SDKs assume native |
| **Capacitor / Ionic (WebView)** | Reuse existing web stack | WebView UX feels non-native, performance drops on lower-end Android, animation/gesture gaps |

## Decision
**React Native with Expo (managed workflow + EAS Build + EAS Update).**

- **Language:** TypeScript (shared with backend OpenAPI-generated clients in `pkg/`-style codegen).
- **UI:** React Native Paper (Material-Design-aligned, parallels the MUI vocabulary the team already knows).
- **Navigation:** React Navigation (native stack on both platforms).
- **Data layer:** TanStack Query over a generated OpenAPI client (axios under the hood).
- **Auth:** `expo-auth-session` for OIDC Authorization Code + PKCE against Keycloak in an in-app browser.
- **Secure storage:** `expo-secure-store` → iOS Keychain / Android Keystore.
- **Push:** `expo-notifications` over APNs (iOS) and FCM (Android), dispatched by the Notification Service.
- **Build & release:** EAS Build for binaries, EAS Update for OTA JS-only changes.

## Consequences

### Positive
- One team can ship to both stores from one codebase
- OpenAPI types flow end-to-end: backend Go server → generated TS client → mobile screens, with no manual contracts
- EAS Update lets us patch JS-only regressions in hours, not the typical 24h Apple review cycle
- The Notification Service gains a real consumer for push (not just email/SMS)

### Negative / Trade-offs
- We accept some bridge overhead vs. fully native. Mitigated by Reanimated/Skia for animation-heavy screens if needed
- Some native features (e.g., obscure payment SDKs) may require Expo config plugins or, in the worst case, a prebuild + bare workflow migration
- We must keep API contracts backward-compatible across at least N,2 mobile versions, since older installs cannot be force-upgraded, Expand-and-Contract applies to API changes as well as DB schemas
- Two store accounts (Apple Developer Program + Google Play Console) and their associated review/compliance overhead are now part of the release process

### Out of Scope (Explicitly)
- The customer web storefront and the admin web panel. Both are covered in [ADR-009](./ADR-009-web-frontend.md). The mobile app carries only **customer** flows. Admin functionality lives in the dedicated admin web app, not in the mobile binary.
- A bare-workflow React Native fork. We stay on the Expo managed workflow until a specific native dependency forces otherwise.
