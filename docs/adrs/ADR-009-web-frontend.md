# ADR-009: Web Frontend Stack, Next.js Storefront + React/Vite Admin

**Status:** Accepted
**Date:** 2026-05-16
**Decision Makers:** Solution Architect
**Relates to:** [ADR-008](./ADR-008-mobile-platform.md) (mobile clients), [ADR-001](./ADR-001-monorepo-tooling.md) (monorepo tooling)

## Context
ADR-008 made the platform mobile-first and explicitly dropped both the customer web SPA and the standalone admin web panel. Product direction has since expanded:

- **Customer web storefront** is required with feature parity to the mobile app. Web cannot be skipped because:
  - SEO is a primary acquisition channel for e-commerce. Product, category, and PDP pages must be crawlable and rank in Google. A pure CSR SPA indexes poorly and forfeits organic traffic.
  - Conversion is sensitive to first-paint and LCP. Server-rendered HTML for content-heavy pages outperforms hydrating a CSR shell.
  - Shareability (links pasted into chat/email/social) requires Open Graph and Twitter Card previews rendered at request time per product.
- **Admin panel** is required as a separate web application:
  - Admin workflows (bulk product edits, order ops, promotion management, analytics) are inherently desk-bound and benefit from large screens, keyboards, and multi-tab workflows.
  - Embedding admin in the mobile app (the original ADR-008 stance) couples cadence, increases the customer-app bundle, and risks leaking admin code paths to customers.
  - Admin has no SEO requirement and sits behind authentication.

We need a web strategy that:

- Maximises SEO and Core Web Vitals for the storefront
- Reuses the OpenAPI-generated TypeScript client already used by the mobile app
- Keeps the admin app simple, fast to iterate on, and decoupled from the customer release cadence
- Shares UI primitives across web surfaces without forcing one framework to fit both jobs

## Options Considered

### Storefront
| Option | Pros | Cons |
|---|---|---|
| **Next.js (App Router)** | First-class SSR/ISR/SSG, RSC for data-heavy pages, route-level code splitting, `next/image`, `next/og` for share cards, mature ecosystem, deployable to Vercel **or** self-hosted Node on K8s behind Cloudflare | Heavier than a CSR SPA, App Router learning curve, some lock-in to Next idioms |
| **Remix** | Web-fundamentals first, nested loaders/actions, good DX | Smaller ecosystem post-React-Router merger, fewer hosting options, less battle-tested at e-commerce scale |
| **Astro (with React islands)** | Best raw perf for content sites, ships near-zero JS by default | Designed for content-heavy sites with light interactivity. Full e-commerce flows (cart, checkout, account) push it outside its sweet spot |
| **Vite + React SPA** | Simple, fast HMR, one mental model with admin | No SSR, SEO and LCP suffer for storefront pages. Would need bolt-on pre-rendering |
| **Nuxt / SvelteKit** | Strong SSR stories | Different framework family from RN/admin React. Team would maintain two component vocabularies |

### Admin Panel
| Option | Pros | Cons |
|---|---|---|
| **React + Vite (SPA)** | Minimal config, instant HMR, smallest moving-part count, no SSR tax, fine for auth-walled UI | No SSR (irrelevant for admin) |
| **Next.js (App Router)** | One framework across web surfaces | Pays SSR complexity tax for no benefit. Route caching and server actions add ceremony admin doesn't need |
| **Refine / React Admin** | Pre-built CRUD scaffolding | Heavy opinionation. Harder to escape when domain UI diverges from CRUD |

### Where the admin lives
| Option | Pros | Cons |
|---|---|---|
| **Separate `admin-web` app at `admin.example.com`** | Independent release cadence, no admin code in customer bundles, smaller blast radius, clearest CSP/auth boundary | Two pipelines, two deployments |
| **`/admin` route inside the Next.js storefront** | One app, one deploy | Admin code risks shipping to every customer browser unless aggressively code-split. Mixing public+private CSP is fiddly |
| **Admin inside the mobile app (ADR-008 status quo)** | No new web surface | Admins want desktop ergonomics. Couples release to store review |

## Decision

**Two web apps, two tools, one shared design system.**

