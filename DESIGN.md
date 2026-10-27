---
name: Harmonix Flow — Moon Resonance
description: Une bibliothèque musicale personnelle, lisible sur chaque écran.
colors:
  midnight: "#0A0F2B"
  violet: "#7B5CFF"
  lavender: "#C8B4FF"
  cyan: "#5EE6FF"
  surface: "#121735"
  raised: "#1C2242"
  text: "#F2F1FA"
  daylight-chip: "#F0F0F4"
  daylight-chip-selected: "#E9E3FF"
rounded:
  collection-artwork: "12px"
  choice-chip: "12px"
  collection-panel: "16px"
components:
  chip-choice-midnight:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.choice-chip}"
    padding: "8px"
  chip-choice-daylight:
    backgroundColor: "{colors.daylight-chip}"
    rounded: "{rounded.choice-chip}"
    padding: "8px"
  chip-choice-daylight-selected:
    backgroundColor: "{colors.daylight-chip-selected}"
    rounded: "{rounded.choice-chip}"
    padding: "8px"
  navigation-bar-midnight:
    backgroundColor: "{colors.surface}"
    height: "72px"
---

# Harmonix Flow

## Overview

La référence officielle est `DOCS/New Logo/new_logo.png`. La V4 remplace
l’ancienne identité circulaire par un H à deux montants arrondis et une onde
continue. Night ajoute un croissant supérieur droit. Les SVG dans
`assets/branding` sont les masters vectoriels ; `tool/generate_branding.ps1`
reprend leur géométrie pour les PNG et la bannière TV. Le master raster 3D est
`assets/images/harmonix.png` : `HarmonixLogo` l’affiche et bascule sur
`harmonix_night.png` quand l’apparence est Night. Les icônes système sont
générées depuis `assets/images/harmonix_mobile.png`.

## Autorité et composants

Les sources applicatives font autorité : `FlowTokens`, `HarmonixColors`,
`FlowAppearance`, `AppTheme`, `ResponsiveBreakpoints`, `FlowFocusTile`,
`FlowEmptyState`, `TrackArtwork`, `TrackListTile` et `MiniPlayerBar`.
Les préférences graphiques locales sont indépendantes des métadonnées Sonora.
Le service historique de thème reste disponible, mais les quatre apparences V4
déterminent les surfaces de l’application.

Midnight est le défaut. Aurora accentue le cyan ; Daylight utilise des surfaces
claires ; Night réduit la luminosité et choisit la lavande. La police reste la
sans sérif native Flutter. Utiliser les rôles TextTheme et les composants
Material 3. Rythme : unité 8 dp, marges principales 24 dp, rayon usuel 14 dp.

## Navigation

Sous 720 dp : Accueil, Bibliothèque, Explorer, Night, Profil en navigation basse.
Seul le libellé de la destination sélectionnée est visible. Explorer ouvre
`/catalog` ; `/search` appartient à cette destination dans la navigation basse.
Le menu de l’accueil donne accès aux destinations complémentaires. À partir de
720 dp, y compris tablette portrait : navigation latérale compacte de 88 dp.
À partir de 1100 dp : sidebar de 236 dp avec libellés. Sur TV : sidebar de 244 dp,
catalogue en carrousels à grandes pochettes et lecteur dédié. Le mini-lecteur
reste présent lorsqu’un morceau existe, sauf dans le lecteur plein écran.
Les playlists mixtes ont une route dédiée et conservent cette coque.

Ctrl/Cmd+K ouvre la recherche. Les contrôles Material conservent leurs
interactions clavier ; les cartes TV exposent un contour de focus et un
défilement automatique. Les parcours télécommande nécessitent une validation TV.

## Couleurs dynamiques et mouvement

Seul le halo de la pochette reçoit un accent extrait de l’image. Surfaces et
texte restent stables. L’extraction est mise en cache, sa saturation est bornée
et l’accent du thème sert de repli. La fonction est désactivable. La réduction
des animations du système et de l’app supprime les transitions concernées.
Ne pas ajouter de flou permanent ni shader animé pour remplir l’écran.

## Accessibilité et preuve

Libellés et tooltips français, cibles Material, focus et zones sûres. Les tests
contrôlent le contraste primaire, l’accueil 320 dp avec texte ×2, le clavier et
cinq dispositions. `DOCS/validation` contient des captures de widgets avec
données fictives de test ; elles ne constituent pas une validation audio, SSO
ou matérielle. La direction artistique pourra être affinée sans réécrire
stockage, sources, synchronisation et moteur Night.

## Colors

La palette Moon Resonance reste la référence. Le violet de marque conserve
les remplissages ; la couleur de texte accentuée est calculée séparément par
`HarmonixColors.accessibleAccent`. Si son contraste est inférieur à 4,5:1,
l’algorithme interpole vers le blanc ou le noir par pas de 1 %, selon la
luminance du fond. Le thème sombre utilise la carte de la palette comme fond
de référence ; Daylight utilise la surface de puce sélectionnée. Ce premier
plan sert aux boutons texte et contour, onglets, éléments de liste sélectionnés
et libellés de navigation concernés. Il ne remplace pas l’accent des remplissages.

