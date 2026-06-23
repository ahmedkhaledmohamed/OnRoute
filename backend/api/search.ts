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
}

interface SearchResponse {
  results: POIResult[];
  route: {
    encodedPolyline: string;
    durationSeconds: number;
    distanceMeters: number;
  };
}

const MOCK_RESULTS: POIResult[] = [
  {
    placeId: "mock_1",
    name: "Balzac's Coffee Roasters",
    address: "1 Distillery Lane, Toronto, ON",
    lat: 43.6503,
    lng: -79.3596,
    detourSeconds: 120,
    detourFormatted: "+2 min",
    rating: 4.5,
    userRatingCount: 342,
    isOpenNow: true,
    types: ["cafe", "coffee"],
  },
  {
    placeId: "mock_2",
    name: "Pilot Coffee Roasters",
    address: "65 Front St E, Toronto, ON",
    lat: 43.6489,
    lng: -79.3725,
    detourSeconds: 180,
    detourFormatted: "+3 min",
    rating: 4.6,
    userRatingCount: 518,
    isOpenNow: true,
    types: ["cafe", "coffee"],
  },
  {
    placeId: "mock_3",
    name: "Tim Hortons",
    address: "200 University Ave, Toronto, ON",
    lat: 43.6508,
    lng: -79.3886,
    detourSeconds: 420,
    detourFormatted: "+7 min",
    rating: 3.8,
    userRatingCount: 1205,
    isOpenNow: true,
    types: ["cafe", "coffee", "fast_food"],
  },
];

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const body = req.body as SearchRequest;

  if (!body.origin || !body.destination || !body.query) {
    return res.status(400).json({
      error: "Missing required fields: origin, destination, query",
    });
  }

  let results = [...MOCK_RESULTS];

  if (body.maxDetourMinutes) {
    const maxSeconds = body.maxDetourMinutes * 60;
    results = results.filter((r) => r.detourSeconds <= maxSeconds);
  }

  if (body.openNow !== false) {
    results = results.filter((r) => r.isOpenNow);
  }

  results.sort((a, b) => a.detourSeconds - b.detourSeconds);

  const response: SearchResponse = {
    results,
    route: {
      encodedPolyline: "mock_polyline",
      durationSeconds: 2700,
      distanceMeters: 38000,
    },
  };

  return res.status(200).json(response);
}
