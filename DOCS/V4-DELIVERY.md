# Harmonix Flow — état de livraison

10 octobre 2026. Version `4.0.0-dev.1+40000`, issue de `3.1.2+30102`.
Cette migration fournit un socle V4 compilable et des fonctions métier nouvelles.
Elle n’est pas présentée comme une release 4.0.0 validée sur tous les appareils.

## Implémentation

| Domaine | Livré |
|---|---|
| Identité | H ondulé et Night, masters SVG, PNG, icônes Android/iOS/desktop/web, bannière Leanback |
| Design | Tokens, quatre apparences, composants de focus/état vide, halo de pochette borné, réduction du mouvement |
| Navigation | Mobile à cinq destinations, rail dès 720 dp, sidebar desktop, routes playlists mixtes, Ctrl/Cmd+K |
| TV | Détection Android uiMode, launcher Leanback, catalogue/carrousels et lecteur dédiés ; focus visible |
| Stockage | SQLite, comptes/serveurs séparés, index/favoris/playlists/historique/transferts/métadonnées Night |
| Imports | Sélection volontaire fichiers/dossiers natifs, copie privée, SHA-256, tags et pochette embarquée, doublons logiques réunis |
| Sources | Fichier conservé avant cache temporaire avant Sonora ; indisponibles sautés en queue, fichiers personnels jamais streamés depuis Sonora |
| Mode local | Entrée sans requête bootstrap, recherche et données mémorisées, favoris personnels, playlists mixtes et Night |
| Téléchargements | Titres/albums/playlists, progression, pause, reprise depuis le début, annulation, erreurs, restauration des interruptions et suppression |
| Cache audio | Temporaire, désactivé par défaut, budget 64/128/256/512 Mo, nettoyage LRU et manuel ; fichiers conservés séparés |
| Playlists mixtes | CRUD, réorganisation, références personnelles, opérations durables, révisions, conflits conservant une copie, synchronisation Sonora |
| Maintien hors ligne | Option locale à chaque appareil ; actualisation périodique des médias Sonora pendant que l’app est ouverte |
| Recherche/bibliothèque | Morceaux, albums, artistes issus des tags, favoris, playlists Sonora/mixtes et filtres de sources |
| Lecteur | Lecteur partagé, file unifiée, source affichée, progression du mini-lecteur, menu du titre, paroles et commandes existantes |
| Night | Affectation distincte du genre, exclusions prioritaires, Night Only, catégories, 45 min par défaut, heure d’arrêt et fin de titre, fade du volume applicatif |
| Night Sense | Consentement local par compte/serveur, horaires et durées effectivement observés, médiane circulaire pondérée, seuil de cinq sessions, effacement |
| Rift/Cast/Auto | Écran Rift connecté au moteur existant ; fichiers personnels exclus de la diffusion distante ; Android Auto et Chromecast conservés |
| Session | Migration vérifiée des jetons vers le coffre, absence de redirection login sur panne réseau, arrêt de la lecture au changement de profil/serveur |
| SSO | Fenêtre web préparée au clic et fermée après connexion, navigateur intégré mobile, retour par scheme fixe, premier plan desktop, callback Sonora sécurisé |

## Preuves

- Tests Flutter : **35 réussis** à l’état testé, couvrant notamment fermeture et
  réouverture réelle d’un fichier SQLite, isolation, doublons logiques, sources,
  origine des jetons, migration sécurisée, concurrence de playlists, opérations
  stables, absence de redirection sur HTTP 503, minuteur/fade, habitudes nocturnes,
  contrastes, accueil 320 dp ×2 et clavier sur cinq dispositions.
- Analyse Dart : aucune erreur ni avertissement à l’état analysé.
- Sonora : `npm run check`, syntaxe et **19 tests réussis**, incluant les anciens
  parcours catalogue/RBAC/playlists/favoris/reprise/Rift, PKCE/PAR, nouveau retour
  SSO et comparaison atomique des playlists mixtes.
- Builds réussis : web JavaScript release, Windows release et APK Android debug.
  Les builds finaux sont régénérés après les derniers changements de code.
- Captures contrôlées dans `validation/flow-{mobile,tablet,desktop,daylight,tv}.png`.
  Widgets Flutter avec fixtures de test, sans connexion au compte utilisateur.
  Vérification visuelle en une passe et une confirmation ; pas de preuve audio.
