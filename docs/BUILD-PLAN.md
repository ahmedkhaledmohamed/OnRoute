# Build Plan — Detour iOS MVP

Each step below is a self-contained prompt designed to be executed sequentially. Every prompt produces a working, committable increment.

---

## Step 1: Xcode Project + MapKit Scaffold

**Branch:** `feat/project-setup`

Set up the Xcode project for the Detour iOS app in the `ios/` directory of this repo (github.com/ahmedkhaledmohamed/detour).

Requirements:
- Create an Xcode project named "Detour" targeting iOS 17+ using SwiftUI
- Bundle ID: `com.ahmedkhaled.detour`
- Add a basic `ContentView` with a full-screen `Map` (MapKit) centered on Toronto (43.6532, -79.3832)
- Set up the project structure:
  - `Detour/Views/` — SwiftUI views
  - `Detour/Models/` — data models
  - `Detour/Services/` — API clients
  - `Detour/ViewModels/` — view models
- Add a `.gitignore` for Xcode/Swift projects
- The app should build and show a map on launch
- Open a PR to main with the changes

---

## Step 2: Route Input UI

**Branch:** `feat/route-input`

Add route input to the Detour iOS app (`ios/` directory). The app currently shows a full-screen map.

Requirements:
- Add a bottom sheet (`.sheet` or custom) with two text fields: "From" and "To"
- Both fields should use `MKLocalSearchCompleter` for address autocomplete as the user types
- Show autocomplete suggestions in a list below each field
- When both origin and destination are selected, store them as `CLLocationCoordinate2D` in a shared view model
- Add a "Search" button that becomes active when both fields are filled
- For now, tapping Search just prints the coordinates — route rendering comes in Step 3
- Add a "Current Location" quick-fill button for the "From" field using `CLLocationManager`
- The bottom sheet should be draggable and have a compact collapsed state showing just the two fields
- Open a PR to main

---

## Step 3: Route Rendering on Map

**Branch:** `feat/route-display`

Add route calculation and rendering to the Detour iOS app. The app currently has a map + route input UI with origin/destination selection.

Requirements:
- When the user taps "Search" with valid origin + destination, calculate a driving route using `MKDirections`
- Render the route as a polyline overlay on the map (blue, 5pt stroke)
- Auto-zoom the map to fit the entire route with padding
- Show total drive time and distance in a small pill at the top of the map (e.g., "45 min · 38 km")
- Store the route's polyline coordinates in the view model — the backend will need them later
- Handle errors (no route found, network failure) with a simple alert
- If the user changes origin/destination and searches again, clear the old route and draw the new one
- Open a PR to main

---

## Step 4: Backend — Vercel Functions Setup

**Branch:** `feat/backend-setup`

Set up the backend for the Detour app in the `backend/` directory of this repo (github.com/ahmedkhaledmohamed/detour). The backend is a Vercel Functions project that the iOS app will call.

Requirements:
- Initialize a Node.js project in `backend/` with TypeScript
- Set up Vercel Functions structure (`api/` directory)
- Create a health check endpoint: `GET /api/health` → `{ status: "ok" }`
- Create a placeholder search endpoint: `POST /api/search` that accepts `{ origin: {lat, lng}, destination: {lat, lng}, query: string }` and returns a mock response with 3 fake POIs, each with `name`, `address`, `lat`, `lng`, `detourMinutes`, `rating`, `isOpenNow`
- Add a `vercel.json` with CORS headers allowing all origins (dev convenience)
- Add a `.env.example` with placeholder for `GOOGLE_MAPS_API_KEY`
- Add a README in `backend/` explaining how to run locally (`vercel dev`)
- Open a PR to main

---

## Step 5: Backend — Google Routes + Places Integration

**Branch:** `feat/backend-search`

Wire up the real Google APIs in the Detour backend (`backend/` directory). The backend currently has a placeholder `POST /api/search` endpoint returning mock data.

Requirements:
- Replace the mock `/api/search` with real API calls:
  1. Call Google Routes API `computeRoutes` with the origin/destination to get an encoded polyline
  2. Call Google Places Text Search (New) with `searchAlongRouteParameters.polyline.encodedPolyline` using the query from the request
  3. Request `routingSummaries` in the field mask to get detour duration per result
  4. Calculate detour time: `(leg1_duration + leg2_duration) - original_route_duration`
  5. Return results sorted by detour time (ascending)
- Response shape per result: `{ placeId, name, address, lat, lng, detourSeconds, detourFormatted ("+3 min"), rating, userRatingCount, isOpenNow, types, photoReference? }`
- Also return the route polyline in the response so the iOS app can render it
- Accept optional parameters: `maxDetourMinutes` (filter), `openNow` (boolean, default true)
- Add proper error handling for API failures
- Read `GOOGLE_MAPS_API_KEY` from environment variables
- Open a PR to main

---

## Step 6: iOS — Connect to Backend + Show Results

**Branch:** `feat/poi-results`

Connect the Detour iOS app to the backend and display POI results. The app currently renders routes locally via MKDirections. The backend (`POST /api/search`) returns POIs ranked by detour time.

