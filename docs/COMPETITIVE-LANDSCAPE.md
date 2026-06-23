# Competitive Landscape

*June 2026 — Deep analysis of every app that touches "search along route"*

---

## Direct Competitors

### FastFork — Find Food On Route
- **What:** Purpose-built to find restaurants along your driving route. Shows detour *distance* per result. 18 cuisine filters, drive-thru filter, EV charging integration.
- **Status:** iOS only, 5 ratings (5.0 stars), launched April 2025. Very early.
- **Pricing:** Free (5 searches/day, 100-mile max). Pro: $4.99/mo or $39.99/yr.
- **Gap:** Food only. Detour distance, not time. No general POI. Foursquare data (less comprehensive than Google).
- **Verdict:** Closest direct competitor. Validates the "ranked by detour" UX while leaving the broader market open.

### On The Way / By The Ways
- **What:** Discover attractions along route. Filters by actual detour time (10/20/30 min driving).
- **Status:** Small user base. German startup, government-backed. Won TIC & VIR Travel Start-up Night 2021.
- **Gap:** Europe-focused, tourism/attractions only, not daily commuter use.
- **Verdict:** Validates detour-time filtering as a concept but targets tourists.

### Along the Way
- **What:** iPhone road trip app. Route-aware search for Food, Popular, Sights, Shopping, Nightlife via Foursquare.
- **Status:** Last updated ~2014. iOS 4.0+ requirement listed. 1 rating. Effectively dead.
- **Gap:** No detour time shown. Abandoned.

### iExit Interstate Exit Guide
- **What:** Shows what's at every upcoming interstate exit — gas (with prices), food (with Yelp ratings), hotels, rest stops. Search next 100 exits.
- **Status:** 3M+ downloads, 350K+ pitstop decisions/month. Active, CarPlay support.
- **Pricing:** Free with ads. $2 removes ads.
- **Gap:** Interstate highways only. Exit-based, not arbitrary route. No detour-time ranking.

### Roadtrippers
- **What:** Road trip planner with 30M+ POIs. Configurable distance corridor (0-50 miles from route). AI "Autopilot" itinerary.
- **Status:** $19.4M ARR. Acquired by Roadpass Digital (Thor Industries) in 2023.
- **Pricing:** Free (7 stops), Basic $35.99/yr, Pro $49.99/yr, Premium $59.99/yr.
- **Gap:** No detour TIME ranking (distance only). Planning tool, not real-time. Aggressive paywall. Outdated business data.

### Wanderlog
- **What:** Collaborative trip planner. Route optimization for up to 15 places/day. Web-scraped travel blog recommendations.
- **Status:** 1.5M+ monthly users, 10M trips/year. Y Combinator alumni.
- **Pricing:** Free (unlimited stops). Pro $39.99/yr.
- **Gap:** Not corridor-aware. Good for "things to do in Austin" but weak for "things between Dallas and Austin."

---

## Major Platform Features

### Google Maps — "Search Along Route"

**What it does:** During navigation, tap search icon for categories (gas, restaurants, coffee, grocery) or free-text. Shows detour time per result ("+5 min" or "Quick detour"). API supports Search Along Route with routing summaries.

**What's good:**
- Largest POI database (200M+ places, 50M+ daily updates)
- Shows detour time per result
- New filters: "near me," "midway," "near destination"
- API supports full detour calculation in 2 calls

**What's broken:**
- No sorting by detour time — results appear geographically
- No max-detour filter
- Results cluster near origin/destination, mid-route is sparse
- New card-based UI removes map pin visualization (users hate this)
- One category at a time
- Max 10 stops
- Feature disappears for some users across app versions

### Apple Maps

**What it does:** "Add Stop" during navigation. Preset categories: Gas, Coffee, Dining, Banks & ATMs, Parking. iOS 26 adds natural language search.

**What's broken:**
- No route-aware search at all — searches near current location, not along route
- No detour time shown
- Only 3-5 preset categories
- No free-text route-aware search
- Poor rural coverage (results 15-25 min off route)

### Waze

**What it does:** Preset categories (Gas, Food, Parking, Groceries) during navigation. Shows gas prices. Community-sourced real-time data.

**What's broken:**
- Only 1 intermediate stop
- No free-text search — categories only
- Results include places behind you
- No detour time shown consistently
- No pre-trip planning

**UserVoice requests (26+ votes):**
- "Search along my route" with category + time parameters + route deviation options
- "Sort by miles added by deviation"
- "Show how much time it adds before I select it"

### TomTom (API only, not consumer app)