- Sonora 6.1.0 et Studio 0.2.0 vérifiés dans leurs checkouts locaux.

## Fonctionnement et limites à connaître

Le mode local peut être choisi à la connexion ou dans les paramètres. Après
expiration confirmée, l’identité locale est conservée pour retrouver ses médias
hors connexion. Une déconnexion manuelle passe au profil invité ; elle ne supprime
pas les fichiers du compte. Se reconnecter au même sujet Kyros et au même serveur
permet de retrouver ses données. Un changement de serveur efface la session
active pour éviter l’envoi de son jeton au mauvais serveur.

Les téléchargements utilisent la qualité du flux original. Leur empreinte locale
et leur longueur sont vérifiées ; aucun checksum distant certifié n’est annoncé.
Sans contrat Range/ETag confirmé, la reprise recommence le transfert. Le maintien
hors ligne et le cache optionnel utilisent toute connexion disponible ; le
filtrage Wi-Fi, les quotas de téléchargements permanents et le choix de qualité
transcodée restent à ajouter avec des contrats et capacités vérifiés.

Le cache récupère une copie supplémentaire du flux après démarrage de l’écoute.
Il ne s’agit pas d’un tee du décodeur. Il ne bloque pas la lecture, protège la file
active lors du nettoyage automatique et abandonne un transfert dépassant son
budget. Les fichiers explicitement conservés ne sont jamais évincés par ce cache.
Le cache des pochettes reste géré par cached_network_image.

Le serveur doit intégrer les changements de `D:/DEV/NODEJS/sonora` pour annoncer
la capacité de playlists mixtes. Aucun déploiement effectué. La synchronisation
est une composition complète avec révisions, pas encore un protocole incrémental
par opération. Les anciens favoris Sonora utilisent un toggle : une modification
hors ligne est refusée plutôt que rejouée avec un résultat ambigu. Les favoris
déjà mémorisés restent consultables.

Le web utilise SQLite/IndexedDB et les ressources wasm/worker générées. Ce stockage
reste soumis aux quotas/effacements du navigateur. Les fichiers musicaux locaux
persistants et leur import ne sont pas implémentés sur web. Le build JavaScript
réussit ; le build WebAssembly n’est pas supporté par flutter_secure_storage 9.2.4.

Night applique un fade prudent au volume du lecteur, jamais au volume système.
Il n’intègre pas de limiteur DSP de pics ni de normalisation d’un signal PCM.
L’automatique n’invente aucune analyse vocale ; tags/tempo connus ne donnent
qu’une faible confiance, et l’autorisation manuelle reste prioritaire. Les
rappels OS, reports/ignorés, alarmes Android, correction manuelle des observations
et intégration Samsung ne sont pas livrés. Aucun service Vault n’est appelé.

Le catalogue local indexe toutes les entrées déjà reçues ; les listes UI usuelles
sont virtualisées mais Sonora n’a pas de pagination de catalogue dans ce contrat.
Les très grandes bibliothèques et les panneaux secondaires/menus doivent encore
être profilés sur matériel modeste. L’accueil affiche le contenu réellement
disponible ; l’historique local n’a pas encore une section complète de reprise
avec position persistée. Les raffinements de DA peuvent continuer sur le socle
modulaire livré.

## Intégration des tags Night Studio

Sonora 6.2.0 et Studio 0.2.0 sont modifiés localement pour le tag
`harmonix:night`. Harmonix Night reconnaît l’indicateur serveur, permet
d’actualiser le catalogue et conserve les exclusions/autorisations manuelles.
Les changements du catalogue priment sur les métadonnées d’anciennes copies
téléchargées, et restent conservés hors connexion. Le tag ne modifie ni
**Night Only**, ni la catégorie locale. Voir `SONORA-V4-INTEGRATION.md` pour le
parcours, le contrat, les patches additionnels et les composants à déployer.
Validation après ce changement : 40 tests Flutter, 21 tests Sonora, analyse
Flutter et build Studio. Aucun déploiement effectué.

## Correctif du log répétitif du lecteur

Le log fourni contenait 80 messages `TrackArtwork` et 12 erreurs Windows
`Failed to update ui::AXTree`. Le message de debug émis à chaque construction
de pochette a été supprimé. Les lecteurs compact et complet observent maintenant
la position et le buffering dans des widgets de progression distincts ; leurs
pochettes et boutons ne se reconstruisent plus à chaque tick local ou Cast.

