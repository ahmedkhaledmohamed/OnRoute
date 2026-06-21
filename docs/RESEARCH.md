# Research & Product Plan

*June 2026*

## Context

A mobile app that shows places along your route from A to B, ranked by how little detour they add. You enter origin, destination, and what you're looking for (coffee, dinner, gas) — the app returns options sorted by "+X minutes" added to your trip.

### Decisions

- **Target user:** Daily commuters first, road trippers as a later vertical
- **Build approach:** Solo, native on both platforms (SwiftUI + Jetpack Compose), iOS MVP first
- **Scale ambition:** Build MVP, see traction, then decide indie vs venture

---

## 1. The Market Gap

**No consumer app makes detour time the primary organizing principle across all POI categories.**

| What exists today | What's missing |
|---|---|
| Google Maps shows "+X min" per stop but doesn't sort by it, has no max-detour filter, and buries the feature in navigation | A dedicated UX where detour cost IS the ranking |
| Apple Maps has no route-aware search at all | Any corridor-based discovery on iOS's native nav |
| Waze limits you to 1 stop, shows results behind you, categories only | Multi-stop, forward-only, free-text search |
| FastFork ranks by detour distance — food only, iOS only, 5 ratings | General-purpose version across all categories |
| Roadtrippers uses distance-from-route, not detour time | Time-based ranking (accounts for highway exits, traffic) |
| TomTom API sorts by detour time natively — but it's a developer API, not a consumer product | A consumer app built on this capability |

The APIs exist to build this. Google and TomTom have purpose-built "search along route" endpoints. Nobody has wrapped them in a focused consumer product.

---

## 2. Competitive Landscape

### Direct competitors (all early/dead)

| App | What it does | Status | Key gap |
|---|---|---|---|
| **FastFork** | Food along route, detour distance shown | iOS only, 5 ratings, launched Apr 2025 | Food only, distance not time |
| **On The Way / By The Ways** | Attractions with 10/20/30min detour filter | Tiny user base, Europe-focused | Tourism only, not daily use |
| **Along the Way** | Route POI search via Foursquare | Last updated 2014, effectively dead | Abandoned |
| **iExit** | Exit-by-exit interstate guide | 3M+ downloads, active | Interstate only, no detour ranking |
| **Roadtrippers** | 30M+ POIs, distance corridor | $19.4M ARR, paywall at 7 stops | No detour time, planning only |
| **Wanderlog** | Collaborative trip planner | 1.5M MAU, Y Combinator | No corridor search |

### Incumbents

| Platform | Search along route? | Detour time shown? | Max-detour filter? | Multi-category? |
|---|---|---|---|---|
| **Google Maps** | Yes | Yes ("+X min") | No | No (one at a time) |
| **Apple Maps** | No | No | No | No |
| **Waze** | Partial (categories only) | Partial | No | No |
| **Roadtrippers** | Yes (distance corridor) | No | Yes (distance, not time) | Yes |
| **TomTom API** | Yes (developer API) | Yes (default sort) | Yes (`maxDetourTime`) | Yes |
| **HERE** | Yes (corridor param) | Partial (`excursionDistance`) | No | No |

### Why Google won't close this gap

Google's incentive is ad revenue — promoted listings, not detour minimization. A "local-first, shortest-detour" ranking directly conflicts with their business model. They also treat search-along-route as a secondary feature within navigation, not a standalone experience.

### User pain points (from forums)

**Waze UserVoice (top requests):**
- "Show results AHEAD on my route, not behind me"
- "Let me set max detour: 10/30/60 min off-route"
- "Sort by miles added by deviation"
- "Search with time context: lunch between noon and 1pm"

**Google Maps Community:**
- UI regression: new card design removes ability to see stops on map relative to route
- Results cluster at start/end of route, mid-route is underserved
- Rest stops "almost an hour" off route still appear as "along route"

**TripAdvisor forums:**
- "There is no easy/single app for doing that" — users combine 3-4 apps

---

## 3. Market Size

| Segment | Size (2024-2025) | Growth |
|---|---|---|
| Navigation apps | $21B revenue | 14.7% YoY |
| Location-based services | $48-70B | 12-25% CAGR |
| Road trip planner apps | $2.3B | Growing to $6.9B by 2032 |
| Location-based advertising | $150B | 16% CAGR |
| EV charging apps | $12-13B | 40.5% CAGR |

**User behavior:**
- 46% of all Google searches have local intent (~7.5B/day)
- 78% of local mobile searches lead to offline purchase within 24 hours
- 1.95 billion road trips in the US in 2024 (record)
- "Near me" searches growing 150% YoY

---

## 4. Technical Architecture

### The core algorithm

**Approach A: Google's native Search Along Route (recommended for MVP)**
1. Call Routes API `computeRoutes` -> get encoded polyline
2. Call Places Text Search (New) with `searchAlongRouteParameters.polyline.encodedPolyline`
3. Response includes places near route with duration/distance per leg
4. Detour = (leg1 + leg2) - original route duration
5. **Two API calls total.** Google handles all corridor logic.

