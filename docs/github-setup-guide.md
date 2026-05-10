# GitHub Projects + MCP Setup Guide

## Step 1: Initialize Git Repo + Push to GitHub

Run these commands in your terminal:

```bash
cd /Users/anas/Projects/sol_arch_proj

# Initialize git
git init
git add .
git commit -m "docs: initial architecture design with ADRs"

# Create GitHub repo (requires GitHub CLI)
gh repo create sol_arch_proj --private --source=. --push
```

> If you don't have GitHub CLI (`gh`), install it first:
> ```bash
> brew install gh
> gh auth login
> ```

---

## Step 2: Create GitHub Project Board

1. Go to your repo on GitHub: `https://github.com/<your-username>/sol_arch_proj`
2. Click the **Projects** tab
3. Click **New project**
4. Select **Board** (Kanban view)
5. Name it: `E-Commerce Platform`
6. It will create default columns: **Todo**, **In Progress**, **Done**
7. Add one more column: **Review** (between In Progress and Done)

Your columns should be:
```
Backlog → In Progress → Review → Done
```

Rename "Todo" to "Backlog" by clicking the column header.

---

## Step 3: Create Labels for Issue Categorization

Go to: `https://github.com/<your-username>/sol_arch_proj/labels`

Delete the default labels and create these:

### By Component
| Label | Color (hex) | Description |
|---|---|---|
| `service:user` | `#1d76db` | User Service |
| `service:product` | `#0e8a16` | Product Service |
| `service:order` | `#d93f0b` | Order Service |
| `service:inventory` | `#e4e669` | Inventory Service |
| `service:payment` | `#5319e7` | Payment Service |
| `service:pricing` | `#006b75` | Pricing Service |
| `service:cart` | `#f9d0c4` | Cart Service |
| `service:notification` | `#c2e0c6` | Notification Service |
| `frontend` | `#bfd4f2` | React Frontend |
| `infra` | `#d4c5f9` | Terraform, K8s, CI/CD |
| `api-gateway` | `#fef2c0` | Kong Configuration |
| `shared-pkg` | `#c5def5` | Shared Go Libraries |
| `docs` | `#0075ca` | Documentation |

### By Type
| Label | Color (hex) | Description |
|---|---|---|
| `epic` | `#b60205` | Large feature spanning multiple issues |
| `task` | `#fbca04` | Single unit of work |
| `bug` | `#d73a4a` | Something is broken |
| `spike` | `#d876e3` | Research or investigation |

### By Priority
| Label | Color (hex) | Description |
|---|---|---|
| `P0:critical` | `#b60205` | Must be done first |
| `P1:high` | `#d93f0b` | Important |
| `P2:medium` | `#fbca04` | Normal priority |
| `P3:low` | `#0e8a16` | Nice to have |

---

## Step 4: Create Milestones

Go to: `https://github.com/<your-username>/sol_arch_proj/milestones`

Create these milestones in order:

| Milestone | Description |
|---|---|
| `M1: Foundation` | Repo setup, Taskfile, shared packages, Docker Compose for local dev |
| `M2: Core Services` | User, Product, Cart, Pricing services with PostgreSQL |
| `M3: Event Backbone` | Kafka setup, outbox pattern, event publishing |
| `M4: Order Saga` | Order, Inventory, Payment services with Saga choreography |
| `M5: API Gateway + Auth` | Kong setup, Keycloak integration, RBAC |
| `M6: Frontend` | React SPA with MUI |
| `M7: Observability` | slog, Prometheus, Grafana dashboards |
| `M8: Infrastructure` | Terraform, K8s manifests, GitHub Actions CI/CD |

---

## Step 5: Set Up GitHub MCP Server

Add the GitHub MCP server to your Gemini CLI config.

### Option A: Add to Gemini CLI settings

Edit the file at `~/.gemini/settings.json` and add:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-github-pat>"
      }
    }
  }
}
```

### Create a GitHub Personal Access Token (PAT)

1. Go to: `https://github.com/settings/tokens?type=beta` (Fine-grained tokens)
2. Click **Generate new token**
3. Name: `sol-arch-mcp`
4. Repository access: **Only select repositories** → select `sol_arch_proj`
5. Permissions:
   - **Issues:** Read and Write
   - **Projects:** Read and Write
   - **Pull Requests:** Read and Write
   - **Contents:** Read and Write
6. Click **Generate token**
7. Copy the token and paste it in the config above

---

## Step 6: Verify Everything Works

After setup, restart Gemini CLI and ask me to:
- "Create an issue for setting up the Taskfile"
- "List all open issues"
- "Add a label to issue #1"

If I can do those, we're good to go and I'll create all the epics and tasks for the full project.

---

## Quick Reference

| What | Where |
|---|---|
| Repo | `https://github.com/<username>/sol_arch_proj` |
| Kanban Board | Repo → Projects tab → E-Commerce Platform |
| Issues | Repo → Issues tab |
| Labels | Repo → Issues → Labels |
| Milestones | Repo → Issues → Milestones |
| MCP Config | `~/.gemini/settings.json` |