Des frontières `Semantics(container: true)` séparent les boutons à infobulle du
lecteur, de l’accueil, des lignes de titres et de la navigation latérale. C’est
un contournement du défaut de fusion des ancres documenté dans
[Flutter #182444](https://github.com/flutter/flutter/issues/182444), sans
désactiver l’accessibilité. Les 37 tests Flutter passent, dont deux régressions
sur la progression locale/Cast et les informations accessibles ; l’analyseur
ne signale aucun problème. Le moteur AXTree Windows n’est pas exécuté par ces
tests : vérifier le contournement dans une nouvelle session native, après arrêt
complet de l’application, car un arbre déjà rejeté peut rester invalide.

### Deuxième log AXTree Windows

Le log suivant contient uniquement des réponses Sonora `200 OK` et de nouvelles
erreurs AXTree. Les frontières Semantics du premier correctif ne suffisent pas.
Les 37 boutons à infobulle définis par Harmonix utilisent maintenant
`FlowIconButton`. Sur Windows natif, il remplace l’infobulle OverlayPortal par un
OverlayEntry passif, tout en conservant la description accessible du bouton.
Le composant annule les timers et retire l’overlay lors du retrait du bouton,
du défilement et des changements de taille/thème. Les autres plateformes
conservent l’infobulle Flutter standard.

Les deux tests spécifiques vérifient l’absence d’OverlayPortal autour du bouton
Windows, la description accessible, le survol, le clic et le nettoyage.
L’arbre natif Windows doit encore être vérifié après arrêt complet de l’app.
Le déclencheur précisé par l’utilisateur est l’accueil/le lecteur après un
téléchargement. Celui-ci conserve l’audio sans créer une nouvelle pochette ;
l’invalidation de la liste des fichiers reconstruisait pourtant toutes les
pochettes abonnées. TrackArtwork et la couleur ambiante observent maintenant
uniquement le chemin de pochette du titre concerné. Les tests des lecteurs
compact/complet vérifient qu’une fin de téléchargement audio laisse leur
pochette inchangée.

Ce changement ne remplace pas les overlays internes d’autres contrôles Flutter,
notamment Slider ; des erreurs restantes doivent être reliées à leur écran
et au geste qui les déclenche. L’accessibilité générale reste activée.

## Validation restante avant release

1. Téléphone Android : SSO réel, retour navigateur, import, interruption réseau,
   téléchargement annulé/repris, arrière-plan et changement de compte.
2. TV/émulateur : parcours D-pad complet, Retour/focus après modales, recherche,
   connexion avec navigateur disponible et commandes média. L’authentification
   depuis un autre appareil dépend d’un contrat Kyros V5 proposé dans le document
   dédié ; aucun faux QR de connexion n’a été livré.
3. Windows : import FLAC/MP3/M4A, lecture de fichiers téléchargés et cache,
   redimensionnement, coffre système et longue session audio.
4. iOS/macOS : build et tests sur hôte Apple, entitlements du coffre, permissions,
   retour SSO, verrouillage et reprise. Linux : backend just_audio et libsecret à
   vérifier avant de déclarer la lecture supportée.
5. Navigateur : SSO avec fenêtres autorisées/bloquées, rechargement, persistance
   IndexedDB, consommation des blobs et lecture en arrière-plan. Le navigateur de
   contrôle n’était pas disponible dans cette session.
6. Chromecast, Android Auto et Rift sur appareils réels ; synchronisation entre
   deux appareils connectés à Sonora/Kyros configurés, conflit et suppression.
7. Profilage de milliers de titres, mémoire TV, erreurs disque et couverture des
   transferts audio avec serveurs locaux simulant Range, MIME et coupures.

## Reproduction

```text
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-pub
flutter test --no-pub
flutter test test/v4_flow_surfaces_test.dart --dart-define=FLOW_CAPTURE=true
flutter build web --release --no-pub
flutter build windows --release --no-pub
flutter build apk --debug --no-pub
```

`tool/generate_branding.ps1` régénère les PNG ; `dart run flutter_launcher_icons`
régénère les icônes système. Ne pas exécuter les scripts d’application Sonora sur
un checkout déjà patché sans les relire. Les changements backend effectifs sont
documentés dans `SONORA-V4-INTEGRATION.md` ; le fichier à transmettre à Kyros est
`KYROS-V5-API.md`.
