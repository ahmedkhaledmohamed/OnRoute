# Technical Stack & API Analysis

*June 2026*

---

## Architecture Overview

All routing/POI/detour logic lives server-side. Native apps are thin clients.

```
+--------------+    +--------------+
|  iOS App     |    | Android App  |
|  SwiftUI +   |    | Compose +    |
|  MapKit      |    | Google Maps  |
+------+-------+    +------+-------+
       |                    |
       +--------+-----------+
                | REST API
       +--------v--------+
       |  Backend (Vercel |
       |  Functions)      |
       |                  |
       |  - Route calc    |
       |  - POI search    |
       |  - Detour rank   |
       |  - Caching       |
       +--------+---------+
                |
    +-----------+-----------+
    |           |           |
+---v---+  +---v---+  +---v----+
|Google  |  |Google  |  |Supabase|
|Routes  |  |Places  |  |(cache, |
|API     |  |API     |  |users)  |
+--------+  +--------+  +-------+
```

---

## Routing APIs

### Google Maps Routes API
- **Polyline:** Encoded polyline (default) or GeoJSON LineString
- **Free tier:** 10,000 Essentials / 5,000 Pro (traffic-aware) per month
- **Cost:** $5/1K (Essentials), $10/1K (Pro, traffic-aware)
- **Rate limit:** 3,000 QPM
- **Key advantage:** Native integration with Places API Search Along Route

### Mapbox Directions API
- **Polyline:** `polyline`, `polyline6`, or `geojson`
- **Free tier:** 100,000 requests/month (most generous)
- **Cost:** $2/1K overage
- **Rate limit:** 300 req/min
- **Key advantage:** Cheapest commercial. Native SAR via Search Box with `time_deviation`.

### TomTom Routing API
- **Free tier:** 2,500 requests/day (~75K/month)
- **Cost:** ~$0.50/1K
- **Key advantage:** Native Along Route Search with `maxDetourTime` and `detourTime` in response. The only API that natively returns detour time per POI.

### HERE Routing API
- **Free tier:** 250,000 transactions/month (Base plan with credit card)
- **Cost:** $0.88/1K (routing), $2.65/1K (search)
- **Key advantage:** Native corridor search. Returns `excursionDistance` (how far off route).

### OSRM (Open Source)
- **Cost:** Free (self-hosted). Sub-millisecond queries.
- **RAM:** ~24 GB for North America, ~4 GB for Canada
- **Infrastructure:** ~$100-250/month on AWS, ~$48-96/month on Hetzner
- **Limitation:** No traffic data. Routing only, no POI search.