### Customer Web Storefront → **Next.js (App Router) + TypeScript**
- **Rendering:**
  - **SSG / ISR** for product, category, and CMS pages (cacheable, SEO-critical).
  - **SSR** for personalised pages (account, order history) where freshness matters.
  - **CSR** for cart and checkout interactions after the initial paint.
- **Data:** Generated OpenAPI TypeScript client (same package used by mobile, `pkg/api-client-ts`), TanStack Query on the client, server-side fetches via RSC where it pays off.
- **Auth:** Keycloak OIDC Authorization Code + PKCE via `next-auth` (or a thin custom adapter), HttpOnly secure cookies (not `localStorage`).
- **Styling/UI:** Tailwind CSS + Radix UI primitives, wrapped in a shared `pkg/ui-web` workspace.
- **Image / SEO:** `next/image`, `next/og` for OG/Twitter cards, structured data (JSON-LD `Product`, `Offer`, `BreadcrumbList`).
- **Hosting:** Self-hosted Next.js (Node runtime) on the same EKS/GKE cluster as backend services, fronted by Cloudflare (CDN/WAF). Vercel kept as an escape hatch if we want managed hosting later. Nothing in the code should depend on Vercel primitives.

### Admin Panel → **React + Vite (SPA) + TypeScript**
- **Routing:** React Router v6.
- **State/data:** Same generated OpenAPI client, TanStack Query, TanStack Table for data grids.
- **Auth:** Keycloak OIDC PKCE, role-gated (`admin`, `support` realm roles). Hard-block non-admin tokens at the app shell.
- **UI:** Same `pkg/ui-web` design system as the storefront so primitives stay consistent.
- **Hosting:** Static build served by Cloudflare Pages (or Nginx in K8s as an alternative), behind WAF rules that restrict by IP allowlist where feasible.

### Mobile Apps (unchanged)
React Native (Expo) per [ADR-008](./ADR-008-mobile-platform.md). The mobile app keeps `customer` flows. Admin functionality is **moved off** the mobile app into the dedicated admin web. Admins use desktops.

### Shared Across All Frontends
- **`pkg/api-client-ts`**, OpenAPI-generated TS client + Zod schemas, consumed by `mobile`, `web`, and `admin-web`.
- **`pkg/ui-web`**, Tailwind config, design tokens, and Radix-based primitives used by both web apps (not RN. RN keeps Paper).
- **`pkg/events-ts`**, TS mirrors of Go event structs for any client that subscribes to server-sent updates.

## Consequences

### Positive
- Storefront pages are server-rendered → indexable, ranking-eligible, and fast on first paint without bolt-on prerender hacks.
- Admin is simple and stays simple. No SSR ceremony, no server runtime to operate beyond static files.
- The OpenAPI contract becomes the single source of truth across **four** clients (iOS, Android, web, admin), reinforcing the contract-first discipline already in place for the mobile app.
- Admin code never ships to customer browsers. Smaller bundles, fewer CSP carve-outs, stricter cookie/origin separation.
- Design system primitives are reused across the two web surfaces, so customer and admin UIs stay visually coherent without re-implementing controls.

### Negative / Trade-offs
- **Three frontend pipelines** (mobile, web, admin-web) instead of one. CI/CD complexity grows. Offset by the fact that each pipeline is independently simpler than a one-size-fits-all setup.
- **Two different React dialects** (RN + web). The OpenAPI client and event types port cleanly. UI primitives do not, RN keeps Paper, web uses Tailwind/Radix.
- **Auth surface area expands.** Three OIDC clients in Keycloak (`mobile`, `web`, `admin-web`), each with its own redirect URIs and PKCE config. Token handling differs per client (Keychain on mobile, HttpOnly cookie on web).
- **SSR adds an attack surface** the SPA didn't have: SSRF risk in server fetches, secrets in the Node runtime, RSC payload leakage. The web service runs with no secrets beyond a backend-API service token and the Keycloak public client config.
- **Cache invalidation for ISR** is now a thing we must design (revalidate on product/price updates via webhook from Product/Pricing services into Next.js `revalidatePath`).

### Out of Scope (Explicitly)
- A native desktop admin app (Electron/Tauri). The web admin is sufficient.
- An open public API for third-party integrations. The OpenAPI specs are internal contracts. An external developer portal would be a separate ADR.
- Server Components fetching directly from PostgreSQL. The web service is a frontend. It talks to Kong over REST like every other client. No back-channel DB access.