Requirements:
- Create an `APIService` in `Services/` that calls the backend's `/api/search` endpoint
- When the user taps "Search," call the backend instead of (or in addition to) local MKDirections
- Use the route polyline from the backend response to render the route on the map
- Display POI results as map annotations:
  - Custom annotation view showing a pin with the detour badge ("+3 min") in a small rounded label
  - Color-code: green for <3 min, yellow for 3-7 min, orange for 7-15 min, red for >15 min
- Display POI results in a scrollable bottom sheet list below the route input:
  - Each row: name, address, rating (stars), detour time badge, "Open"/"Closed" tag
  - Tapping a row in the list highlights/selects the corresponding map annotation and vice versa
- Show a loading spinner while the search is in progress
- Backend URL should be configurable (hardcode for now, note where to change it)
- Open a PR to main

---

## Step 7: Category Quick Buttons + Filters

**Branch:** `feat/filters`

Add category selection and filtering to the Detour iOS app. The app currently shows a search text field, route on map, and POI results ranked by detour time.

Requirements:
- Add a horizontal scroll of category quick buttons between the route input and results:
  - Coffee, Food, Gas, Grocery, Pharmacy, EV Charging
  - Each button has an SF Symbol icon + label
  - Tapping a button sets the search query to that category and triggers a search
  - The free-text field still works for custom queries
- Add a max-detour slider:
  - Range: 1-30 minutes, default 15
  - Position it below the category buttons
  - Label: "Max detour: X min"
  - Changing the slider filters results client-side (no new API call) AND sends the filter to the backend on next search
- Add an "Open now" toggle (on by default)
- When filters change, update the visible results immediately (client-side filter of existing results)
- Open a PR to main

---

## Step 8: Navigation Handoff

**Branch:** `feat/nav-handoff`

Add navigation handoff to the Detour iOS app. When a user finds a place they want to stop at, they need to navigate there via their preferred nav app.

Requirements:
- Add a "Navigate" button on each POI result (both in the list row and the map annotation callout)
- Tapping "Navigate" opens an action sheet with options:
  - "Apple Maps" — opens Apple Maps with the POI as a waypoint between origin and destination
  - "Google Maps" — opens Google Maps via `comgooglemaps://` URL scheme with waypoint
  - "Waze" — opens Waze via `waze://` URL scheme
  - Only show options for apps that are installed (use `UIApplication.shared.canOpenURL`)
- If only one nav app is available, skip the action sheet and open directly
- The deep link should set the POI as an intermediate stop, not replace the destination
- Add a "Copy Address" option as a fallback
- Open a PR to main

---

## Step 9: Polish — Loading, Errors, Empty States

**Branch:** `feat/polish`

Polish the Detour iOS app UX. The app is functionally complete (route input, search, results, filters, navigation handoff) but needs refined states.

Requirements:
- **Loading state:** skeleton shimmer on the results list while searching. Subtle route animation while loading.
- **Empty state:** friendly message when no results match filters ("No places within X minutes of your route. Try increasing the max detour.")
- **Error states:** network error → retry button. Invalid route → "Couldn't find a route between these locations." Backend down → "Search is temporarily unavailable."
- **Forward-only filter:** only show POIs that are ahead of the user's current position on the route (not behind). Use the route polyline to determine which POIs are "forward" based on the user's current location (or the origin if location isn't available).
- **Result count badge:** show "X places found" below the filters
- **Haptic feedback:** light haptic on category button tap, medium on search
- **Accessibility:** VoiceOver labels on all interactive elements, dynamic type support
- Open a PR to main

---

## Step 10: App Icon, Launch Screen, TestFlight Prep

**Branch:** `feat/launch-prep`

Prepare the Detour iOS app for TestFlight distribution.

Requirements:
- **App icon:** Create a simple, distinctive app icon. Use a minimal design — a route line (curved path) with a pin/marker on it, using a bold accent color (suggest deep blue or teal). Generate all required sizes for the asset catalog.
- **Launch screen:** Simple launch screen with the app name "Detour" centered, matching the icon's color scheme. Use a storyboard or SwiftUI launch approach.
- **App metadata:**
  - Display name: "Detour"
  - Version: 1.0.0 (build 1)
  - Category: Navigation
  - Minimum iOS: 17.0
- **Info.plist entries:**
  - Location usage description: "Detour uses your location to find places along your route"
  - Camera/Photos: not needed for v1
- **Scheme configuration:** ensure Release build configuration is set up for archiving
- Remove any hardcoded localhost/dev backend URLs — use a config file or build setting for the backend URL
- Add a basic onboarding: first launch shows a single-screen explainer ("Enter where you're going, pick a category, and find places ranked by how little time they add to your trip") with a "Get Started" button
- Open a PR to main

---

## Execution Notes

- Each step opens a PR. Merge each PR before starting the next step.
- Steps 1-3 (iOS scaffold) and Step 4 (backend scaffold) can run in parallel.
- Step 5 requires a Google Maps API key set as `GOOGLE_MAPS_API_KEY` in Vercel environment variables.
- The backend URL in the iOS app should be updated after Step 4 is deployed to Vercel.
- Step 10 is the last step before TestFlight beta.
