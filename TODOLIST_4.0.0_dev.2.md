# TODOLIST 4.0.0-dev.2

Carnet de suivi des retours d'usage après la 4.0.0-dev.1.
Statuts : `[ ]` à faire · `[~]` en cours · `[x]` fait · `[-]` reporté.

---

## 1. `[x]` Musiques de « Harmonix Night » visibles dans la bibliothèque

**Retour** : *« Je vois les musiques de Harmonix Night dans la bibliothèque. »*
**Décision révisée (27 octobre, nouveaux retours)** : les titres classés
`harmonix:night` / `night_eligible` sont réservés à Night et masqués des listes
ordinaires, ainsi que les titres marqués localement **Night Only**.

Diagnostic :

- Filtre appliqué dans `lib/features/catalog/providers/tracks_provider.dart:16`,
  `lib/features/library/providers/favorites_provider.dart:15`,
  `lib/features/search/data/search_repository.dart:14`,
  `lib/features/player/providers/player_provider.dart:34,98`.
- **Fuites** (chemins qui ne lisent pas le filtre) :
  - `playlistTrackIndexProvider` (`lib/features/library/data/mixed_playlist_sync.dart:292-302`)
    → écran Playlist mixte.
  - `deviceTracksProvider` brut → écran **Téléchargements** (`downloads_screen.dart`).
  - `DeviceLibrary.allTracks()` (`device_library.dart:29-40`) → recherche locale
    et cache offline.
  - `Playlist.tracks` serveur → écran Playlist Sonora (`playlist_detail_screen.dart`).
  - `library_repository.getFavorites()` (`library_repository.dart:26-32`), filtré
    seulement côté provider.

**Correction** : un seul helper d'exposition `visibleInLibrary(track)` (fichier
`lib/features/night/domain/night_visibility.dart`) + application dans chacun de
ces chemins, avec tests de non-régression.

**Bilan** : helper appliqué dans `tracks_provider`, `favorites_provider`,
`search_repository`, `player_provider` (+ `playFromQueue`),
`playlist_detail_screen`, `downloads_screen`, `device_library_screen`
(playlist mixte : filtres des lignes, de la lecture et du dialogue « Ajouter »,
reordonnancement traduit par id). Volontairement **non filtrés** :
`DeviceLibrary.allTracks()` et `playlistTrackIndexProvider` (couche données /
index `byId`, l'UI filtre), `library_repository.getFavorites()` (écrirait la
suppression dans le cache), `night_screen`. Tests :
`test/night_visibility_test.dart`.

---

## 2. `[x]` Ordre d'ajout / date d'ajout

**Retour** : *« Les musiques n'apparaissent pas dans l'ordre d'ajout ou date d'ajout. »*
**Décision** : **menu de tri** dans l'onglet Morceaux
(**Ajout récent** par défaut, A–Z, Artiste, Album), choix mémorisé.

Diagnostic :

- Tri actuel = alphabétique, en dur :
  `lib/features/library/presentation/device_library_screen.dart:90-91`.
- `Track` **n'a aucun champ de date** (`lib/core/models/track.dart:6-34`) et la
  table `records` (`lib/core/storage/local_store.dart:21-25`) n'a pas de colonne
  d'ordre → il faut **créer la donnée**.

**Plan** :

