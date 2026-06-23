# Detour

Find places along your route, ranked by how little time they add.

Enter origin, destination, and what you're looking for — coffee, dinner pickup, gas — and see options sorted by "+X minutes" of detour.

## The Problem

Google Maps shows you what's nearby. Detour shows you what's worth the stop.

No existing app makes detour time the primary ranking across all POI categories. Google Maps has "search along route" but buries it, doesn't sort by detour time, and has no max-detour filter. Waze limits you to one stop and shows results behind you. Apple Maps has no route-aware search at all.

## Core Features (MVP)

- **Detour-ranked results** — every result shows "+X min" added to your trip
- **Max-detour slider** — "only show places adding less than 5 minutes"
- **Forward-only** — never shows places behind you on the route
- **Category search** — gas, coffee, food, grocery, pharmacy, EV charging + free text
- **Navigation handoff** — deep links to Google Maps, Apple Maps, or Waze

## Target User

Daily commuters first. "Best coffee adding less than 5 min on my way to work." Road trippers as a later vertical.

## Tech Stack

| Layer | Choice |
|---|---|
| iOS | SwiftUI + MapKit |
| Android | Jetpack Compose + Google Maps SDK (post-validation) |
| Backend | Vercel Functions (shared between platforms) |
| Routing | Google Routes API |
| Places | Google Places Text Search (Search Along Route) |
| Database | Supabase (Postgres + PostGIS) |

All routing/POI logic lives server-side. Native apps are thin clients that render routes and markers.

## Project Structure

```
docs/               Research, competitive analysis, product strategy
ios/                 SwiftUI app (coming soon)
backend/             Vercel Functions API (coming soon)
```

## Status

Research and planning phase. See [docs/RESEARCH.md](docs/RESEARCH.md) for the full analysis.
