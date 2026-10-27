<!-- V4-AUDIT.md -->
# Harmonix 4 — audit et migration

Audit du 10 octobre 2026, avant modification du code applicatif.

## Diagnostic vérifié

- Version réelle : `3.1.2+30102`, Flutter/Dart disponibles sous `C:/apps/flutter`.
- Structure : modules `core`, `features`, `shared`; Riverpod 2, go_router 14,
  Dio/Retrofit, Freezed. Génération de code déjà versionnée.
- Lecture : un `HarmonixAudioHandler` et un `AudioPlayer` just_audio partagés.
  audio_service sur Android/iOS, just_audio_windows sur Windows. La lecture web
  authentifiée utilise des blobs et une fenêtre de préchargement.
- Catalogue, albums, paroles, favoris et playlists : clients réels sous
  `/api/harmonix/apps/v2`. Les listes sont actuellement non paginées.
- Kyros : relais SSO `v2/sso/start` et `status`, refresh `/api/auth/refresh`.
  Les jetons existants sont dans SharedPreferences : migration sécurisée requise.
- Android Auto : AutoBridge fournit browse/search/play à la même MediaSession.
- Chromecast : dart_cast, découverte et contrôles existants.
- Rift : dépôt et contrôleur existants (création, invitation, rejoindre, état,
  polling), mais l'écran est un placeholder. Réutiliser ce moteur.
- Navigation actuelle : cinq destinations, bibliothèque reléguée à Explorer.
  Tablette portrait utilise encore la barre mobile. Plusieurs styles codés en dur.
- Hors connexion : cache catalogue uniquement en mémoire; erreurs réseau
  déclenchent `requireLogin`. Aucun index persistant ni téléchargement musical.
- Aucun import local, Night, Night Sense ni configuration Leanback TV.
- Android/iOS/macOS/Windows/Linux/web présents. Linux n'a pas de backend
  just_audio explicitement configuré : lecture Linux à vérifier avant promesse.
- Tests existants : refresh/intercepteur auth, thème/contrastes, responsive accueil,
  mises à jour et smoke widget. Pas de scénarios audio matériels.
- Référence Moon Resonance disponible : `DOCS/New Logo/new_logo.png`, planche raster.
  Créer un master géométrique vectoriel suivant le H ondulé et sa lune.
- Aucun checkout Sonora adjacent. Version serveur 6.1.0 non vérifiable ici.
  Les documents d'endpoints sont historiques; les clients actuels font autorité.

## Stratégie avant modifications majeures

1. Préserver les routes v2, les modèles réseau et le lecteur unique. Ajouter les
   propriétés locales dans un modèle séparé : une copie téléchargée ne change
   jamais l'identité du titre Sonora.
2. Ajouter un stockage SQLite par serveur/compte, sans remplacer les préférences
   existantes ni supprimer de données. Séparer imports, fichiers permanents,
   transferts incomplets et cache temporaire. Index et opérations locales
   transactionnels; aucun chemin local envoyé au serveur.
3. Résoudre la source audio locale avant le streaming. Import volontaire avec
   empreinte SHA-256, copie privée durable, doublons reconnus. En cas d'absence,
   conserver l'entrée et proposer une nouvelle copie.
4. Rendre navigation/recherche/catalogue/favoris disponibles depuis le disque.
   Seule une expiration d'authentification confirmée impose une reconnexion.
5. Construire tokens, quatre thèmes, identité vectorielle, navigation adaptée et
   composants clavier/focus. Réutiliser les fonctions fiables, reconstruire les
   surfaces où leur structure empêche les nouveaux parcours.
6. Playlists mixtes locales et réorganisation hors ligne. Ne pas prétendre
   synchroniser les références locales avec l'API actuelle. Spécifier révisions,
   opérations idempotentes et conflits pour Sonora; ne pas rejouer un toggle
   favori après un timeout, dont le résultat serveur est inconnu.
7. Night : affectation distincte du genre, exclusions prioritaires, minuteur
   borné, fade sur le volume du lecteur. Night Sense déterministe et volontaire,
   données locales; aucune mesure du sommeil ni notification automatique factice.
8. TV : détection uiMode native, Leanback/banner, interface dédiée, focus et
   commandes média; support final conditionné à des parcours sur matériel TV.
9. Tester logique de stockage/source/minuteur/conflits, widgets responsive et
   build web/Windows/Android selon outils disponibles. Documenter chaque limite.

## Dépendances Sonora identifiées

Les routes actuelles ne garantissent ni révisions de playlist, ni références
locales, ni clé d'idempotence, ni pagination, ni classification Night. Ces besoins
seront documentés comme un contrat proposé, jamais exposés comme déjà disponibles.
La qualité téléchargée restera celle du flux existant jusqu'à vérification d'un
contrat de transcodage. La connexion TV réutilisera le relais SSO existant.

## Validation de livraison

Une version 4.0.0 de développement ne signifie pas validation matérielle de
toutes les plateformes. Les preuves, fonctionnalités partielles et dépendances
externes sont consignées dans `V4-DELIVERY.md`.

## Complément après communication des chemins locaux

L’utilisateur a ensuite fourni `D:/DEV/NODEJS/sonora` et
`D:/DEV/NODEJS/sonoraStudio`. Le code confirme Sonora 6.1.0 et Studio 0.2.0.
Studio transmet `/auth` à Sonora : la page de fin du SSO est corrigée côté Sonora
sans modifier Studio. Un contrat additif de playlists mixtes est implémenté sous
le préfixe v2 existant, avec une table séparée et comparaison atomique des
révisions. Les anciens contrats restent présents. Voir `SONORA-V4-INTEGRATION.md`.
