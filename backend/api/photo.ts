import type { VercelRequest, VercelResponse } from "@vercel/node";

const API_KEY = process.env.GOOGLE_MAPS_API_KEY;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "GET") return res.status(405).json({ error: "Method not allowed" });

  const ref = req.query.ref as string;
  const maxWidth = parseInt(req.query.maxWidth as string) || 200;

  if (!ref) {
    return res.status(400).json({ error: "ref parameter required" });
  }

  if (!API_KEY) {
    return res.status(500).json({ error: "Server configuration error" });
  }

  try {
    const response = await fetch(
      `https://places.googleapis.com/v1/${ref}/media?maxWidthPx=${maxWidth}&key=${API_KEY}`,
      { signal: AbortSignal.timeout(10000) }
    );

    if (!response.ok) {
      return res.status(response.status).json({ error: "Photo not available" });
    }

    const contentType = response.headers.get("content-type") || "image/jpeg";
    const buffer = Buffer.from(await response.arrayBuffer());

    res.setHeader("Content-Type", contentType);
    res.setHeader("Cache-Control", "public, max-age=2592000, immutable");
    return res.status(200).send(buffer);
  } catch {
    return res.status(500).json({ error: "Failed to fetch photo" });
  }
}
