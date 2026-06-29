# Store Submission Guide — OnRoute v1.0.0

## iOS (App Store Connect)

### Prerequisites
- [x] Apple Developer account (ahmed.k.abdelhameed@gmail.com)
- [x] App built and uploaded to TestFlight (build 15)
- [x] Privacy policy live: https://onroute-landing.vercel.app/privacy.html
- [x] Terms of Service live: https://onroute-landing.vercel.app/terms.html
- [x] Export compliance: ITSAppUsesNonExemptEncryption = false
- [x] App icon in asset catalog
- [ ] Screenshots uploaded (see `store-screenshots/` directory)

### Steps

1. **Go to** [App Store Connect](https://appstoreconnect.apple.com)

2. **Create new app:**
   - Platform: iOS
   - Name: `OnRoute`
   - Primary language: English (Canada)
   - Bundle ID: `com.ahmedkhaled.detour`
   - SKU: `onroute-ios`

3. **App Information tab:**
   - Subtitle: `Find stops ranked by detour time`
   - Category: Navigation (primary), Travel (secondary)
   - Content rights: Does not contain third-party content requiring rights
   - Age rating: Fill questionnaire (all "None" — navigation app, no objectionable content)

4. **Pricing and Availability:**
   - Price: Free
   - Availability: All territories

5. **App Privacy tab:**
   - Privacy Policy URL: `https://onroute-landing.vercel.app/privacy.html`
   - Data types collected (see `app-store-connect.json` for full details):
     - Location: When In Use, App Functionality, Not linked
     - Usage Data: Analytics, Not linked, Not tracking
     - Diagnostics: Crash Data, Not linked
     - Contact Info: Email (optional), Marketing, Not linked

6. **Version 1.0.0 page:**
   - Screenshots: Upload from `store-screenshots/` (6.7" iPhone required, 6.1" optional)
   - Description: Copy from `app-store-connect.json`
   - Keywords: `detour,route,stops,coffee,food,gas,commute,navigation,places,along route,driving,trip,nearby`
   - Support URL: `mailto:ahmed.khaled.a.mohamed@gmail.com`
   - Marketing URL: `https://onroute-landing.vercel.app`
   - What's New: Copy from `app-store-connect.json`
   - Build: Select build 15 (or latest)

7. **Submit for Review**
   - Typical review time: 24-48 hours

---

## Android (Google Play Console)

### Prerequisites
- [ ] Google Play developer account ($25 one-time fee): https://play.google.com/console
- [x] Signed release AAB: run `scripts/build-release-aab.sh`
- [x] Privacy policy live
- [x] Terms of Service live
- [ ] Screenshots uploaded

### Steps

1. **Create developer account** at https://play.google.com/console ($25)

2. **Create app:**
   - App name: `OnRoute`
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free

3. **Store listing:**
   - Title: `OnRoute — Find What's Worth the Stop`
   - Short description: Copy from `play-store.json`
   - Full description: Copy from `play-store.json`
   - Screenshots: Upload from `store-screenshots/` (phone required)
   - App icon: 512x512 PNG (use the existing icon)
   - Feature graphic: 1024x500 (optional but recommended)

4. **Content rating:**
   - Fill IARC questionnaire (navigation app, all "No")
   - Expected rating: Everyone

5. **Data Safety:**
   - Follow the structure in `play-store.json` → `dataSafety` section
   - Data collected: Location (optional), App interactions, Crash logs, Email (optional)
   - Data shared with third parties: No
   - Data encrypted in transit: Yes

6. **App signing:**
   - Enroll in Google Play App Signing (recommended)
   - Upload the signed AAB from `android/app/build/outputs/bundle/release/app-release.aab`

7. **API key restriction (Google Cloud Console):**
   - Go to https://console.cloud.google.com/apis/credentials
   - Find the Maps API key used by the Android app
   - Add restriction: Android apps → package `com.ahmedkhaled.onroute`
   - Add SHA-1: `46:75:54:39:F8:90:75:7D:E5:6C:C2:80:02:81:8E:A4:ED:D4:61:9B`

8. **Release:**
   - Start with **Internal testing** track (requires 20 testers, 14-day minimum)
   - Add testers: ahmed.khaled.a.mohamed@gmail.com, youssefhassan13@gmail.com, minazakiz@gmail.com, mina.kleid@atlantic-ventures.com
   - After 14 days: promote to **Production**

### Important: 14-Day Closed Testing Requirement
Google Play requires at least 20 closed testing users who have been active for 14+ days before you can publish to production. **Start this immediately** — it's the longest lead time.

---

## Post-Submission Checklist

- [ ] iOS: Monitor App Store Connect for review status
- [ ] Android: Add 16+ more testers to reach 20 minimum
- [ ] Android: Wait 14 days, then promote to production
- [ ] Update landing page download buttons to point to store listings
- [ ] Announce on social media / Reddit / Slack communities

---

## Quick Commands

```bash
# iOS: Upload to TestFlight
bash scripts/upload-testflight.sh

# Android: Build signed AAB
bash scripts/build-release-aab.sh

# Android: Upload to Firebase (beta)
bash scripts/upload-firebase.sh "Release notes here"

# Backend: Deploy
cd backend && vercel --prod
```
