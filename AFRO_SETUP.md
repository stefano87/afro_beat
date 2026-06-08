# Afro Beat Trap Instrumental — Setup

Flutter rebuild of [Afro Beat Trap Instrumental](https://play.google.com/store/apps/details?id=com.andromo.dev127586.app1066667), cloned from `flutter_app` (Hip Hop).

## Package ID (Play Store update)

`com.andromo.dev127586.app1066667` — same listing as the existing Andromo app.

## What you need to provide

### 1. Free beats CDN
Edit `lib/config/app_config.dart`:
- `beatsCdnBaseUrl` — folder with `beat.mp3`, `beat1.mp3`, …
- `freeBeatCount` — number of numbered beats (e.g. `250`)

### 2. Radio stations
Edit `lib/data/radio_stations_data.dart` + add artwork under `assets/stations/`.

### 3. Premium beats (optional, when Store is ready)
- Upload MP3s to `premiumCdnBaseUrl` (`afrobeats1.mp3`, `afrotrap1.mp3`, …)
- Create Play products: `beat_pack_afrobeats`, `beat_pack_afrotrap`, `beat_pack_afropop`, `beat_pack_full`
- Set `kEnablePremiumStore = true` in `lib/config/feature_flags.dart`

### 4. Branding assets
Replace under `assets/`:
- `logo.webp`, `app_icon.png`, background image
- Run: `flutter pub run flutter_launcher_icons`

### 5. Firebase
Add Android app `com.andromo.dev127586.app1066667` to your Firebase project → download new `google-services.json` → `android/app/`.

### 6. AdMob
Create dedicated ad units for this app (do not reuse Hip Hop units in production). Update `AppConfig.admob*` in `app_config.dart` + `AndroidManifest.xml`.

### 7. Signing
Copy `android/key.properties` + keystore from Hip Hop project (or create new) for release builds.

## Build

```powershell
cd c:\Users\Stefano\hiphopApp\afrobeat_app
flutter pub get
flutter build appbundle --release
```

## Project layout

| Path | Purpose |
|------|---------|
| `lib/config/app_config.dart` | **Main config** — URLs, titles, keys, AdMob |
| `lib/data/beats_data.dart` | Free beat list |
| `lib/data/radio_stations_data.dart` | Radio streams |
| `lib/data/premium_beats_data.dart` | IAP packs (when enabled) |
