import type { VercelRequest, VercelResponse } from "@vercel/node";

// Rate limiting: per-IP, in-memory (resets on cold start)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_MAX = 20; // requests per window
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }
  entry.count++;
  return entry.count <= RATE_LIMIT_MAX;
}

// CORS: restrict to known origins
const ALLOWED_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:8080",
  "https://onroute-landing.vercel.app",
  "https://getonroute.vercel.app",
];

function getCorsOrigin(req: VercelRequest): string {
  const origin = req.headers.origin || "";
  // Mobile apps send no origin header — allow those
  if (!origin) return "*";
  if (ALLOWED_ORIGINS.includes(origin)) return origin;
  return "";
}

function sanitizeError(message: string): string {
  return message
    .replace(/key=[A-Za-z0-9_-]+/gi, "key=***")
    .replace(/AIza[A-Za-z0-9_-]+/g, "***");
}

const VALID_TRAVEL_MODES = ["DRIVE", "WALK", "BICYCLE"];

interface SearchRequest {
  origin: { lat: number; lng: number };
  destination: { lat: number; lng: number };
  query: string;
  maxDetourMinutes?: number;
  openNow?: boolean;
  travelMode?: "DRIVE" | "WALK" | "BICYCLE";
}

interface POIResult {
  placeId: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  detourSeconds: number;
  detourFormatted: string;
  rating: number;
  userRatingCount: number;
  isOpenNow: boolean;
  types: string[];
  photoReference?: string;
}

interface SearchResponse {
  results: POIResult[];
  route: {
    encodedPolyline: string;
    durationSeconds: number;
    distanceMeters: number;
  };
}

// In-memory cache — survives across requests in the same Vercel function instance
const cache = new Map<string, { data: SearchResponse; timestamp: number }>();
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

function getCacheKey(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  query: string,
  openNow: boolean,
  travelMode: string
): string {
  const oLat = origin.lat.toFixed(3);
  const oLng = origin.lng.toFixed(3);
  const dLat = destination.lat.toFixed(3);
  const dLng = destination.lng.toFixed(3);
  return `${oLat},${oLng}|${dLat},${dLng}|${query.toLowerCase()}|${openNow}|${travelMode}`;
}

function getFromCache(key: string): SearchResponse | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.timestamp > CACHE_TTL_MS) {
    cache.delete(key);
    return null;
  }
  return entry.data;
}

function setCache(key: string, data: SearchResponse): void {
  // Evict old entries if cache grows too large
  if (cache.size > 500) {
    const oldest = cache.keys().next().value;
    if (oldest) cache.delete(oldest);
  }
  cache.set(key, { data, timestamp: Date.now() });
}

const API_KEY = process.env.GOOGLE_MAPS_API_KEY;