**Approach B: TomTom Along Route Search (cheapest with native detour time)**
- Has a `maxDetourTime` parameter (up to 3600s)
- Returns `detourTime` per result as the default sort
- ~37x cheaper than Google per query
- Smaller POI database

**Approach C: Self-hosted (Valhalla + Overpass, zero API cost)**
- Buffer route polyline, query OSM POIs in corridor
- Use Valhalla `sources_to_targets` for batch detour calculation
- Full control, $40-50/mo on Hetzner, but significant engineering effort

### API comparison

| Stack | Cost/query | Free tier | POI quality | Native SAR? |
|---|---|---|---|---|
| Google Routes + Places | ~$0.037 | ~5K/mo | Best (200M+ POIs) | Yes |
| Mapbox Directions + Search Box | ~$0.004 | 25K+/mo | Good (330M+ POIs) | Yes (`time_deviation`) |
| TomTom Along Route | ~$0.001 | 2,500/day | Good (131M+ POIs) | Yes (`detourTime`) |
| HERE Routing + Discover | ~$0.004 | 250K/mo | Good | Yes (corridor) |
| OSRM + Overpass (self-hosted) | ~$0 | N/A | Basic (OSM) | DIY |

### Monthly API cost at scale (Google stack)

| DAU | Sessions/mo | Monthly API cost |
|---|---|---|
| 1,000 | 60,000 | ~$500-800 |
| 10,000 | 600,000 | ~$5,200-8,200 |
| 100,000 | 6,000,000 | ~$30,000-45,000 |

### Cost at scale (optimized stack: Mapbox + TomTom + Valhalla)

| MAU | Monthly cost |
|---|---|
| 1,000 | ~$0 (free tiers) |
| 10,000 | ~$160-300 |
| 100,000 | ~$3,300 |

### Recommended tech stack

| Layer | MVP choice | Why | Android / Scale |
|---|---|---|---|
| **iOS** | SwiftUI + MapKit | Free maps, 60 fps, Zia experience | Jetpack Compose + Google Maps SDK |
| **Routing** | Google Routes API | Native polyline for SAR. 10K free/mo | Same API, shared backend |
| **Places** | Google Places Text Search (New) | Purpose-built SAR. 5K free/mo | TomTom at scale ($2.50/1K vs $32/1K) |
| **Detour calc** | Google routing summaries | Included in SAR response | Self-host Valhalla ($40-50/mo) |
| **Backend** | Vercel Functions | Zero infra. Shared across platforms | Node.js server |
| **Database** | Supabase (Postgres + PostGIS) | Free tier, geospatial caching | Self-hosted Postgres |

### Architecture

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

Native apps are thin clients. All routing/POI/detour logic is server-side.

### API cost mitigation path

1. **Cache aggressively** — same corridor + category within 1 hour = cached response
2. **Use "IDs Only" tier** ($0/1K) then fetch details only for displayed results
3. **Migrate to TomTom** at 10K+ DAU (native `detourTime`, $2.50/1K vs $32/1K)
4. **Self-host Valhalla** at $500+/mo API costs ($40-50/mo on Hetzner, 4-8 GB RAM for US)

---

## 5. Product Strategy

### Use cases (commuter-first)

1. **Morning commute** — "Best coffee adding <5 min on my way to work"
2. **Evening commute** — "Dinner pickup that barely adds time on my way home"
3. **Errands on the way** — "Pharmacy or grocery store, under 3 min detour"
4. **Parents** — "Playground or family spot coming up, not behind us"
5. **Gas/EV charging** — "Cheapest gas within 5 min of my route"

### 10x differentiators vs Google Maps

| Differentiator | Why Google can't/won't do this |
|---|---|
| **Detour time IS the primary ranking** | Conflicts with ad-revenue incentive to show promoted listings |
| **Max-detour slider** | Most-requested feature on Waze UserVoice. Nobody offers it. |
| **Forward-only results** | Google/Waze both show places behind you |
| **Time budget mode** ("I have 15 extra minutes") | Flips model from category-search to time-budget browsing |
| **Multi-stop clustering** ("gas + coffee" as one detour) | No competitor does this |
| **Local-first ranking** (de-rank chains) | Directly conflicts with Google's ad model |
| **Corridor memory** (remember visited, surface new) | Requires being a focused product, not a feature |

### MVP scope (v1)

| Feature | Detail |
|---|---|
| Route input | Origin + destination text fields with autocomplete |
| Category search | Free-text + quick buttons: gas, coffee, food, grocery, pharmacy, EV charging |
| Detour ranking | Every result shows "+X min" — default sort by lowest detour |
| Max-detour filter | Slider: 1-30 min max detour |
| Forward-only | Only show stops ahead on the route |
| Open now | On by default |
| Map view | Route polyline + POI pins with detour labels |
| List view | Sortable by detour time, rating, or distance |
| Navigation handoff | Deep link to Google Maps / Apple Maps / Waze |
| Ratings & hours | From Google Places |

