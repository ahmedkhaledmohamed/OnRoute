import type { VercelRequest, VercelResponse } from "@vercel/node";

const POSTHOG_API_KEY = process.env.POSTHOG_API_KEY;
const POSTHOG_HOST = process.env.POSTHOG_HOST || "https://us.i.posthog.com";

interface EventRequest {
  event: string;
  properties?: Record<string, unknown>;
  anonymousId: string;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  if (!POSTHOG_API_KEY) {
    return res.status(500).json({ error: "Analytics not configured" });
  }

  const body = req.body as EventRequest;

  if (!body.event || !body.anonymousId) {
    return res.status(400).json({ error: "event and anonymousId required" });
  }

  try {
    await fetch(`${POSTHOG_HOST}/capture/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        api_key: POSTHOG_API_KEY,
        event: body.event,
        distinct_id: body.anonymousId,
        properties: {
          ...body.properties,
          $lib: "onroute-backend-proxy",
        },
      }),
    });

    return res.status(200).json({ ok: true });
  } catch {
    return res.status(500).json({ error: "Failed to forward event" });
  }
}
