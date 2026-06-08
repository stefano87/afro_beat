# Hip Hop Instrumental Beats — Flutter

Migrazione completa dell'app Ionic/Angular in Flutter con layout e funzionalità equivalenti.

## Funzionalità incluse

- **Beat List** — 251 beat, play/pause, preferiti, registrazione voce con countdown
- **Favorites** — beat preferiti persistenti
- **Hip Hop Radio** — 8 stazioni streaming, volume, skip, ads ogni 3 min
- **Community** — form invio brani via EmailJS (accessibile da Info modal)
- **AdMob** — banner + interstitial
- **Firebase Analytics**
- **Privacy & License** — dialog obbligatori al primo avvio
- **Rating popup** — dopo stop playback registrazione

## Prerequisiti

1. **Flutter SDK** installato e funzionante (`flutter doctor`)
2. Android Studio / SDK per build Android

> Nota: sul tuo PC Flutter in `C:\flutter` risulta danneggiato. Reinstallalo da https://docs.flutter.dev/get-started/install/windows

## Setup

```powershell
cd c:\Users\Stefano\hiphopApp\flutter_app

# Genera file mancanti (gradle wrapper, ic_launcher, local.properties)
flutter create . --project-name hip_hop_beats --org hip_hop_beats_instrumental.dev127586

# Installa dipendenze
flutter pub get

# Esegui su dispositivo/emulatore Android
flutter run
```

## Build release

```powershell
flutter build apk --release
```

L'APK sarà in `build/app/outputs/flutter-apk/app-release.apk`.

## Struttura progetto

```
flutter_app/
├── lib/
│   ├── main.dart              # Entry point + Provider setup
│   ├── app.dart               # MaterialApp + bootstrap privacy/ads
│   ├── models/                # Beat, RadioStation
│   ├── data/                  # Liste beat e stazioni radio
│   ├── services/              # Audio, recording, ads, analytics, privacy
│   ├── screens/               # Beat, Favorites, Radio, Community
│   ├── widgets/               # Header, modali, recording panel
│   └── theme/                 # Colori e tema dark (#121212)
├── assets/                    # Logo, background, artwork stazioni
└── android/                   # Config Android (stesso applicationId Ionic)
```

## Application ID

`hip_hop_beats_instrumental.dev127586.app689033` — identico all'app Ionic per aggiornamento Play Store.

## Prossimi passi consigliati

- Background audio per la radio (`audio_service`)
- Mix registrazione + beat con latenza più bassa
- Download offline beat preferiti
- UI polish e animazioni player
