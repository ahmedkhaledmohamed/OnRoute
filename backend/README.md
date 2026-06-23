# Detour Backend

Vercel Functions API for the Detour app. Handles route calculation, POI search along route, and detour time ranking.

## Setup

```bash
cd backend
npm install
```

## Run locally

```bash
npx vercel dev
```

The API will be available at `http://localhost:3000`.

## Endpoints

### `GET /api/health`

Health check.

```json
{ "status": "ok" }
```

### `POST /api/search`

Search for places along a route, ranked by detour time.

**Request:**
```json
{
  "origin": { "lat": 43.77, "lng": -79.26 },
  "destination": { "lat": 43.65, "lng": -79.38 },
  "query": "coffee",
  "maxDetourMinutes": 10,
  "openNow": true
}
```

**Response:**
```json
{
  "results": [
    {
      "placeId": "...",
      "name": "Balzac's Coffee Roasters",
      "address": "1 Distillery Lane, Toronto, ON",
      "lat": 43.6503,
      "lng": -79.3596,
      "detourSeconds": 120,
      "detourFormatted": "+2 min",
      "rating": 4.5,
      "userRatingCount": 342,
      "isOpenNow": true,
      "types": ["cafe", "coffee"]
    }
  ],
  "route": {
    "encodedPolyline": "...",
    "durationSeconds": 2700,
    "distanceMeters": 38000
  }
}
```

## Environment Variables

Copy `.env.example` to `.env` and set your API key:

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Maps Platform key (Routes API + Places API enabled) |