**What it does right:**
- Along Route Search API with `maxDetourTime` parameter (up to 3600s)
- Default sort by `detourTime` (seconds)
- Also sorts by `detourDistance` and `detourOffset`
- Returns negative detour times when the stop is on a faster route

**Gap:** Developer API only, no consumer-facing product.

### HERE WeGo

**What it does:** "Along your route" search for Gas, Parking, Restaurants, Toilets. Multi-stop trip planning.
**Gap:** Limited consumer adoption. No detour time shown.

---

## Category-Specific Apps

### GasBuddy
- Route-aware gas station search with community-updated prices
- 100M+ downloads, 12M MAU
- Monetizes via Pay with GasBuddy card (transaction fees), Premium ($9.99/mo), ads, data licensing
- Gap: Gas only. No detour time shown.

### A Better Route Planner (ABRP)
- EV route planning with charging stops optimized for battery/temp/elevation
- Up to 9 route alternatives with charger reliability indicators
- Proves "search along route with detour awareness" works when focused on a vertical

### PlugShare
- EV charger discovery along route with "Show Along Route Only" toggle
- Photos, reviews, real-time availability, connector types
- Configurable distance-from-route filter

---

## Failed Attempts (Graveyard)

| App | Died | What happened | Lesson |
|---|---|---|---|
| **Field Trip** (Niantic/Google) | 2019 | GPS-triggered POI narration from 130+ sources. Niantic pivoted to Pokemon Go. | POI discovery less lucrative than gaming. |
| **RoadNinja** (Lamar Advertising) | ~2016 | Interstate exit guide, 1M+ downloads, McDonald's/Shell promos. Parent is a billboard company. | Non-tech parent can't sustain app investment. |
| **OnTheWay** (TeachStreet) | ~2013 | Web app: start/destination, see routes with diners/coffee/gas. One-week side project. TeachStreet acquired by Amazon. | Side projects die when main company sells. |
| **Alongways** | ~2016 | Android (Amazon Appstore only). Route + search query, places along route. | Limited distribution = death. |
| **Scout GPS** (Telenav) | Oct 2023 | Free nav with social features. Ford/Toyota partnerships. | Google Maps/Waze saturation killed standalone nav. |
| **Desti** (SRI International) | Sept 2014 | AI trip planning with NL search. Acquired by Nokia/HERE. Killed 90 days later. | Acqui-kill. |
| **Google Trips** | Aug 2019 | Standalone trip planning. Google consolidated into Maps. | Big company kills standalone when it can bundle. |
| **Hipmunk** | Jan 2020 | Travel search. Acquired by SAP Concur. Consumer product killed. | Acqui-kill. |
| **Tripnotes** | Dec 2023 | ChatGPT-powered trip planner. 1M users in 45 days. Couldn't raise post-SVB. | AI hype != sustainable funding. |
| **Campendium** | Early 2024 | Campground discovery with route search. Killed by Roadpass (Thor Industries). | Consolidated into Roadtrippers. |

**Pattern:** ~300 travel planning startups failed since 2005 — the highest failure rate of any travel vertical. Structural causes: infrequent use, Google platform risk, monetization difficulty, acquisition graveyard.

---

## Summary Matrix

| App | POI Types | Detour Time? | Detour Sort? | Max-Detour Filter? | Daily + Trip? | Platform | Price |
|---|---|---|---|---|---|---|---|
| Google Maps | ~5 quick + free text | Shown | No | No | Both | All | Free |
| Apple Maps | 3-5 categories | No | No | No | Both | iOS | Free |
| Waze | Gas, food, parking | Partial | No | No | Daily | All | Free |
| FastFork | 18 food categories | Distance only | Sort | No | Both | iOS | $5/mo |
| Roadtrippers | 30M+ POIs | No | No | Distance only | Trip only | All | $36-60/yr |
| On The Way | Attractions | Yes (filter) | No | Yes (time) | Trip only | iOS/Android | $5/mo |
| iExit | Exit amenities | No | No | No | Daily (highway) | All | $2 |
| **Detour** | **All categories** | **Yes (primary)** | **Yes (default)** | **Yes (time slider)** | **Both** | **iOS first** | **Freemium** |

---

## Key Differentiation Opportunities

1. **Detour time as the primary UX** — no app makes "+X minutes" the universal ranking
2. **Max-detour slider** — the single most-requested feature across Waze and Google forums
3. **All categories, one app** — today users combine GasBuddy + FastFork + Roadtrippers
4. **Forward-only results** — Waze users specifically complain about results behind them
5. **Cross-platform from Android launch** — FastFork, Along the Way, On The Way are all iOS-only
6. **Quick-stop signals** — drive-thru vs sit-down, restroom quality, wait time estimates
