# MiniDex

[![Check Server](https://github.com/DaylightLtd/minidex/actions/workflows/check-server.yaml/badge.svg)](https://github.com/DaylightLtd/minidex/actions/workflows/check-server.yaml)
[![Check Web](https://github.com/DaylightLtd/minidex/actions/workflows/check-web.yaml/badge.svg)](https://github.com/DaylightLtd/minidex/actions/workflows/check-web.yaml)
[![Secret Scan](https://github.com/DaylightLtd/minidex/actions/workflows/secret-scan.yaml/badge.svg)](https://github.com/DaylightLtd/minidex/actions/workflows/secret-scan.yaml)
![Swift 6.2](https://img.shields.io/badge/swift-6.2-orange?logo=swift)
![Node.js 20](https://img.shields.io/badge/node.js-20.x-339933?logo=node.js)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

> MiniDex is a personal catalogue for miniature painters and collectors. It lets you record each mini, tag it by game system, and track everything from acquisition to paint status so your collection is always at your fingertips.

## Project Layout

- `Sources/MiniDexServer` – Vapor application exposing authentication, minis, and game system APIs.
- `Sources/MiniDexDB` - miniature/domain model database.
- `Sources/AuthAPI` - reusable authentication module for Vapor apps.
- `Sources/AuthDB` - database for authentication.
- `web/` – Next.js frontend that talks to the Vapor API through `/api/*` proxy routes.
- `Resources/Views` and `Public/` – server-rendered assets that Vapor can serve if desired.

## Getting Started

### Prerequisites

- Swift 6.2 (or the toolchain specified in `Package.swift`)
- Node.js 20.x + npm 10.x for the frontend
- Docker 24+ (optional, for Compose-based workflows)

### Configure Environment Variables

1. Copy `.env.example` to `.env`.
2. Provide real values for the database connection and bootstrap admin account.
3. `.env` is loaded automatically by Vapor (`Environment.get`) and by Docker Compose. Keep it out of source control.

### Local Development

Server development is generally done in Xcode, but you can develop in whatever editor and compile via shell:

```bash
swift build
swift test
```

Recommended way of launching the server is via Docker Compose, these are the available services:

- `server` – Vapor API listening on port `8080`.
- `web` – Next.js app on port `3000`, proxying requests to `server`.
- `db` / `redis` – Postgres + Redis backing services that expect the same env variables defined in `.env`.

To run the stack first copy the `.env.example` into `.env`, tweak the values as needed and then run:

```bash
docker compose up --build
```

This will start both server and web services in dev mode, web supports hot reload.

Run database migrations inside the Compose stack:

```bash
docker compose run --rm migrate
```

The web app proxies API calls through Next.js routes (`/api/*`) to the Vapor server running on `http://localhost:8080`.

## Testing & Quality

- `swift test` exercises the server, shared modules, and utilities.
- `cd web && npm run lint && npm run tsc && npm run prettier` keeps the frontend clean.
- `cd web && npm run lint:fix` to automatically fix lint issues.
- `cd web && npm run prettier:fix` to automatically apply formatting.
- GitHub Actions (Check Server, Check Web, Secret Scan) run on every push/PR to `master`.

## Security

Please review [SECURITY.md](SECURITY.md) for reporting guidelines and secret-handling expectations.

## License

Released under the [GNU AGPL v3.0](LICENSE). See the file for details.

## About This Project

- MiniDex doubles as my creative coding sandbox and a practical way to keep the miniature pile of shame under control.
- **Immediate goal:** capture every mini with rich metadata—game system, faction, unit, origin, cost—so the collection is searchable instead of buried in foam trays.

## Future Ideas

- **Painting workflow & coaching**
  - Session tracking (time spent per mini/project, Pomodoro-style painting sessions)
  - “Paint recipes” library with steps, colors, photos, and reuse across minis
  - Skill progression tracking and before/after comparisons over time

- **Smart collection insights**
  - Stats dashboards (points per faction, painted vs unpainted backlog, spend over time)
  - “Backlog health” indicators and suggested next projects (e.g., finish this unit to complete a list)
  - Budgeting tools and spend limits with gentle nudges when you’re about to buy another box

- **Image & recognition features**
  - Photo-driven entry: snap a mini, auto-suggest game system/faction via tags
  - Automatic background removal and simple photo editing tuned for mini pics
  - Style tagging (grimdark, comic-book, etc.) and search by visual style

- **Social & sharing**
  - Public profiles and shareable collection links (per army, per game system)
  - Collaborative “club collections” for local gaming groups
  - Commenting/likes on gallery entries, with privacy controls

- **Gaming integration**
  - Basic list/army builder tied into your catalogue (pull minis into lists)
  - “On-table” view for games: track which minis are on the board, wounded, etc.
  - Scenario pack support: tag minis to scenarios, quickly see what you still need to build/paint

- **Inventory & logistics**
  - Storage location tracking (box/shelf/room) with QR labels on cases
  - Condition/repair tracking (broken bits, magnetized, pinned, etc.)
  - Wishlist & pre-order tracking across stores, with simple spend history

- **Multi-platform companion**
  - Watch app for quick checklists during painting sessions or tournaments
  - Offline-first mobile app for conventions/gaming nights, syncing when online
  - Simple export/import (CSV/JSON) for backups and data portability
