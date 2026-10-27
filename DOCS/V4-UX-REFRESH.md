# Collections Harmonix — 27 octobre 2026

La bibliothèque met les ajouts récents et leurs pochettes en tête, avec lecture
directe, onglets persistants, recherche locale par titre/artiste/album, sources
et ordre mémorisé. Les filtres défilent avec les morceaux pour rester utilisables
sur petit écran avec texte agrandi.

Night sépare sélection, préparation et session active. Sur téléphone, la durée
et l'action Démarrer précèdent les pochettes ; sur tablette et ordinateur, ces
espaces se répartissent en deux colonnes. Les autres titres et Night Sense sont
accessibles à la demande. Le moteur de minuterie, le fondu, l'arrêt en fin de
morceau et les exclusions manuelles sont conservés.

Explorer réunit recherche, titre à écouter, albums et catalogue. Les paramètres
se répartissent entre Apparence, Écoute, Connexion et À propos. Les quatre thèmes
ont un aperçu et utilisent le contrôleur persistant existant. La navigation
interne devient latérale lorsque la largeur le permet.

## Correction des données

Le drapeau `night_eligible` de Sonora et le tag exact `harmonix:night` réservent
maintenant un titre à Night, en plus du réglage local. Cela remplace la décision
initiale de ne filtrer que « Night Only ». Le modèle conserve le drapeau dans
le cache ; les téléchargements utilisent les métadonnées actuelles du catalogue
sans modifier leurs fichiers audio. Le lecteur refuse une lecture Night depuis
un contexte ordinaire, plutôt que de démarrer un autre morceau après filtrage.

`Track.addedAt` lit `added_at`, `uploaded_at`, `created_at` et leurs variantes
camelCase. Les timestamps SQLite sans fuseau sont interprétés en UTC. Le tri
utilise la date serveur avant le premier scan local ; une modification des
métadonnées ne change pas la date d'import.

**Dépendance serveur :** le checkout local `D:/DEV/NODEJS/sonora` expose désormais
`added_at: row.uploaded_at || null` depuis son adaptateur Harmonix. Le test API
vérifie catalogue, recherche et détail. Cette modification locale n'a pas été
déployée sur Sonora en production. [Le patch](sonora-catalog-dates.patch) permet
de la reporter dans un autre checkout. Sans ce champ côté serveur, les anciens
titres conservent le repli « premier scan », qui ne permet pas de reconstituer
leur véritable chronologie d'import.

## Validation

`flutter analyze --no-pub` : aucune anomalie. `flutter test --no-pub` :
96 tests réussis, un contrat Kyros live ignoré faute de configuration.
Les deux corrections demandées par la revue indépendante (contraste des textes
et destination Explorer en navigation compacte) ont été validées après reprise.
Le contraste du libellé de paramètres sélectionné atteint 10,87:1 dans la capture
sombre. Le build web JavaScript release réussit ; les avertissements préexistants
concernent la compatibilité Wasm du stockage sécurisé et la police Cupertino.

- Modèles Freezed/JSON régénérés.
- Tests de métadonnées : tags exacts, conservation du cache, UTC, tri par date
  serveur, refus de lecture Night dans un contexte ordinaire.
- Tests SQLite : les téléchargements prennent les nouveaux tags sans changer
  leur fichier, leur taille ni la première date locale.
- `collection_surfaces_test.dart` : quatre écrans à 390×844, 834×1112, 1440×1000,
  320×844 avec texte ×2, et 390×844 en thème clair. Filtrage local et accès aux
  paramètres de connexion également exercés.
- Les captures de `.impeccable/review` sont des rendus de widgets Flutter avec
  données de démonstration. Les pochettes locales de test sont préexistantes et
  ne sont pas ajoutées aux assets de production.

Ces captures ne prouvent ni l'audio, ni les gestes natifs, ni les performances
sur appareil. Android/iOS et Android Auto nécessitent toujours leur recette
matérielle. Le test Kyros live reste optionnel et n'a pas été exécuté.


## Aperçus de démonstration

Ces rendus Flutter contiennent des données synthétiques et des pochettes de test,
ils illustrent les dispositions et non le catalogue réel de l'utilisateur.

| Écran | Téléphone | Tablette | Ordinateur |
|---|---|---|---|
| Bibliothèque | [Capture](validation/collections/library-mobile.png) | [Capture](validation/collections/library-tablet.png) | [Capture](validation/collections/library-desktop.png) |
| Night | [Capture](validation/collections/night-mobile.png) | [Capture](validation/collections/night-tablet.png) | [Capture](validation/collections/night-desktop.png) |
| Explorer | [Capture](validation/collections/catalog-mobile.png) | [Capture](validation/collections/catalog-tablet.png) | [Capture](validation/collections/catalog-desktop.png) |
| Paramètres | [Capture](validation/collections/settings-mobile.png) | [Capture](validation/collections/settings-tablet.png) | [Capture](validation/collections/settings-desktop.png) |
