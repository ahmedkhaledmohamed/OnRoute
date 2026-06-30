import type { VercelRequest, VercelResponse } from "@vercel/node";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { oLat, oLng, dLat, dLng, oName, dName, query, results } = req.query as Record<string, string>;

  if (!oLat || !oLng || !dLat || !dLng) {
    return res.status(400).json({ error: "Missing route coordinates" });
  }

  const originName = oName || "Origin";
  const destName = dName || "Destination";
  const searchQuery = query || "places";
  const resultCount = results || "0";

  const title = `${originName} → ${destName} | OnRoute`;
  const description = `Found ${resultCount} ${searchQuery} stops along this route, ranked by detour time.`;

  const mapUrl = `https://maps.googleapis.com/maps/api/staticmap?size=1200x630&scale=2&maptype=roadmap`
    + `&markers=color:green|label:A|${oLat},${oLng}`
    + `&markers=color:red|label:B|${dLat},${dLng}`
    + `&path=color:0x008DA6ff|weight:4|${oLat},${oLng}|${dLat},${dLng}`
    + `&key=${process.env.GOOGLE_MAPS_API_KEY}`;

  const appStoreUrl = "https://testflight.apple.com/join/jp77yU4e";
  const landingUrl = "https://onroute-landing.vercel.app";

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  <meta property="og:title" content="${escapeHtml(title)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:image" content="${mapUrl}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${landingUrl}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeHtml(title)}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <meta name="twitter:image" content="${mapUrl}">
  <style>
    body { font-family: -apple-system, sans-serif; margin: 0; background: #FAFBFC; color: #1A1A2E; }
    .container { max-width: 600px; margin: 0 auto; padding: 24px; text-align: center; }
    h1 { font-size: 24px; margin-bottom: 8px; }
    .subtitle { color: #6B7280; font-size: 16px; margin-bottom: 24px; }
    .map { width: 100%; border-radius: 16px; margin-bottom: 24px; }
    .badge { display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; background: #1A1A2E; color: white; border-radius: 20px; font-size: 14px; margin-bottom: 16px; }
    .cta { display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #008DA6, #005A80); color: white; border-radius: 12px; text-decoration: none; font-size: 16px; font-weight: 600; }
    .cta:hover { transform: translateY(-1px); }
    .info { margin-top: 24px; font-size: 14px; color: #6B7280; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">OnRoute</div>
    <h1>${escapeHtml(originName)} → ${escapeHtml(destName)}</h1>
    <p class="subtitle">${escapeHtml(description)}</p>
    <img class="map" src="${mapUrl}" alt="Route map">
    <br>
    <a class="cta" href="${landingUrl}">Get OnRoute</a>
    <p class="info">Search for places along your route, ranked by detour time.</p>
  </div>
</body>
</html>`;

  res.setHeader("Content-Type", "text/html");
  res.setHeader("Cache-Control", "public, max-age=86400");
  return res.status(200).send(html);
}

function escapeHtml(str: string): string {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
