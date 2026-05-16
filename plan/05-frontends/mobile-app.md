# Mobile App (React Native + Expo)

## Purpose

Single React Native codebase producing iOS and Android binaries via Expo (managed workflow). Auth via OIDC PKCE through `expo-auth-session`; tokens in `expo-secure-store` (Keychain / Keystore). Uses generated TS client from `packages/api-client-ts`.

## Inputs / Prerequisites

- ADR-008 confirmed (Expo / RN / TS / Paper)
- `packages/api-client-ts` published from [`openapi-codegen.md`](./openapi-codegen.md)
- Keycloak `mobile-app` client configured (PKCE, Universal Link + custom scheme redirect URIs)

## Tasks

1. [ ] Initialize Expo project under `mobile/` using TypeScript template — effort: S
2. [ ] Configure `app.config.ts`: bundle identifier, scheme, Universal Links (iOS apple-app-site-association) + Android App Links — effort: M
3. [ ] Set up React Navigation (stack + bottom-tabs): Home, Search, Cart, Account stacks — effort: M
4. [ ] Theme via React Native Paper (Material 3) — effort: S
5. [ ] Auth flow: `expo-auth-session` with PKCE, tokens stored in `expo-secure-store`, refresh-token rotation — effort: L
6. [ ] API layer: TanStack Query + `packages/api-client-ts`, auto-attach `Authorization: Bearer` header, 401 → refresh → retry — effort: M
7. [ ] Screens (MVP):
   - Home (featured products from Product Service)
   - Product list / search
   - Product detail
   - Cart
   - Checkout (creates PaymentIntent via Payment Service, confirms via Stripe RN SDK)
   - Order list / detail
   - Account / addresses
   - Login / signup (delegated to Keycloak)
   — effort: XL
8. [ ] Push notifications: `expo-notifications`, register token with Notification Service on login, handle deep-link payloads — effort: M
9. [ ] EAS Build profiles `eas.json`: `development`, `preview`, `production` per design-doc §11.5 — effort: M
10. [ ] `minimum_supported_version` check on cold start; show blocking "update required" screen if backend says we're too old — effort: M
11. [ ] Hardening: jailbreak detection (`jail-monkey`), no debug Reanimated in release, ProGuard/R8 on Android — effort: M
12. [ ] Certificate pinning to Kong's TLS leaf/intermediate — effort: M
13. [ ] Submit to TestFlight + Play Internal Testing — effort: M

## Deliverables

- `mobile/` Expo project building to iOS + Android
- EAS Build pipelines hooked into GitHub Actions
- TestFlight + Play Internal builds installable on test devices
- Universal/App Links verified working

## Exit Criteria

- [ ] Full purchase flow works on a real iPhone and Android device
- [ ] OAuth login completes via in-app browser, tokens survive app restart
- [ ] Push notification arrives within 10s of order confirmation
- [ ] Force-upgrade screen displays when backend reports old version
- [ ] Cert pinning blocks a MITM via mitmproxy on a rooted test device

## References

- Design doc: §3.1 Context (Mobile), §9.4 Mobile Token Storage, §11.5 Mobile App Release Pipeline
- ADR-008 Mobile platform

## Risks & Open Questions

- Stripe RN SDK adds native dependencies; verify EAS Build works with it (use `expo-stripe` if available, else `@stripe/stripe-react-native` via config plugin).
- EAS Update for OTA: limit to JS-only and copy fixes; native changes always require store review.
