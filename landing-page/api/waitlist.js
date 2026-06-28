import { put, list } from "@vercel/blob";

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();

  // GET: return all signups (for admin use)
  if (req.method === "GET") {
    try {
      const { blobs } = await list({ prefix: "waitlist/" });
      const emails = blobs.map((b) => ({
        email: b.pathname.replace("waitlist/", ""),
        signedUpAt: b.uploadedAt,
      }));
      return res.status(200).json({ count: emails.length, emails });
    } catch {
      return res.status(200).json({ count: 0, emails: [] });
    }
  }

  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { email } = req.body || {};
  if (!email || !email.includes("@")) {
    return res.status(400).json({ error: "Valid email required" });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    await put(`waitlist/${normalizedEmail}`, JSON.stringify({
      email: normalizedEmail,
      source: req.headers.referer || "direct",
      signedUpAt: new Date().toISOString(),
    }), {
      access: "public",
      addRandomSuffix: false,
    });
  } catch (err) {
    // Fall back to logging if Blob store isn't configured
    console.log(`WAITLIST_SIGNUP: ${normalizedEmail} at ${new Date().toISOString()}`);
  }

  return res.status(200).json({ ok: true });
}