**The Readable Accent Rule.** Séparer l’accent de texte calculé du remplissage
de marque ; conserver le violet de marque pour les actions remplies.

Les puces non sélectionnées utilisent la surface neutre du thème. Leur sélection
sombre superpose l’accent à 26 % sur cette surface ; Daylight utilise les deux
tons de puce du frontmatter. Le texte sombre suit `palette.text` ; le texte
Daylight reste noir à 87 %. La sélection est tonale et conserve la coche native.

## Typography

Conserver la sans sérif native et les rôles `TextTheme`. Le thème définit
`displaySmall` (36, 800), `headlineMedium` (28, 800), `headlineSmall` (20, 700),
`titleLarge` (18, 600), `titleMedium` (16, 500), `bodyMedium` (14) et `bodySmall`
(12). Les compositions de collection continuent d’honorer le facteur système.

Bibliothèque, Explorer et Paramètres passent de `headlineLarge` à
`headlineSmall` au-delà d’un facteur de texte de 1,5. Au-delà de 1,3, les aperçus
d’apparence passent en une colonne et la sortie mise en avant d’Explorer empile
pochette et texte. La hauteur des étagères et cellules d’albums réserve davantage
de place aux libellés à mesure que le texte grandit.

## Layout

`CollectionWidth` centre les collections dans la largeur restante après la
navigation, avec un maximum de 1280 dp ; Paramètres utilise 1180 dp. Les seuils
internes mesurent cet espace disponible, pas la largeur totale de l’appareil.

Night juxtapose introduction et musique (flex 3), puis minuteur (flex 2), à
partir de 680 dp disponibles, avec une séparation de 40 dp. En dessous, le
minuteur précède l’étagère de pochettes. Paramètres remplace les puces de sections
horizontales par une navigation interne de 220 dp à partir de 850 dp disponibles.
La grille d’albums d’Explorer calcule de deux à six colonnes depuis la largeur
disponible divisée par 200, avec un espacement de 20 dp ; sa mise en avant change
de dimension à 700 dp disponibles et s’empile aussi selon la taille du texte.

**The Available Space Rule.** Adapter chaque collection à l’espace que la coque
lui laisse et à la taille du texte, sans déduire sa composition du type d’appareil.

## Elevation & Depth

Les panneaux de collection privilégient les niveaux de surface du thème :
`surfaceContainerHigh` pour la mise en avant d’Explorer et le minuteur Night,
`surfaceContainerHighest` pour l’entrée de recherche et les squelettes statiques.
Ces composants ne rajoutent pas d’ombre décorative.

## Shapes

Les pochettes, puces et aperçus d’apparence partagent des angles doux (12 dp).
Les panneaux de minuteur et de sortie mise en avant utilisent 16 dp. Les actions
de lecture superposées aux pochettes restent circulaires.

## Components

### Collection musicale

Bibliothèque garde ses six onglets défilants épinglés (56 dp). La vue Morceaux
privilégie les derniers ajouts : une étagère jouable apparaît pour le tri récent,
sans recherche et avec la source Tout, puis vient la liste complète. Le filtre
local porte sur titre, artiste et album sans réinitialiser source ou tri. Les
pochettes jouables utilisent `InkWell`, un rayon de 12 dp et une action de lecture
dans la couleur primaire ; les étagères séparent leurs éléments de 16 dp.

### Session Night

Le panneau expose la durée, les cinq préréglages (15, 30, 45, 60 et 90 min),
l’arrêt à une heure précise, le choix de terminer le morceau et l’action de
démarrage. Les catégories et durées utilisent les puces tonales du thème.

### Paramètres et apparences

Les tâches sont réparties entre Apparence, Écoute, Connexion et À propos.
Les quatre choix Midnight, Aurora, Daylight et Night montrent chacun un aperçu
avec les couleurs de leur apparence ; sélection, coche et sémantique indiquent
le choix courant. Le contrôleur d’apparence existant conserve ce choix.

### États et preuve

Conserver chargement statique, réessai, absence de contenu et absence de résultats
dans le langage Material. Les vingt captures `.impeccable/review` représentent
les vrais widgets Flutter des quatre écrans dans `AppShell`, avec données
synthétiques et pochettes de test. Elles couvrent téléphone, tablette, bureau,
320 dp avec texte ×2 et Daylight. Ce sont des rendus de tests de widgets,
sans validation matérielle, audio ou gestuelle sur appareil.

## Do's and Don'ts

### Do:

- **Do** séparer l’accent de texte lisible des remplissages de marque.
- **Do** adapter les collections à l’espace disponible et au texte redimensionné.
- **Do** garder accessibles les onglets de Bibliothèque et les contrôles Night.
- **Do** conserver états, focus, interactions et sémantique Material natifs.

### Don't:

- **Don't** remplacer les surfaces neutres des puces par un aplat de marque au repos.
- **Don't** présenter les captures de widgets comme une validation sur appareil.

La section active de la navigation interne des Paramètres utilise explicitement
`colorScheme.onSurface` sur son fond sélectionné pour conserver le contraste.