1. Lire d'éventuels champs date renvoyés par l'API (`added_at` / `created_at`) en
   optionnel dans `Track` (les champs inconnus sont aujourd'hui ignorés).
2. Sinon, horodatage **« premier scan local »** : bucket `track_added`
   (`id → ISO`), écrit au cache catalogue (`device_library.cacheCatalog`) et à
   l'import de fichier.
3. Menu tri dans `DeviceLibraryScreen`, préférence persistée dans
   `SettingsRepository` (`library_sort`), défaut `recent`.

**Bilan révisé** : `Track.addedAt` conserve désormais les dates du serveur
(`added_at` / `uploaded_at` / `created_at`). Le premier scan reste le repli dans un bucket `track_added` (`{id, at}`) horodaté au premier
scan (`DeviceLibrary.stampAdded`, appels depuis `cacheCatalog` et `saveFile`),
lu par `trackAddedDatesProvider`. Ordre implémenté dans
`lib/features/library/domain/library_sort.dart` (`sortTracks`, défaut
`recent`, titres sans horodatage en fin de liste). Tests :
`test/library_sort_test.dart`.

---

## 3. `[x]` Player : impossible de changer de musique (suivant)

**Retour** : *« Dans le player, je ne peux changer la musique suivante. »*

Diagnostic :

- `HarmonixAudioHandler.skipToNext()` est un no-op si `!_player.hasNext`
  (`lib/core/audio/audio_handler.dart:250-258`) : la file à **1 seul titre** ne
  donne jamais `hasNext`.
- Les écrans qui appellent `playTrack()` (file à un titre) au lieu de
  `playFromQueue()` :
  - `track_detail_screen.dart:82` (bouton « Lire »),
  - `downloads_screen.dart:144`,
  - `device_library_screen.dart:409` (piste d'une playlist mixte),
  - `session_reconnect_provider.dart:23`.
- Le bouton suivant du player n'est jamais désactivé
  (`full_player_screen.dart:99-104`) → il paraît « cassé » plutôt que désactivé.

**Correction** :

1. Passer le **contexte de liste** aux appels `playTrack` (ou basculer en
   `playFromQueue`) pour que chaque source de lecture construise une vraie file.
2. Marquer le bouton suivant/précédent comme indisponible quand la file fait 1
   titre (état `hasNext/hasPrevious` diffusé par le handler) au lieu d'un
   onPressed muet.
3. Sur le web, fiabiliser la fenêtre de file incrémentale
   (`player_provider._maintainWebQueueWindow`) : un titre non résolvable est
   sauté (`player_provider.dart:246-248`) et crée un trou dans la file.

**Bilan** :

1. `playTrack(track, {queue})` construit la file quand un contexte est fourni
   (appels mis à jour : Détail d'album via `_albumQueue`, Téléchargements,
   playlist mixte, favoris déjà en file). `session_reconnect` et `auto_bridge`
   gardent le fallback mono-piste.
2. Le handler diffuse `(hasNext, hasPrevious)` (ValueNotifier + providers
   `playerNavigationProvider`) : les boutons suivant/précédent sont réellement
   désactivés (`full_player_screen`, `mini_player_bar` — sauf mode cast, qui
   pilote sa propre file).
3. `resolverLoop` réessaie le même index 3× avant de sauter. La fenêtre compte
   les sources effectivement chargées, et la file publique reste alignée sur
   ces sources même lorsqu'un titre est inaccessible. Les URL blob restent
   valides pour Précédent / Boucle / Aléatoire et sont libérées au remplacement
   de la file (la mémoire audio peut donc augmenter avec les titres parcourus).

---

## 4. `[x]` UX bibliothèque (propreté / beauté)

**Retour** : *« Optimiser les bibliothèques côté UX pour que ce soit plus propre
et plus beau. »*

Cibles (à affiner une fois 1-3 livrés) :

- Onglet Morceaux : en-tête compact (compteur + menu de tri + filtres source),
  regrouper Import sous un seul bouton, aligner les puces de filtre.
- Favoris / Playlists : mêmes motifs de tuile que `TrackListTile`, états vides
  homogènes via `FlowEmptyState`.
- Écran Night : ne plus lister le catalogue entier avec la raison brute
  (`night_screen.dart:221-226`) → lister d'abord les titres **autorisés**, puis
  les autres dans un bloc repliable.
- Listes : lisibilité des métadonnées, rythme vertical, touch targets ≥ 48.

**Livré** :

- **Morceaux** (`device_library_screen.dart`) : une seule ligne d'en-tête —
  menu de tri + compteur de titres + bouton **Importer** regroupant
  « Fichiers audio… » / « Dossier entier… » (plus deux boutons séparés), puis
  les puces de filtre alignées dessous. Cibles tactiles du tri et de l'import
  portées à 48 px, état d'importation en inline spinner, état vide distinct
  quand un filtre ne renvoie rien, marge basse de liste.
- **Night** (`night_screen.dart`) : les titres **autorisés** pour la catégorie
  passent en tête, le reste du catalogue est replié derrière un
  « Autres titres du catalogue · N » (`nightTrackRow` partagé).
- **Favoris / Playlists Sonora** (`library_screen.dart`) : états vides
  homogènes via `FlowEmptyState` (avec l'action « Créer une playlist »), marge
  basse de liste.
- **Métadonnées** : durée des titres en `bodySmall` + `onSurfaceVariant`
  (au lieu de 60 % d'opacité, sous le seuil de contraste).

---

## 5. `[x]` Persistance de « Aléatoire » et « Boucle »

**Retour** : *« Enregistrement de l'état de Aléatoire et Boucle. »*

Diagnostic : l'état vit uniquement dans `just_audio`
(`audio_handler.dart:277-294`), n'est **jamais persisté** ; `SettingsRepository`
n'a aucune clé shuffle/repeat. `PlaybackRepository.saveState()` existe
(`playback_repository.dart:17-25`) mais n'est **jamais appelé**.

**Correction** : clés `flow_shuffle` / `flow_repeat` dans
`SettingsRepository`, écrites à chaque changement (`Player.setShuffle` /
`setRepeat`) et restaurées au démarrage du handler.

---

## 6. `[x]` « Aléatoire » et « Boucle » sur Android Auto + synchro

**Retour** : *« Avoir Aléatoire et Boucle sur Android Auto et synchronisation
entre Android Auto et le Player. »*

Diagnostic :

- La synchro **Auto ↔ player** passe déjà par la `PlaybackState` diffusée
  (`audio_handler.dart:350-357` + `_rebroadcastState`), donc un changement fait
  côté Auto met à jour le lecteur, et inversement.
- **Manque** : `systemActions` ne déclare pas `MediaAction.setShuffleMode` /
  `setRepeatMode` (`audio_handler.dart:337-341`) → Android Auto n'affiche pas
  (ou n'envoie pas) les commandes, selon le client.
- Manque la persistance (voir §5) : l'état revient au par défaut au redémarrage.

**Correction** : exposer les actions système + persistance §5 + boutons
Aléatoire / Boucle dans la mini barre (utile aussi hors Auto).

---

## Vérifications

- [x] `flutter analyze --no-pub` sans erreur (27 octobre 2026)
- [x] `flutter test` (revalidé le 27 octobre 2026 : 96 tests OK, 1 skip —
      contrat Kyros live non configuré)
- [x] `flutter build web --release --no-pub` (27 octobre 2026, build JavaScript ;
      avertissements existants : compatibilité Wasm du stockage sécurisé et
      police Cupertino absente)
- [ ] Recette manuelle : lecture d'un titre depuis Détail / Téléchargements →
      suivant/précédent actifs ; relance de l'app → Aléatoire/Boucle conservés ;
      Android Auto → mêmes états que le player ; titres Night absents de la
      bibliothèque/favoris/playlists ; tri « Ajout récent » conservé après
      redémarrage.

### Reprise du 27 octobre 2026

La revue du travail existant a reproduit puis corrigé quatre défauts audio :
Boucle écrasée pendant la restauration des préférences, état initial de
navigation perdu à l'ouverture du lecteur, métadonnées décalées après un titre
web inaccessible, ancienne file conservée après une lecture mono-piste.
Tests de régression : `test/audio_playback_test.dart` (les quatre échouaient
avant correction).

Les dates d'ajout sont aussi rechargées après le scan du catalogue pour éviter
un tri obsolète au premier affichage. Tests complémentaires :
`test/library_added_dates_test.dart` (rafraîchissement des dates, conservation
de la première date et isolation par compte). La recette sur appareil et
Android Auto reste à réaliser.


### Retours complémentaires — refonte des collections

Les nouveaux retours remplacent la sémantique Night initiale : les tags Studio
réservent désormais les morceaux à Night. Les dates serveur priment sur le scan
local. Le mapping Sonora local et son test API ont été corrigés ; leur déploiement
est nécessaire pour retrouver la chronologie exacte sur le serveur utilisé.
Bibliothèque, Night, Explorer et Paramètres ont été retravaillés pour les trois
formats, avec thème clair et texte agrandi. Voir [le bilan de la refonte](DOCS/V4-UX-REFRESH.md)
pour le périmètre et les limites de validation.
