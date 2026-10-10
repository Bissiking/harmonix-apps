# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Personnes qui écoutent leur bibliothèque personnelle Sonora et leurs fichiers
musicaux sur téléphone, ordinateur, navigateur et Android TV.

## Product Purpose

Harmonix réunit catalogue Sonora, copies téléchargées et fichiers personnels,
avec un lecteur partagé, playlists, favoris, paroles, Chromecast, Android Auto,
Rift et Harmonix Night. Les capacités livrées sont dans `DOCS/V4-DELIVERY.md`.

## Positioning

Une application Flutter personnelle et multiplateforme. Sonora reste le backend
musical ; l’appareil conserve son index et ses médias locaux. Aucun fichier
personnel n’est envoyé au serveur. Les compositions de playlists mixtes peuvent
être synchronisées sans transporter leurs fichiers.

## Operating Context

Mobile tactile ; tablette tactile et clavier ; desktop redimensionnable ; web
avec contraintes navigateur ; TV à distance et D-pad. Le mode local n’impose pas
de disponibilité réseau. Le SSO utilise le relais Sonora et le protocole Kyros
réel, dont la version est indépendante du numéro Harmonix.

## Capabilities and Constraints

- Flutter, Riverpod, Dio, just_audio et audio_service restent le socle.
- Un seul moteur audio ; préserver Android Auto, Chromecast et Rift.
- Fichiers privés et données métier isolés par compte et serveur.
- Sonora expose son catalogue musical public à Harmonix.
- SQLite conserve les données métier ; SharedPreferences garde les réglages.
- Night Sense reste volontaire et local, sans mesure du sommeil.
- Le web conserve des métadonnées ; les imports et téléchargements audio
  persistants de cette implémentation nécessitent l’application native.
- Un contrat proposé ne doit jamais apparaître comme un service Kyros disponible.
- Les changements Sonora nécessaires sont autorisés ; Studio ne nécessite pas
  de modification pour le nouveau relais SSO.

## Brand Commitments

Moon Resonance : H ondulé violet/cyan, déclinaison lunaire Night, Midnight Navy
#0A0F2B, violet #7B5CFF, lavande #C8B4FF et cyan #5EE6FF. La stabilité et la
modularité priment ; le raffinement artistique reste évolutif.

## Evidence on Hand

`DOCS/V5-PROMPT.txt`, `DOCS/codex-infos.txt`, `DOCS/New Logo/new_logo.png` ; code
Harmonix et checkouts Sonora 6.1.0 et Studio 0.2.0 fournis par l’utilisateur.
Audit, tests et captures documentés dans DOCS.

## Product Principles

La musique reste contrôlable pendant la navigation. Les téléchargements ne
créent pas de doublons Sonora. Les conflits conservent les données locales jusqu’à
résolution explicite. Une interruption réseau conserve la session ; une
expiration confirmée demande une reconnexion. Aucun transfert comportemental
caché. Les préférences de conservation hors ligne restent propres à l’appareil.

## Accessibility & Inclusion

Contraste, clavier, focus visible, texte redimensionnable, zones sûres et
réduction des animations. La validation TV nécessite des parcours matériels.
