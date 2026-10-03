# Acquisitions Application - Docker & Neon Setup

This repository contains an Express.js application configured with **Drizzle ORM** and **Neon Database**. It supports two distinct operational modes for development and production using Docker and Docker Compose.

---

## Architecture Overview

```
+-----------------------------------------------------------------------------------+
| DEVELOPMENT (Local)                                                               |
|                                                                                   |
|  +-----------------------+                    +--------------------------------+  |
|  |  acquisitions-app-dev | --(DATABASE_URL)-->|           neon-local           |  |
|  |  (Express Container)  |                    | (Neon Local Proxy Service)     |  |
|  +-----------------------+                    +--------------------------------+  |
|                                                                |                  |
|                                                   (Creates Ephemeral Branch)     |
|                                                                v                  |
|                                                   +----------------------------+  |
|                                                   |   Neon Cloud (Dev Branch)  |  |
|                                                   +----------------------------+  |
+-----------------------------------------------------------------------------------+

+-----------------------------------------------------------------------------------+
| PRODUCTION                                                                        |
|                                                                                   |
|  +-----------------------+                                                        |
|  | acquisitions-app-prod | -------------------(DATABASE_URL)-------------------+   |
|  | (Express Container)   |                                                     |   |
|  +-----------------------+                                                     |   |
|                                                                                v   |
|                                                   +----------------------------+  |
|                                                   | Production Neon Cloud DB   |  |
|                                                   +----------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## Environment Variable Configuration

Database connections are dynamically configured using `DATABASE_URL`. Separate environment files manage configuration per target environment:

### 1. Development Environment (`.env.development`)

Points the application to the `neon-local` proxy container inside the Docker network. Ephemeral branches are generated automatically using your Neon credentials.

```env
# Server Configuration
PORT=3000
NODE_ENV=development
LOG_LEVEL=debug

# Neon Credentials for Ephemeral Branching
NEON_API_KEY=your_neon_api_key
NEON_PROJECT_ID=your_neon_project_id

# Local Database Connection String (via Neon Local Proxy)
DATABASE_URL=postgres://neon:npg@neon-local:5432/neondb?sslmode=no-verify
```

### 2. Production Environment (`.env.production`)

Points directly to your primary Neon Cloud Database host without a proxy.

```env
# Server Configuration
PORT=3000
NODE_ENV=production
LOG_LEVEL=info

# Production Neon Cloud Database Connection String
DATABASE_URL=postgres://neondb_owner:password@ep-sample-host.neon.tech/neondb?sslmode=require
```

---

## Local Development with Neon Local

**Neon Local** runs as a proxy alongside the app. On container start, it automatically creates an isolated ephemeral database branch in Neon Cloud and tears it down when stopped.

### Prerequisites

1. Docker & Docker Compose installed.
2. Neon API Key and Project ID configured in `.env.development`.

### Quick Start (Development)

Run the development stack (App + Neon Local):

```bash
docker compose -f docker-compose.dev.yml up --build
```

_(Or simply `docker compose up`)_

### How Ephemeral Branching Works

1. `neon-local` service starts and connects to your Neon project using `NEON_API_KEY` and `NEON_PROJECT_ID`.
2. Neon creates a new, temporary PostgreSQL branch for your dev session.
3. Your application communicates with `neon-local:5432` locally; the proxy routes all queries to the ephemeral branch.
4. When `docker compose down` is run, the proxy cleans up and removes the temporary branch.

---

## Production Deployment

In production, no proxy container is deployed. The containerized application communicates directly with your cloud-hosted Neon database over SSL.

### Running in Production Mode

1. Ensure `.env.production` contains your live `DATABASE_URL`.
2. Deploy using `docker-compose.prod.yml`:

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

---

## Command Reference Summary

| Environment     | Compose File              | Command                                           | Connection Target         |
| :-------------- | :------------------------ | :------------------------------------------------ | :------------------------ |
| **Development** | `docker-compose.dev.yml`  | `docker compose -f docker-compose.dev.yml up`     | `neon-local:5432` (Proxy) |
| **Production**  | `docker-compose.prod.yml` | `docker compose -f docker-compose.prod.yml up -d` | Neon Cloud DB Host        |

## TESTING CI/CD PIPELINES
