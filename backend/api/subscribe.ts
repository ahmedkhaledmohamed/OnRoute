import type { VercelRequest, VercelResponse } from "@vercel/node";

interface SubscribeRequest {
  email: string;
  anonymousId?: string;
  platform?: string;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const body = req.body as SubscribeRequest;

  if (!body.email || !body.email.includes("@")) {
    return res.status(400).json({ error: "Valid email required" });
  }

  const email = body.email.toLowerCase().trim();

  console.log(
    `IN_APP_SUBSCRIBE: email=${email} platform=${body.platform || "unknown"} id=${body.anonymousId || "unknown"} at=${new Date().toISOString()}`
  );

  return res.status(200).json({ ok: true });
}
