# Changelog

## v1.0.0 Build 4 (2026-06-23)

**Latest beta release on both platforms.**

### New Features
- **Travel mode toggle** — switch between Drive, Walk, and Bike for route search
- **A/B/C waypoint markers** — clear Start/Stop/End labels on the map when previewing a detour
- **Detour route preview** — tap any POI to see the full A→B→C orange route on the map
- **"Open in Maps" button** — in the results sheet header when a POI is selected
- **Forward-only filter** — hides places behind you on the route
- **Category quick buttons** — Coffee, Food, Gas, Grocery, Pharmacy, EV Charging
- **Max-detour slider** — filter results by maximum detour time (1-30 min)
- **Open now toggle** — only show places that are currently open
- **Onboarding screen** — first-launch explainer with 3 feature highlights
- **Navigation handoff** — open routes in Google Maps, Apple Maps (iOS), or Waze
- **Feedback button** — email feedback with app version info

### Bug Fixes
- Fixed "Current Location" button race condition (iOS) — was silently failing
- Fixed Google Maps URL double-encoding — addresses no longer show `%20`
- Fixed bike mode using wrong transport type (iOS)
- Fixed Android DirectionsService ignoring travel mode selection
- Added error banner with Retry/Dismiss for failed searches (Android)

### Security & Reliability
- Backend rate limiting: 20 requests/min per IP
- CORS restricted to known origins (no more wildcard `*`)
- Input validation: coordinate ranges, query non-empty, travelMode enum
- API key sanitized from error messages
- Fetch timeouts: 10s (Routes API), 15s (Places API)
- iOS: retry on 5xx/429 errors with 1s delay
- In-memory response caching with 1-hour TTL

### Polish
- Dark mode color improvements for detour badges on both platforms
- iOS: location permission denial shows helpful error message
- Android: location permission checked before accessing GPS
- Android: ProGuard rules for Moshi, Retrofit, Google Play Services
- Android: autocomplete race condition fixed (stale responses ignored)
- Category selection debounced at 300ms on both platforms
- Accessibility labels for VoiceOver (iOS) and TalkBack (Android)
- Android: all UI strings extracted to strings.xml for localization
- Backend: robust duration parsing handles various formats

### Infrastructure
- Landing page: https://onroute-landing.vercel.app
- iOS TestFlight: https://testflight.apple.com/join/jp77yU4e
- Android Firebase: https://console.firebase.google.com/u/0/project/onroute-akm-2026/appdistribution/app/android:com.ahmedkhaled.onroute/releases/7j3c5pr905a70

---

## v1.0.0 Build 2 (2026-06-23)

First TestFlight upload. Basic MVP with route search, POI results, and navigation handoff.

---

## v1.0.0 Build 1 (2026-06-23)

Initial build. App icon and onboarding only.