### Valhalla (Open Source) — Recommended for self-hosting
- **Cost:** Free (MIT license). Used by Tesla, BMW.
- **RAM:** 4-8 GB (tiled architecture, vs OSRM's 24 GB for US)
- **Infrastructure:** $40-50/month on Hetzner
- **Key advantage:** Native isochrones, runtime cost customization, `sources_to_targets` for batch detour calc.

---

## Places / POI APIs

### Google Places API (New) — Text Search
- **Native SAR:** YES. Pass encoded polyline via `searchAlongRouteParameters`. Returns routing summaries with detour duration/distance.
- **Free tier:** 5,000 Pro / 1,000 Enterprise per month (per SKU)
- **Cost:** $32/1K (Pro), $35-40/1K (Enterprise with ratings/photos)
- **Data:** 200M+ places, 50M+ daily updates. Best quality.
- **Max results:** 20/page, 60 total

### TomTom Along Route Search
- **Native SAR:** YES. Dedicated endpoint with `maxDetourTime` (up to 3600s). Returns `detourTime` and `detourDistance` per result.
- **Free tier:** 2,500/day
- **Cost:** ~$2.50/1K
- **Max results:** 20 per query
- **Data:** 131M+ POIs, 188 countries

### Mapbox Search Box
- **Native SAR:** YES. `/category` endpoint with `sar_type=isochrone`, `route=<polyline>`, `time_deviation=<minutes>`.
- **Free tier:** 25,000/month
- **Cost:** $1.70/1K
- **Data:** 330M+ POIs globally
- **Max results:** 25 per query

### HERE Geocoding & Search
- **Corridor search:** YES. `route` parameter with `w=<width_meters>`. Returns `distance` (along route) and `excursionDistance` (off route).
- **Free tier:** 250,000 transactions/month
- **Cost:** $2.65/1K
- **Limitation:** Polyline must fit in 2,048-byte URL (long routes lose precision)

### Foursquare Places API
- **No corridor search.** Radius or bounding box only.
- **Free tier:** 10K Pro/month (dropping to 500 in June 2026)
- **Cost:** $15/1K (Pro), $18.75/1K (Premium with photos/ratings)
- **Data:** 100M+ places. Half the cost of Google for basic searches.

### Overpass API (OpenStreetMap)
- **Corridor search:** YES. `around:{radius},{lat1,lon1,lat2,lon2,...}` filter.
- **Cost:** Free (public instance or self-hosted)
- **Data:** Community-mapped. No ratings, photos, or price levels. Uneven coverage.

---

## Algorithm Approaches

### Approach A: Google Native SAR (MVP)
```
1. POST /routes/computeRoutes -> encoded polyline
2. POST /places:searchText + searchAlongRouteParameters.polyline + routingSummaries
3. Response: places with legs[].duration (origin->place, place->destination)
4. Detour = (leg1 + leg2) - original_duration
```
Two API calls. ~$0.037 per search. Google handles all corridor logic.

### Approach B: TomTom Native SAR (Scale)
```
1. POST /routing -> route coordinates
2. POST /search/{query}/alongRoute.json + maxDetourTime
3. Response: places with detourTime (seconds), detourDistance (meters)
```
Purpose-built. ~$0.001 per search. Smaller POI database.

### Approach C: Self-hosted Hybrid (Cost optimization)
```
1. Compute route via Valhalla /route
2. Buffer polyline with PostGIS ST_Buffer (~15km)
3. Query POIs within buffer (Overpass or own DB)
4. Batch detour times via Valhalla /sources_to_targets
```
Full control. ~$40-50/month total infrastructure. Significant engineering.

### Detour Calculation via OSRM/Valhalla Table
Send `[Origin, POI_1, ..., POI_n, Destination]` to Table endpoint:
1. `sources=0, destinations=1..n` — origin to all POIs
2. `sources=1..n, destinations=n+1` — all POIs to destination
3. Sum per POI, subtract baseline route time

Two API calls for any number of POIs, free if self-hosted.

---

## Mobile Platform Decision

### Why native over Flutter

| Factor | Native (SwiftUI/Compose) | Flutter |
|---|---|---|
| Map FPS | 60 fps (Metal/Vulkan) | 30 fps on mid-range Android (PlatformView issue, Flutter #113381) |
| Map load | Native | ~1.8s (Mapbox) |
| Gesture conflicts | None | Bottom sheet + map pan conflicts |
| Memory | Clean | Custom markers leak (never cleaned up) |
| SDK support | First-party | Community-maintained wrappers |

Flutter's `google_maps_flutter` on Android uses PlatformView, causing documented frame drops with overlays + bottom sheets. `flutter_map` avoids this but loses Google Maps data. For a map-heavy app, native rendering matters.

### Why iOS first

- MapKit is free (unlimited map loads, 25K service calls/day)
- SwiftUI experience from Zia
- iPhone users pay more for apps
- All direct competitors are iOS-only
- MapKit iOS 18+ added `MapSelection`, iOS 19 adds `GeoToolbox`

### Mitigation for two codebases

Backend is shared — native apps are thin clients. Business logic duplication is near zero:
- iOS: SwiftUI views + MapKit rendering
- Android: Compose views + Google Maps rendering
- Both call the same REST API for routes, POIs, and detour calculations

---

## Cost Modeling

### Per-query cost by stack

| Stack | Cost/query | Free tier/mo |
|---|---|---|
| Google Routes + Places | ~$0.037 | ~5K queries |
| Mapbox + Search Box | ~$0.004 | ~25K queries |
| TomTom Along Route | ~$0.001 | ~75K queries |
| HERE + Discover | ~$0.004 | ~250K transactions |
| Self-hosted (Valhalla + Overpass) | ~$0 | N/A |

### Monthly cost by scale

| DAU | Google stack | Optimized stack (Mapbox/TomTom) | Self-hosted |
|---|---|---|---|
| 100 | ~$0 (free tier) | ~$0 (free tier) | ~$40-50 (infra) |
| 1,000 | ~$500-800 | ~$40-80 | ~$40-50 |
| 10,000 | ~$5,200-8,200 | ~$160-300 | ~$100-200 |
| 100,000 | ~$30,000-45,000 | ~$3,300 | ~$350-750 |

### Caching strategy

- **Google prohibits caching POI details.** Only Place IDs can be stored indefinitely.
- **Mapbox:** 30 days on device for offline tiles and search results.
- **HERE:** 30 days on device. Can download entire countries for offline.
- **OSM/Overpass:** No restrictions (ODbL license).

Cache corridor search results (same origin/destination/category within 1 hour) server-side in Supabase. Fetch fresh details only for results the user taps.

---

## Performance Considerations

### Marker rendering
- Custom view markers lag at 50-100 markers
- GL-rendered markers (SymbolLayer, GeoJSON source): 10,000+ at 60 fps
- Pre-render marker variants into a texture atlas at startup
- Use SDF icons for resolution-independent, GPU-colored markers

### Battery
- GPS: 13% battery (strong signal) to 38% (weak)
- Use `kCLAccuracyHundredMeters` + `distanceFilter: 50m` (not nav-grade)
- Set `activityType = .automotiveNavigation` on iOS for sensor fusion
- Dark map style saves 30-50% OLED battery at full brightness

### Real-time recalculation
- Debounce route changes at 300ms
- `AbortController.abort()` for in-flight requests
- Show uncalculated segments as dotted lines during drag
- Progressive: keep existing markers at reduced opacity -> client-side pre-filter -> server response -> lazy-load detour times for visible markers only
