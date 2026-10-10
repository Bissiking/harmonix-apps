# Harmonix Apps

Application musicale Flutter : Sonora, fichiers personnels, téléchargements,
Android Auto, Chromecast, Rift et Harmonix Night.

La migration **Harmonix Flow 4.0.0-dev.1** est documentée dans
[le bilan de livraison](DOCS/V4-DELIVERY.md), avec les fonctions livrées, les builds
vérifiés et les limites par plateforme. Voir aussi [l’audit](DOCS/V4-AUDIT.md),
[l’intégration Sonora](DOCS/SONORA-V4-INTEGRATION.md) et
[les besoins API Kyros V5](DOCS/KYROS-V5-API.md).

## Stack technique

| Couche | Technologie |
|---|---|
| UI & cross-platform | Flutter, validation sur 3.41.6 |
| State management | Riverpod 2 (riverpod_annotation) |
| Navigation | go_router 14 |
| Audio | just_audio + audio_service |
| HTTP | Dio 5 + Retrofit |
| Modèles | freezed + json_serializable |
| Android Auto | audio_service / MediaBrowserServiceCompat |
| Desktop window | window_manager |

## Prérequis

1. [Flutter SDK](https://flutter.dev/docs/get-started/install), version recommandée 3.41.6 pour reproduire la validation V4
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

L'intégration Android Auto utilise directement le `MediaBrowserServiceCompat` fourni par `audio_service`. Android Auto et l'application partagent ainsi la même `MediaSession` et le même player.

**Flux :**
1. Android Auto se connecte au service `audio_service`
2. `HarmonixAudioHandler.getChildren()` fournit le catalogue
3. `search()` retourne les résultats du serveur Harmonix
4. `playFromMediaId()` et `playFromSearch()` utilisent le player normal de l'application
5. L'état de lecture et les métadonnées se propagent sur l'unique `MediaSession`

## Configuration serveur

À la connexion, renseigner l’URL de Sonora et utiliser le bouton SSO Kyros.
Le serveur peut ensuite être changé dans les paramètres. Le bouton hors connexion
ouvre les données déjà mémorisées et les médias de cet appareil.

## Génération de code

Les fichiers `*.g.dart` et `*.freezed.dart` doivent être (re)générés après chaque modification de modèle ou provider :

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Endpoints API utilisés

| Endpoint | Usage |
|---|---|
| `GET /api/health` | Santé Sonora |
| `GET /api/harmonix/apps/v2/bootstrap` | Config initiale |
| `GET /api/harmonix/apps/v2/catalog/tracks` | Catalogue |
| `GET /api/harmonix/apps/v2/catalog/search?q=` | Recherche |
| `GET /api/harmonix/apps/v2/catalog/tracks/:id` | Détail piste |
| `GET /api/harmonix/apps/v2/stream/:id` | Flux audio |
| `GET /api/harmonix/apps/v2/covers/:file` | Pochettes |
| `GET /api/harmonix/apps/v2/library/favorites` | Favoris |
| `POST /api/harmonix/apps/v2/library/favorites/toggle` | Toggle favori |
| `GET /api/harmonix/apps/v2/playback/state` | État player |
| `PUT /api/harmonix/apps/v2/playback/state` | Sauvegarder état |
| `GET /api/harmonix/apps/v2/playback/resume-active` | Reprise rapide |
| `GET /api/harmonix/apps/v2/playback/resume/:trackId` | Reprise piste |
| `GET/PUT /api/harmonix/apps/v2/mixed-playlists[/id]` | Composition des playlists mixtes, après mise à jour Sonora |
