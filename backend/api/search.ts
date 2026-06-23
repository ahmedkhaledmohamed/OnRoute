import type { VercelRequest, VercelResponse } from "@vercel/node";

interface SearchRequest {
  origin: { lat: number; lng: number };
  destination: { lat: number; lng: number };
  query: string;
  maxDetourMinutes?: number;
  openNow?: boolean;
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

const API_KEY = process.env.GOOGLE_MAPS_API_KEY;

async function computeRoute(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number }
): Promise<{ encodedPolyline: string; durationSeconds: number; distanceMeters: number }> {
  const response = await fetch(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    {
      method: "POST",
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
        travelMode: "DRIVE",
        routingPreference: "TRAFFIC_AWARE",
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
    durationSeconds: parseInt(route.duration.replace("s", ""), 10),
    distanceMeters: route.distanceMeters,
  };
}

async function searchAlongRoute(
  encodedPolyline: string,
  query: string,
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  openNow: boolean
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

  const body: Record<string, unknown> = {
    textQuery: query,
    searchAlongRouteParameters: {
      polyline: { encodedPolyline },
    },
    routingParameters: {
      origin: {
        location: {
          latLng: { latitude: origin.lat, longitude: origin.lng },
        },
      },
      destination: {
        location: {
          latLng: { latitude: destination.lat, longitude: destination.lng },
        },
      },
      travelMode: "DRIVE",
    },
  };

  if (openNow) {
    body.openNow = true;
  }

  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchText",
    {
      method: "POST",
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
        detourSeconds += parseInt(String(leg.duration).replace("s", ""), 10);
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

function formatDetour(seconds: number): string {
  const minutes = Math.round(seconds / 60);
  if (minutes < 1) return "+<1 min";
  return `+${minutes} min`;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  if (!API_KEY) {
    return res.status(500).json({ error: "GOOGLE_MAPS_API_KEY not configured" });
  }

  const body = req.body as SearchRequest;

  if (!body.origin || !body.destination || !body.query) {
    return res.status(400).json({
      error: "Missing required fields: origin, destination, query",
    });
  }

  try {
    const route = await computeRoute(body.origin, body.destination);

    let results = await searchAlongRoute(
      route.encodedPolyline,
      body.query,
      body.origin,
      body.destination,
      body.openNow !== false
    );

    // Recalculate detour as difference from direct route
    for (const result of results) {
      if (result.detourSeconds > 0) {
        const actualDetour = result.detourSeconds - route.durationSeconds;
        result.detourSeconds = Math.max(0, actualDetour);
        result.detourFormatted = formatDetour(result.detourSeconds);
      }
    }

    if (body.maxDetourMinutes) {
      const maxSeconds = body.maxDetourMinutes * 60;
      results = results.filter((r) => r.detourSeconds <= maxSeconds);
    }

    results.sort((a, b) => a.detourSeconds - b.detourSeconds);

    const response: SearchResponse = {
      results,
      route,
    };

    return res.status(200).json(response);
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown error";
    return res.status(500).json({ error: message });
  }
}
