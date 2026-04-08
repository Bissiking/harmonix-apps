# Harmonix Apps

Application de streaming audio cross-platform : **Android**, **iOS**, **Android Auto** et **Desktop** (Windows / macOS / Linux).

## Stack technique

| Couche | Technologie |
|---|---|
| UI & cross-platform | Flutter 3.22+ |
| State management | Riverpod 2 (riverpod_annotation) |
| Navigation | go_router 14 |
| Audio | just_audio + audio_service |
| HTTP | Dio 5 + Retrofit |
| Modèles | freezed + json_serializable |
| Android Auto | MediaBrowserServiceCompat (Kotlin) |
| Desktop window | window_manager |

## Prérequis

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.22
2. Android Studio ou Xcode (selon la cible)
3. Pour Android Auto : Android Auto Desktop Head Unit (DHU)

## Installation

```bash
# 1. Générer les fichiers natifs Flutter (première fois)
flutter create . --org com.harmonix --project-name harmonix_apps

# 2. Installer les dépendances
flutter pub get

# 3. Générer le code (Riverpod, Retrofit, freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

## Lancer l'application

```bash
# Mobile (Android)
flutter run -d android

# Mobile (iOS)
flutter run -d ios

# Desktop (Windows)
flutter run -d windows

# Desktop (macOS)
flutter run -d macos
```

## Architecture

```
lib/
├── main.dart                    # Point d'entrée, init AudioService
├── app.dart                     # MaterialApp.router
├── core/
│   ├── api/                     # Dio, intercepteur, clients Retrofit
│   ├── audio/                   # HarmonixAudioHandler (just_audio)
│   ├── models/                  # Track, PlaybackStateModel, Bootstrap
│   ├── navigation/              # AppRouter (go_router)
│   ├── platform/                # AutoBridge, DesktopMediaKeys
│   ├── settings/                # SettingsRepository (SharedPreferences)
│   └── utils/                   # Formatters, URL builders
├── features/
│   ├── bootstrap/               # Splash + config initiale
│   ├── catalog/                 # Liste et détail des pistes
│   ├── search/                  # Recherche avec debounce
│   ├── library/                 # Favoris (toggle optimiste)
│   ├── player/                  # Mini-player + fullscreen + providers
│   └── settings/                # Config URL serveur
└── shared/
    ├── theme/                   # AppTheme (dark/light), couleurs
    └── widgets/                 # AsyncValueWidget, ErrorView, TrackArtwork, AppShell
```

## Android Auto

L'intégration Android Auto utilise un `MediaBrowserServiceCompat` natif Kotlin (`HarmonixAudioService`) qui communique avec Flutter via un `MethodChannel` (`com.harmonix.apps/auto`).

**Flux :**
1. Android Auto se connecte au service → `onGetRoot()` autorise l'accès
2. Auto demande le contenu → `onLoadChildren()` appelle Flutter `getQueue`
3. L'utilisateur tape une piste → `AutoMediaCallback.onPlayFromMediaId()` appelle Flutter `playFromId`
4. Flutter met à jour `HarmonixAudioHandler` → l'état `MediaSession` se propage

## Configuration serveur

Au premier lancement, aller dans **Paramètres** et renseigner l'URL de votre serveur Harmonix (ex: `http://192.168.1.10:3000`).

## Génération de code

Les fichiers `*.g.dart` et `*.freezed.dart` doivent être (re)générés après chaque modification de modèle ou provider :

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Endpoints API utilisés

| Endpoint | Usage |
|---|---|
| `GET /api/harmonix/apps/health` | Santé |
| `GET /api/harmonix/apps/bootstrap` | Config initiale |
| `GET /api/harmonix/apps/catalog/tracks` | Catalogue |
| `GET /api/harmonix/apps/catalog/search?q=` | Recherche |
| `GET /api/harmonix/apps/catalog/tracks/:id` | Détail piste |
| `GET /api/harmonix/apps/stream/:id` | Flux audio (Range) |
| `GET /api/harmonix/apps/covers/:file` | Pochettes |
| `GET /api/harmonix/apps/library/favorites` | Favoris |
| `POST /api/harmonix/apps/library/favorites/toggle` | Toggle favori |
| `GET /api/harmonix/apps/playback/state` | État player |
| `PUT /api/harmonix/apps/playback/state` | Sauvegarder état |
| `GET /api/harmonix/apps/playback/resume-active` | Reprise rapide |
| `GET /api/harmonix/apps/playback/resume/:trackId` | Reprise piste |

