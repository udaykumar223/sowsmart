# 🌾 SowSmart — Weather-Aware Crop Scheduler & Profit Tracker

> **Guidance only.** Agronomic data is labelled `REPLACE WITH VERIFIED DATA`. Always cross-check with your state agricultural university extension office before applying any advice.

---

## 📋 Table of Contents

- [What is SowSmart?](#what-is-sowsmart)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Agronomic Data Sources](#agronomic-data-sources)
- [Setup & Running](#setup--running)
- [Firebase Configuration](#firebase-configuration)
- [Running Tests](#running-tests)
- [Building a Release APK](#building-a-release-apk)

---

## What is SowSmart?

SowSmart is a Flutter mobile app that helps Indian smallholder farmers:

- **Schedule** crop cultivation tasks automatically from a sowing date
- **Get weather advice** (skip irrigation on rainy days, avoid spraying on windy days)
- **Track finances** — seed, labour, fertilizer, pesticide costs vs sale revenue
- **Close harvest cycles** — record yield, calculate net profit and profit-per-acre
- Works fully **offline** (Firestore offline cache + local notifications)
- Supports **English and Telugu (తెలుగు)**

---

## Features

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Foundation — themes, l10n, constants | ✅ |
| 2 | Domain logic — schedule generator, rescheduler, weather advisor, profit calculator | ✅ |
| 3 | Fields & Plantings — CRUD, GPS, live schedule preview | ✅ |
| 4 | Today screen, Calendar (TableCalendar), local notifications | ✅ |
| 5 | Weather advice — Open-Meteo API, offline cache, advice badges | ✅ |
| 6 | Finance & Harvest — transaction log, fl_chart pie chart, harvest closure | ✅ |
| 7 | Polish — full i18n, tightened Firestore rules, README | ✅ |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Screens  (lib/screens/*_screen.dart)               │
│  ↓ context.read / context.watch                     │
├─────────────────────────────────────────────────────┤
│  State    (lib/state/*_state.dart)  ChangeNotifier  │
│  ↓ calls repositories & domain services             │
├────────────────────┬────────────────────────────────┤
│  Domain (pure Dart)│  Repositories (abstract)       │
│  schedule_generator│  firestore_repository.dart      │
│  rescheduler       │  weather_repository.dart        │
│  weather_advisor   │  crop_rules_repository.dart     │
│  profit_calculator │  notification_service.dart      │
├────────────────────┴────────────────────────────────┤
│  Firebase Firestore │ Open-Meteo API │ assets/*.json │
└─────────────────────────────────────────────────────┘
```

**Key rules:**
- Screens **never** call Firestore or HTTP directly
- `lib/domain/` has **zero** Flutter, Firebase, or HTTP imports — 100% pure Dart
- Repositories sit behind abstract interfaces → swapped with fakes in tests
- State managed strictly with `Provider` (`ChangeNotifier` + `ProxyProvider`)
- No Cloud Functions, no custom backend — everything runs client-side

---

## Project Structure

```
lib/
├── core/           app_theme.dart, constants.dart
├── data/           firestore_repository.dart, weather_repository.dart,
│                   crop_rules_repository.dart, notification_service.dart,
│                   prefs_service.dart
├── domain/         schedule_generator.dart, rescheduler.dart,
│                   weather_advisor.dart, profit_calculator.dart
├── l10n/           app_en.arb, app_te.arb  (English + Telugu)
├── models/         field.dart, planting.dart, task_item.dart,
│                   transaction.dart, crop_rule.dart, weather_forecast.dart
├── screens/
│   ├── auth/       login_screen.dart
│   ├── home/       home_screen.dart
│   ├── fields/     fields_screen.dart, add_edit_field_screen.dart
│   ├── plantings/  start_planting_screen.dart, planting_detail_screen.dart,
│   │               harvest_screen.dart
│   ├── today/      today_screen.dart
│   ├── calendar/   calendar_screen.dart
│   ├── finance/    finance_screen.dart, add_transaction_screen.dart
│   └── settings/   settings_screen.dart
├── state/          auth_state.dart, fields_state.dart, plantings_state.dart,
│                   tasks_state.dart, weather_state.dart, finance_state.dart,
│                   settings_state.dart
├── app.dart        GoRouter + MaterialApp.router
└── main.dart       MultiProvider DI wiring

assets/
├── crop_rules.json     Agronomic rules (3 crops — REPLACE WITH VERIFIED DATA)
└── weather_config.json Weather threshold config

test/
├── data/           crop_rules_repository_test.dart, firestore_repository_test.dart,
│                   notification_service_test.dart, weather_repository_test.dart
├── domain/         profit_calculator_test.dart, rescheduler_test.dart,
│                   schedule_generator_test.dart, weather_advisor_test.dart
├── models/         models_serialization_test.dart
├── state/          auth_state_test.dart, settings_state_test.dart,
│                   fields_and_plantings_state_test.dart, tasks_state_test.dart,
│                   weather_state_test.dart, finance_state_test.dart
└── widget_test.dart
```

---

## Agronomic Data Sources

> ⚠️ All values in `assets/crop_rules.json` are **PLACEHOLDER DATA** marked `REPLACE WITH VERIFIED DATA`. Before deploying to real farmers, replace with verified figures from:

| Crop | Recommended Source |
|------|-------------------|
| **Paddy IR 20** | [ICAR-CRRI Variety Bulletin](https://www.crri.nic.in) · State Dept. of Agriculture |
| **Tomato Hybrid** | [ICAR-IIVR Tomato Package of Practices](https://www.iivr.res.in) |
| **Banana Grand Naine** | [ICAR-NRC Banana](https://www.nrcb.res.in) · Tamil Nadu Agricultural University |

Weather advice thresholds in `assets/weather_config.json` are configured conservatively:
- Irrigation skip: rain probability ≥ 60% OR precipitation ≥ 5 mm
- Spray warning: wind > 15 km/h OR rain probability ≥ 40%
- Heat alert: max temperature > 38 °C

These are guidance values only. Adjust for your agro-climatic zone.

---

## Setup & Running

### Prerequisites

- Flutter SDK ≥ 3.38.3 ([install](https://docs.flutter.dev/get-started/install))
- Dart ≥ 3.10.1 (bundled with Flutter)
- Android Studio / VS Code (optional)

### Quick Start (Demo Mode — no Firebase needed)

```bash
# 1. Clone / open the project
cd path/to/project

# 2. Install dependencies
flutter pub get

# 3. Run on Windows desktop, Chrome, or Android
flutter run -d windows     # Windows desktop
flutter run -d chrome      # Chrome browser
flutter run                # connected Android device

# 4. On the login screen, tap "Continue in Demo Mode"
#    All features work with in-memory data (resets on restart)
```

---

## Firebase Configuration

To persist data across sessions (production use):

```bash
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Create a Firebase project at https://console.firebase.google.com
#    Enable: Authentication (Google sign-in) + Cloud Firestore

# 3. Configure
flutterfire configure

# 4. Deploy Firestore security rules
firebase deploy --only firestore:rules

# 5. Run the app — it now uses real Firebase instead of demo mode
flutter run
```

The app auto-detects whether Firebase is initialized and falls back to Demo Mode gracefully if not.

---

## Running Tests

```bash
# All 63 tests
flutter test

# With verbose output
flutter test --reporter=expanded

# Single file
flutter test test/state/finance_state_test.dart
```

**Test coverage by layer:**

| Layer | Tests |
|-------|-------|
| Domain (pure Dart) | 20 tests |
| Data (repositories) | 10 tests |
| State (ChangeNotifier) | 25 tests |
| Models serialization | 5 tests |
| Widget smoke test | 1 test |
| **Total** | **63 tests** |

---

## Building a Release APK

```bash
# Debug APK (for direct install / testing)
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# Release APK (requires signing config)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# App Bundle (for Play Store submission)
flutter build appbundle
# → build/app/outputs/bundle/release/app-release.aab
```

> **Note:** For release builds, configure a keystore in `android/key.properties`. See [Flutter deployment docs](https://docs.flutter.dev/deployment/android).

---

## Localization

The app ships with English (`en`) and Telugu (`te`) translations.

To add a new language:
1. Create `lib/l10n/app_XX.arb` (copy `app_en.arb` as template)
2. Add `Locale('XX')` to `AppLocalizations.supportedLocales`
3. Run `flutter gen-l10n`

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.5 | State management |
| `go_router` | ^17.5.0 | Navigation |
| `cloud_firestore` | ^7.1.0 | Database |
| `firebase_auth` | ^7.0.1 | Authentication |
| `google_sign_in` | ^6.2.2 | Google OAuth |
| `fl_chart` | ^1.3.1 | Finance pie chart |
| `table_calendar` | ^3.2.1 | Calendar view |
| `flutter_local_notifications` | ^22.3.3 | Task reminders |
| `geolocator` | ^14.1.2 | GPS coordinates |
| `http` | ^1.6.0 | Open-Meteo API |
| `intl` | 0.20.2 | Date formatting + l10n |

---

## License

Private — not published to pub.dev (`publish_to: none`).

---

*Built with Flutter 3.38.3 · Dart 3.10.1 · Material Design 3*