async function computeRoute(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  travelMode: string = "DRIVE"
): Promise<{ encodedPolyline: string; durationSeconds: number; distanceMeters: number }> {
  const response = await fetch(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    {
      method: "POST",
      signal: AbortSignal.timeout(10000),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY!,
        "X-Goog-FieldMask":
          "routes.polyline.encodedPolyline,routes.duration,routes.distanceMeters",
      },
      body: JSON.stringify({
        origin: {
          location: { latLng: { latitude: origin.lat, longitude: origin.lng } },
        },
        destination: {
          location: {
            latLng: { latitude: destination.lat, longitude: destination.lng },
          },
        },
        travelMode,
        routingPreference: travelMode === "DRIVE" ? "TRAFFIC_AWARE" : undefined,
      }),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Routes API error: ${response.status} ${error}`);
  }

  const data = await response.json();
  const route = data.routes?.[0];
  if (!route) throw new Error("No route found");

  return {
    encodedPolyline: route.polyline.encodedPolyline,
    durationSeconds: parseDuration(route.duration),
    distanceMeters: route.distanceMeters,
  };
}

async function computeRouteVia(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  poi: { lat: number; lng: number },
  travelMode: string
): Promise<number | null> {
  try {
    const response = await fetch(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
      {
        method: "POST",
        signal: AbortSignal.timeout(8000),
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": API_KEY!,
          "X-Goog-FieldMask": "routes.duration",
        },
        body: JSON.stringify({
          origin: {
            location: { latLng: { latitude: origin.lat, longitude: origin.lng } },
          },
          destination: {
            location: { latLng: { latitude: destination.lat, longitude: destination.lng } },
          },
          intermediates: [
            {
              location: { latLng: { latitude: poi.lat, longitude: poi.lng } },
            },
          ],
          travelMode,
        }),
      }
    );

    if (!response.ok) return null;
    const data = await response.json();
    const route = data.routes?.[0];
    if (!route) return null;
    return parseDuration(route.duration);
  } catch {
    return null;
  }
}

async function recalculateDetours(
  pois: POIResult[],
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  baselineDurationSeconds: number,
  travelMode: string
): Promise<POIResult[]> {
  const results = await Promise.all(
    pois.map(async (poi) => {
      const viaDuration = await computeRouteVia(
        origin, destination,
        { lat: poi.lat, lng: poi.lng },
        travelMode
      );
      if (viaDuration !== null) {
        const detour = Math.max(0, viaDuration - baselineDurationSeconds);
        return { ...poi, detourSeconds: detour, detourFormatted: formatDetour(detour) };
      }
      return poi;
    })
  );
  return results.sort((a, b) => a.detourSeconds - b.detourSeconds);
}

async function searchAlongRoute(
  encodedPolyline: string,
  query: string,
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  openNow: boolean,
  travelMode: string = "DRIVE"
): Promise<POIResult[]> {
  const fieldMask = [
    "places.id",
    "places.displayName",
    "places.formattedAddress",
    "places.location",
    "places.rating",
    "places.userRatingCount",
    "places.currentOpeningHours",
    "places.types",
    "places.photos",
  ].join(",");

  // Bias results toward the route area
  const midLat = (origin.lat + destination.lat) / 2;
  const midLng = (origin.lng + destination.lng) / 2;
  const distKm = Math.sqrt(
    Math.pow((origin.lat - destination.lat) * 111, 2) +
    Math.pow((origin.lng - destination.lng) * 111 * Math.cos(midLat * Math.PI / 180), 2)
  );
  // Radius = half the route distance + 5km buffer, min 10km, max 50km
  const radiusMeters = Math.min(50000, Math.max(10000, (distKm / 2 + 5) * 1000));

  const body: Record<string, unknown> = {
    textQuery: query,
    searchAlongRouteParameters: {
      polyline: { encodedPolyline },
    },
    locationBias: {
      circle: {
        center: { latitude: midLat, longitude: midLng },
        radius: radiusMeters,
      },
    },
    routingParameters: {
      origin: {
        latitude: origin.lat,
        longitude: origin.lng,
      },
      travelMode,
    },
  };

  // Don't send openNow to the API — Google's opening hours data is incomplete
  // in many regions, which causes places without hours data to be excluded entirely.
  // Instead, we return the isOpenNow field per result and let clients filter locally.

  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchText",
    {
      method: "POST",
      signal: AbortSignal.timeout(15000),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY!,
        "X-Goog-FieldMask": fieldMask + ",routingSummaries",
      },
      body: JSON.stringify(body),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Places API error: ${response.status} ${error}`);
  }

  const data = await response.json();
  const places = data.places || [];
  const summaries = data.routingSummaries || [];

  return places.map((place: Record<string, unknown>, i: number) => {
    const summary = summaries[i];
    const legs = summary?.legs || [];

    let detourSeconds = 0;
    for (const leg of legs) {
      if (leg.duration) {
        detourSeconds += parseDuration(leg.duration);
      }
    }

    const location = place.location as { latitude: number; longitude: number } | undefined;
    const displayName = place.displayName as { text: string } | undefined;
    const photos = place.photos as Array<{ name: string }> | undefined;
    const openingHours = place.currentOpeningHours as { openNow?: boolean } | undefined;

    const detourMinutes = Math.round(detourSeconds / 60);
    const detourFormatted =
      detourMinutes < 1 ? "+<1 min" : `+${detourMinutes} min`;

    return {
      placeId: place.id as string,
      name: displayName?.text || "Unknown",
      address: (place.formattedAddress as string) || "",
      lat: location?.latitude || 0,
      lng: location?.longitude || 0,
      detourSeconds,
      detourFormatted,
      rating: (place.rating as number) || 0,
      userRatingCount: (place.userRatingCount as number) || 0,
      isOpenNow: openingHours?.openNow ?? false,
      types: (place.types as string[]) || [],
      photoReference: photos?.[0]?.name,
    };
  });
}