**Excluded from v1:** accounts, personalization, multi-stop, social, offline, CarPlay/Android Auto, saved routes, corridor memory.

### v2 features (post-validation)

| Feature | Why |
|---|---|
| Time budget mode | "I have 20 min" — browse everything within budget |
| Multi-stop clustering | "Gas + coffee" combos with one detour time |
| Corridor memory | Track visited stops, surface new openings for commuters |
| Arrive-by constraint | Only show schedule-compatible stops |
| Local-first toggle | De-rank chains, surface independents |
| CarPlay / Android Auto | Critical for in-drive usage |
| Saved routes + routines | "Every morning commute, show me coffee" |

---

## 6. Monetization

### Recommended: Freemium + promoted listings

| Tier | Price | What you get |
|---|---|---|
| **Free** | $0 | 5 searches/day, routes up to 100 miles |
| **Pro** | $4.99/mo or $29.99/yr | Unlimited searches, 500-mile routes, multi-stop, corridor memory |
| **Search packs** | $0.99 / 10 searches | For occasional users |

### Revenue timeline

| Phase | Users | Revenue model | Target |
|---|---|---|---|
| 0-10K | Free, no ads | Validate PMF | $0 (API cost ~$500-1K/mo) |
| 10K-100K | Freemium + promoted listings ($2-5 CPM) | First revenue | $5-15K/mo |
| 100K+ | + affiliate commissions + data licensing | Scale | $50-200K/mo |

### Realistic scale

Likely a **$750K-$3M ARR indie/bootstrapped business** (500K-2M addressable users, 5% conversion at $30/yr). Venture-scale requires finding a fintech or data wedge (GasBuddy's playbook: utility -> payments -> data licensing).

---

## 7. Growth Strategy

### First 1,000 users

**Pre-launch (weeks 1-4):**
- Waitlist landing page: "Google Maps shows you what's nearby. We show you what's worth the detour."
- Seed Reddit threads in r/roadtrip, r/GoogleMaps, r/electricvehicles
- 30-second demo video on Twitter/X and TikTok

**Launch (week 5):**
- Product Hunt (Tuesday, target Product of the Day)
- Hacker News "Show HN" — lead with technical angle
- Email waitlist

**Post-launch (weeks 6-12):**
- SEO: auto-generate "Best stops between [City A] and [City B]" pages for top 50 corridors
- EV community: "Find food near your charger" hook
- Commuter corridor campaigns: geo-targeted in cities with long commutes (Toronto, LA, Houston)
- Referral: "Share a route, both get 10 free Pro searches"

**Targets:** 500 downloads at launch -> 1,000 by week 8 -> 2,500 by week 12 -> first 50 paying subscribers

---

## 8. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **Google ships a better version** | HIGH | Their ad model conflicts with detour-minimization. Build corridor memory + multi-stop. |
| **API costs eat margins** | HIGH | Cache aggressively. Migrate to TomTom at scale. Self-host Valhalla. |
| **"Feature not product" risk** | HIGH | Corridor memory, multi-stop, local-first create defensibility. |
| **Low retention** | MEDIUM | Target daily commuters (5x/week), not road trippers (2-3x/year). |
| **FastFork expands beyond food** | MEDIUM | Ship general-purpose first. First-mover in broader category. |

### Startup graveyard warning

~300 travel planning startups have failed since 2005. Common patterns:
- Infrequent use kills retention (2-3x/year travel)
- Google adds the feature natively (Field Trip, OnTheWay, Alongways)
- Acqui-kill (Nokia killed Desti + Dopplr, SAP killed Hipmunk, Bending Spoons gutted Komoot)

**Why this is different:**
1. Daily commuters use it 5x/week, not 2-3x/year
2. Detour-time ranking conflicts with Google's ad model
3. Corridor memory creates switching cost
4. API costs low enough for solo dev ($0 during dev, ~$500/mo at 1K DAU)

---

## 9. Build Timeline (iOS MVP)

| Week | Milestone |
|---|---|
| 1-2 | SwiftUI project, MapKit integration, route input UI |
| 3-4 | Backend: Vercel Functions + Google Routes/Places SAR |
| 5-6 | Results: route polyline + POI annotations with "+X min" badges |
| 7-8 | Max-detour slider, forward-only filter, category buttons |
| 9-10 | Navigation handoff, error states, edge cases |
| 11-12 | Landing page, TestFlight beta (50 Toronto commuters) |
| 13 | App Store submission |
| 14+ | Launch. Begin Android if traction validates. |

**Cost to launch: ~$120** (Apple Dev $99 + domain ~$20. APIs and hosting free tier.)

---

## 10. Validation Strategy

Test with Toronto commuters on one corridor (e.g., Scarborough -> Downtown via 401/DVP):

1. Pre-populate 50-100 coffee/food spots with detour times
2. TestFlight beta with 50 daily commuters
3. Success metrics:
   - App opens 3+ times/week?
   - Users actually stop at suggested places?
   - Top searched categories?
   - Would they pay $4.99/mo?

If week-4 retention is <20%, rethink before investing in Android.
