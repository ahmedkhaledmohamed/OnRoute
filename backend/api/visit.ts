import type { VercelRequest, VercelResponse } from "@vercel/node";
import { neon } from "@neondatabase/serverless";

const sql = neon(process.env.DATABASE_URL!);

async function ensureTable() {
  await sql`
    CREATE TABLE IF NOT EXISTS visits (
      id SERIAL PRIMARY KEY,
      anonymous_id TEXT NOT NULL,
      place_id TEXT NOT NULL,
      place_name TEXT,
      lat DOUBLE PRECISION,
      lng DOUBLE PRECISION,
      corridor_key TEXT,
      visited_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(anonymous_id, place_id)
    )
  `;
  await sql`
    CREATE INDEX IF NOT EXISTS idx_visits_user_corridor
    ON visits(anonymous_id, corridor_key)
  `;
}

let tableReady = false;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Anonymous-Id");

  if (req.method === "OPTIONS") return res.status(200).end();

  if (!process.env.DATABASE_URL) {
    return res.status(500).json({ error: "Database not configured" });
  }

  if (!tableReady) {
    await ensureTable();
    tableReady = true;
  }

  const anonymousId = req.headers["x-anonymous-id"] as string;
  if (!anonymousId) {
    return res.status(400).json({ error: "X-Anonymous-Id header required" });
  }

  if (req.method === "POST") {
    const { placeId, placeName, lat, lng, originLat, originLng, destLat, destLng } = req.body || {};

    if (!placeId) {
      return res.status(400).json({ error: "placeId required" });
    }

    const corridorKey = makeCorridorKey(originLat, originLng, destLat, destLng);

    await sql`
      INSERT INTO visits (anonymous_id, place_id, place_name, lat, lng, corridor_key)
      VALUES (${anonymousId}, ${placeId}, ${placeName || null}, ${lat || null}, ${lng || null}, ${corridorKey || null})
      ON CONFLICT (anonymous_id, place_id) DO UPDATE SET visited_at = NOW()
    `;

    return res.status(200).json({ ok: true });
  }

  if (req.method === "GET") {
    const corridorKey = req.query.corridor as string;
    const placeIds = req.query.placeIds as string;

    if (placeIds) {
      const ids = placeIds.split(",");
      const rows = await sql`
        SELECT place_id, visited_at FROM visits
        WHERE anonymous_id = ${anonymousId} AND place_id = ANY(${ids})
      `;
      const visitMap: Record<string, string> = {};
      for (const row of rows) {
        visitMap[row.place_id] = row.visited_at;
      }
      return res.status(200).json({ visits: visitMap });
    }

    if (corridorKey) {
      const rows = await sql`
        SELECT place_id, place_name, lat, lng, visited_at FROM visits
        WHERE anonymous_id = ${anonymousId} AND corridor_key = ${corridorKey}
        ORDER BY visited_at DESC
        LIMIT 50
      `;
      return res.status(200).json({ visits: rows });
    }

    return res.status(400).json({ error: "placeIds or corridor query param required" });
  }

  return res.status(405).json({ error: "Method not allowed" });
}

function makeCorridorKey(oLat?: number, oLng?: number, dLat?: number, dLng?: number): string | null {
  if (!oLat || !oLng || !dLat || !dLng) return null;
  return `${oLat.toFixed(2)},${oLng.toFixed(2)}|${dLat.toFixed(2)},${dLng.toFixed(2)}`;
}
