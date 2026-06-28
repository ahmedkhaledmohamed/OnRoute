import type { VercelRequest, VercelResponse } from "@vercel/node";

interface FeedbackRequest {
  anonymousId: string;
  score: number;
  comment?: string;
  platform?: string;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const body = req.body as FeedbackRequest;

  if (!body.anonymousId || typeof body.score !== "number") {
    return res.status(400).json({ error: "anonymousId and score required" });
  }

  console.log(
    `NPS_FEEDBACK: score=${body.score} comment="${body.comment || ""}" platform=${body.platform || "unknown"} id=${body.anonymousId} at=${new Date().toISOString()}`
  );

  return res.status(200).json({ ok: true });
}