function parseDuration(duration: unknown): number {
  if (typeof duration === "number") return duration;
  if (typeof duration !== "string") return 0;
  const match = duration.match(/(\d+)/);
  return match ? parseInt(match[1], 10) : 0;
}

function formatDetour(seconds: number): string {
  const minutes = Math.round(seconds / 60);
  if (minutes < 1) return "+<1 min";
  return `+${minutes} min`;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS
  const corsOrigin = getCorsOrigin(req);
  res.setHeader("Access-Control-Allow-Origin", corsOrigin || "null");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // Rate limiting
  const ip = (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() || "unknown";
  if (!checkRateLimit(ip)) {
    return res.status(429).json({ error: "Too many requests. Try again in a minute." });
  }

  if (!API_KEY) {
    return res.status(500).json({ error: "Server configuration error" });
  }

  const body = req.body as SearchRequest;

  // Input validation
  if (!body.origin || !body.destination || !body.query) {
    return res.status(400).json({
      error: "Missing required fields: origin, destination, query",
    });
  }

  if (typeof body.origin.lat !== "number" || typeof body.origin.lng !== "number" ||
      typeof body.destination.lat !== "number" || typeof body.destination.lng !== "number") {
    return res.status(400).json({ error: "Coordinates must be numbers" });
  }

  if (body.origin.lat < -90 || body.origin.lat > 90 || body.destination.lat < -90 || body.destination.lat > 90) {
    return res.status(400).json({ error: "Latitude must be between -90 and 90" });
  }

  if (body.origin.lng < -180 || body.origin.lng > 180 || body.destination.lng < -180 || body.destination.lng > 180) {
    return res.status(400).json({ error: "Longitude must be between -180 and 180" });
  }

  if (typeof body.query !== "string" || body.query.trim().length === 0) {
    return res.status(400).json({ error: "Query must be a non-empty string" });
  }

  const openNow = body.openNow !== false;
  const travelMode = VALID_TRAVEL_MODES.includes(body.travelMode || "") ? body.travelMode! : "DRIVE";
  const cacheKey = getCacheKey(body.origin, body.destination, body.query, openNow, travelMode);

  // Check cache first
  const cached = getFromCache(cacheKey);
  if (cached) {
    let results = [...cached.results];
    if (body.maxDetourMinutes) {
      const maxSeconds = body.maxDetourMinutes * 60;
      results = results.filter((r) => r.detourSeconds <= maxSeconds);
    }
    return res.status(200).json({ ...cached, results, cached: true });
  }

  try {
    const route = await computeRoute(body.origin, body.destination, travelMode);

    // Places Search Along Route only supports DRIVE mode
    let results = await searchAlongRoute(
      route.encodedPolyline,
      body.query,
      body.origin,
      body.destination,
      openNow,
      "DRIVE"
    );

    if (travelMode === "WALK" || travelMode === "BICYCLE") {
      // Recalculate detour times using actual walk/bike routing
      results = await recalculateDetours(
        results, body.origin, body.destination,
        route.durationSeconds, travelMode
      );
    } else {
      // DRIVE: use SAR routing summaries directly
      for (const result of results) {
        if (result.detourSeconds > 0) {
          const actualDetour = result.detourSeconds - route.durationSeconds;
          result.detourSeconds = Math.max(0, actualDetour);
          result.detourFormatted = formatDetour(result.detourSeconds);
        }
      }
      results.sort((a, b) => a.detourSeconds - b.detourSeconds);
    }

    const fullResponse: SearchResponse = { results, route };

    // Cache the full unfiltered response
    setCache(cacheKey, fullResponse);

    // Apply maxDetourMinutes filter for this specific request
    if (body.maxDetourMinutes) {
      const maxSeconds = body.maxDetourMinutes * 60;
      results = results.filter((r) => r.detourSeconds <= maxSeconds);
    }

    return res.status(200).json({ results, route, cached: false });
  } catch (error) {
    const raw = error instanceof Error ? error.message : "Unknown error";
    return res.status(500).json({ error: sanitizeError(raw) });
  }
}
