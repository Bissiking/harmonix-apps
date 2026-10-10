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
---

# Harmonix Flow

La référence officielle est `DOCS/New Logo/new_logo.png`. La V4 remplace
l’ancienne identité circulaire par un H à deux montants arrondis et une onde
continue. Night ajoute un croissant supérieur droit. Les SVG dans
`assets/branding` sont les masters ; `tool/generate_branding.ps1` reprend leur
géométrie pour les PNG et la bannière TV. `HarmonixMark` utilise le même repère
de 128 unités. Les icônes système sont générées depuis ce master.

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

Sous 720 dp : Accueil, Bibliothèque, Recherche, Night, Profil en navigation basse.
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
