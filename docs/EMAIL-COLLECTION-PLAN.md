# Email Collection — Implementation Plan

## When to build
After 20+ anonymous installs from Reddit/HN — when you have users you can't reach directly.

## UX: Optional prompt after first search

```
User opens app → searches for first time → results appear → 
after 3 seconds, a bottom sheet slides up:

┌─────────────────────────────────────┐
│  Get updates on OnRoute?            │
│                                     │
│  We'll let you know about new       │
│  features and improvements.         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  your@email.com             │    │
│  └─────────────────────────────┘    │
│                                     │
│  [ Subscribe ]         [ No thanks ]│
└─────────────────────────────────────┘
```

- Appears ONCE after first successful search (not on app open — let them see value first)
- Dismissible — "No thanks" hides it permanently
- No login, no account, no password
- Stored flag: `hasSeenEmailPrompt` in UserDefaults / DataStore

## Backend: Simple email endpoint

### New endpoint: `POST /api/subscribe`

```typescript
// Request
{ "email": "user@example.com" }

// Response
{ "ok": true }
```

- Validate email format
- Store in Supabase `subscribers` table (or start with just logging to Vercel function logs + a JSON file in KV)
- Rate limit: 5 per IP per hour
- No double-opt-in needed for beta (add later for GDPR/CAN-SPAM compliance at scale)

### Simplest viable storage: Vercel KV or just logs

**Option A (zero infra): Log to Vercel function logs**
```typescript
console.log(`EMAIL_SUBSCRIBE: ${email} at ${new Date().toISOString()}`);
```
Retrieve with `vercel logs --output json | grep EMAIL_SUBSCRIBE`. Good for <100 signups.

**Option B (proper): Supabase**
```sql
CREATE TABLE subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  source text DEFAULT 'app'  -- 'app' or 'landing'
);
```
Free tier handles 50K rows. Can query, export, and build on top of it later.

**Recommendation:** Start with Option A (logs). Move to Supabase when you hit 50+ subscribers.

## Files to create/modify

### Backend
- `backend/api/subscribe.ts` — new endpoint, validates email, logs/stores it

### iOS
- `ios/Detour/Views/EmailPromptSheet.swift` — new view, text field + subscribe/dismiss buttons
- `ios/Detour/Views/ContentView.swift` — show sheet after first search, gate on `hasSeenEmailPrompt` in @AppStorage
- `ios/Detour/Services/APIService.swift` — add `subscribe(email:)` function

### Android
- `android/.../ui/component/EmailPromptSheet.kt` — new composable
- `android/.../ui/screen/MainScreen.kt` — show after first search, gate on DataStore flag
- `android/.../service/ApiService.kt` — add subscribe endpoint

### Landing page
- Already has a waitlist form — wire it to the same `POST /api/subscribe` endpoint instead of the current `/api/waitlist`

## Privacy policy update
Add to privacy.html:
- "If you choose to subscribe, we store your email address to send product updates. You can unsubscribe at any time by emailing us."

## Estimated effort
- Backend endpoint: 15 min
- iOS prompt: 30 min
- Android prompt: 30 min
- Total: ~1.5 hours

## What this enables later
- Email users when you launch on App Store / Play Store
- Send a "what do you think?" survey after 1 week
- Announce new features to engaged users
- Segment by city (if you add a city field later)
