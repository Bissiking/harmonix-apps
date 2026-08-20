---
name: Harmonix
description: Un salon d’écoute nocturne et continu pour retrouver, lancer, partager et reprendre sa musique.
colors:
  listening-lavender: "#A78BFA"
  signal-cyan: "#67D7F0"
  light-signal-cyan: "#00BCD4"
  midnight-ink: "#07101E"
  slate-surface: "#0D1727"
  raised-slate: "#152033"
  night-glow: "#121D38"
  moon-text: "#F4F2FF"
  light-canvas: "#FAFAFC"
  light-panel: "#F0F0F4"
  light-glow: "#F1EEFF"
  amoled-surface: "#0A0A0A"
  amoled-panel: "#111111"
  profile-blue: "#304E78"
  discovery-green: "#66D6A8"
  together-amber: "#FFB85C"
typography:
  display:
    fontSize: "36px"
    fontWeight: 800
  headline:
    fontSize: "28px"
    fontWeight: 800
  heading:
    fontSize: "20px"
    fontWeight: 700
  title:
    fontSize: "18px"
    fontWeight: 600
  body:
    fontSize: "14px"
    fontWeight: 400
  supporting:
    fontSize: "12px"
    fontWeight: 400
  navigation-label:
    fontSize: "11px"
    fontWeight: 500
rounded:
  artwork-sm: "6px"
  tile-sm: "10px"
  badge: "12px"
  control: "14px"
  panel: "16px"
  circular: "999px"
spacing:
  micro: "4px"
  xs: "8px"
  sm: "10px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  section: "32px"
components:
  button-filled-dark:
    backgroundColor: "{colors.listening-lavender}"
    textColor: "#000000"
    rounded: "{rounded.control}"
  button-filled-light:
    backgroundColor: "{colors.listening-lavender}"
    textColor: "#000000"
    rounded: "{rounded.tile-sm}"
  input-dark:
    backgroundColor: "{colors.raised-slate}"
    textColor: "{colors.moon-text}"
    rounded: "{rounded.control}"
  card-raised-dark:
    backgroundColor: "{colors.raised-slate}"
    textColor: "{colors.moon-text}"
    rounded: "{rounded.panel}"
  card-raised-light:
    backgroundColor: "{colors.light-panel}"
    textColor: "#000000DE"
    rounded: "{rounded.panel}"
  mini-player-dark:
    backgroundColor: "{colors.slate-surface}"
    textColor: "{colors.moon-text}"
    height: "64px"
  navigation-bar-dark:
    backgroundColor: "{colors.slate-surface}"
    textColor: "{colors.listening-lavender}"
    height: "72px"
---

# Design System: Harmonix

## Overview

**Creative North Star: "Le salon d’écoute nocturne"**

Harmonix installe l’utilisateur dans un espace d’écoute continu : un fond bleu encre, des panneaux ardoise légèrement relevés et des accents lavande et cyan laissent les pochettes porter l’immersion. L’accueil est éditorial — une écoute mise en avant, des ajouts récents et des raccourcis d’humeur — tandis que le catalogue reste une destination de recherche, jamais la forme dominante de toute l’application.

La hiérarchie sert une histoire stable : retrouver sa musique, la lancer, la partager en séance et la reprendre partout. Le lecteur compact persiste au bas des destinations quand un morceau existe; le lecteur complet devient une scène dédiée, avec la pochette comme centre de gravité. Le thème sombre est la référence visuelle; le thème clair conserve les mêmes rôles et remplace l’encre par un canevas presque blanc avec une lueur lavande.

**Key Characteristics:**

- Univers nocturne bleu encre, panneaux ardoise et lueur radiale discrète.
- Lavande pour l’action et l’état actif; cyan pour le signal et l’accompagnement.
- Grandes pochettes immersives, recadrées dans des angles doux.
- Navigation adaptative à cinq destinations et lecteur persistant.
- Densité calme : marges de 20 px, panneaux de 16 px et sections séparées de 32 px.

## Colors

La palette associe une base nocturne froide à deux voix lumineuses; les couleurs d’humeur restent confinées aux raccourcis de l’accueil.

### Primary

- **Lavande d’écoute** (`listening-lavender`): action remplie, sélection, progression, focus, logo teinté et état de lecture actif.

### Secondary

- **Cyan de signal** (`signal-cyan`): signal secondaire du thème sombre et accent de contenu; le thème clair utilise `light-signal-cyan` pour garder le même rôle sur fond pâle.

### Tertiary

- **Vert découverte** (`discovery-green`): raccourci Recherche uniquement.
- **Ambre ensemble** (`together-amber`): raccourci À plusieurs uniquement.
- **Bleu profil** (`profile-blue`): extrémité sombre du dégradé de l’avatar Profil.

### Neutral

- **Encre minuit** (`midnight-ink`): fond sombre et extrémité extérieure du halo de coque.
- **Ardoise de surface** (`slate-surface`): navigation, mini-lecteur, menus et surfaces de premier niveau.
- **Ardoise relevée** (`raised-slate`): cartes, champs et conteneurs de contenu en thème sombre.
- **Lueur nocturne** (`night-glow`): centre supérieur du fond radial sombre.
- **Texte lunaire** (`moon-text`): texte de référence du thème sombre; les niveaux secondaires réduisent son opacité.
- **Canevas clair** (`light-canvas`), **panneau clair** (`light-panel`) et **lueur claire** (`light-glow`): équivalents du fond, des cartes et du halo en thème clair.
- **Surfaces AMOLED** (`amoled-surface`, `amoled-panel`): substituts presque noirs de la surface et du panneau quand le mode AMOLED est actif; le fond devient noir pur.

### Named Rules

**The Two-Signal Rule.** La lavande porte l’action et la sélection; le cyan porte le signal secondaire. Les accents vert et ambre ne quittent pas les raccourcis d’humeur de l’accueil.

**The Palette Authority Rule.** En thème sombre, les rôles accent, secondaire, texte, fond, surface et carte peuvent être fournis par la palette Sonora; les valeurs documentées sont le repli livré.

## Typography

**Display Font:** police sans sérif native choisie par Flutter et la plateforme.
**Body Font:** la même famille système, sans police de marque ajoutée.

**Character:** Une sans sérif native, dense et familière garde les contrôles crédibles sur mobile, web et desktop. La personnalité vient des contrastes de graisse — titres très affirmés, corps retenu — plutôt que d’une fonte décorative.

### Hierarchy

- **Display** (800, `display`): valeur maximale de 36 px, réservée aux moments de forte emphase.
- **Headline** (800, `headline`): titres d’écran éditoriaux et titres de morceau principaux.
- **Heading** (700, `heading`): titres compacts et barres d’application.
- **Title** (600, `title`): titres de panneau et de section.
- **Body** (400, `body`): descriptions et informations courantes, rendues à 85 % du texte de surface dans le thème sombre.
- **Supporting** (400, `supporting`): artistes, métadonnées et temps, rendus à 60–62 % du texte de surface lorsque secondaires.
- **Navigation label** (500, `navigation-label`): libellés de navigation; la sélection passe à 700 et à la lavande.

### Named Rules

**The Native Voice Rule.** Conserver la famille système de la plateforme et exprimer la hiérarchie par la taille, la graisse et l’opacité déjà définies.

## Layout

La coque alterne entre une barre de navigation basse à cinq destinations et un rail latéral. Le rail apparaît à partir de 1100 px, ou dès 720 px sur une tablette en paysage; il mesure 88 px replié et 216 px étendu. L’extension avec mot-symbole et devise s’active à 1080 px. La barre basse mesure 72 px. Le mini-lecteur reste sous le contenu sur toutes les destinations sauf le lecteur complet; il mesure au moins 64 px et passe à 72 px à partir de 1100 px.

Le rythme principal utilise 20 px de marge latérale, 16–24 px de respiration interne et 32 px entre sections. Les contenus restent centrés avec des plafonds observés de 860 px pour Profil, 960 px pour Séances, 980–1020 px pour Explorer et 1180 px pour l’Accueil. L’accueil juxtapose la mise en avant et les ajouts récents à partir de 900 px; le lecteur juxtapose écoute et file à partir de 860 px; les cartes de séance passent en deux colonnes à 720 px. Les raccourcis d’accueil passent de deux à quatre colonnes à 720 px.

La grille d’albums appartient à Explorer : 2 colonnes sous 520 px, 3 à partir de 520 px, 4 à partir de 760 px, 5 à partir de 1080 px et 6 à partir de 1400 px. Cette grille fonctionnelle ne remplace jamais l’accueil éditorial. Les zones sûres sont respectées, et les listes restent rafraîchissables.

**The Persistent Listening Rule.** Le morceau en cours reste visible et contrôlable sous les destinations; seule la scène du lecteur complet remplace le mini-lecteur.

**The Editorial First View Rule.** Sur écran large, le premier regard rencontre le rail, l’accueil éditorial et le lecteur persistant — pas une grille catalogue générique.

## Elevation & Depth

Le système est tonal par défaut : le halo radial distingue la coque, puis les surfaces ardoise séparent navigation, cartes et champs sans ombre systématique. Les ombres sont réservées aux moments qui doivent sembler physiquement proches — morceau mis en avant, séance active, grande pochette et bouton lecture central.

### Shadow Vocabulary

- **Relief éditorial** (`0 14px 30px rgba(0,0,0,0.20)`): morceau mis en avant et séance active.
- **Pochette immersive** (`0 20px 40px rgba(0,0,0,0.32)`): grande pochette du lecteur complet.
- **Commande centrale** (`0 10px 22px rgba(62,42,128,0.27)`): bouton circulaire lecture/pause.

### Named Rules

**The Tonal-First Rule.** Utiliser les niveaux de surface pour la structure; réserver l’ombre aux éléments d’écoute qui avancent réellement vers l’utilisateur.

## Shapes

Les panneaux et grandes pochettes utilisent des angles généreux de 16 px. Les contrôles, champs, tuiles de piste et raccourcis utilisent principalement 14 px; badges et menus descendent à 12 px, listes à 10 px et miniature du mini-lecteur à 6 px. Le logo, l’avatar et les commandes principales de lecture emploient le cercle plein. Les pochettes sont toujours rognées proprement; la mise en avant peut supprimer le rayon de la pochette interne pour fondre l’image dans son panneau.

**The Soft Frame Rule.** Les angles arrondis encadrent le contenu; les cercles sont réservés à l’identité, au profil et aux actions de lecture immédiates.

## Components

### Buttons

- **Shape:** remplis et contours à 14 px en thème sombre, 10 px en thème clair; lecture/pause principale dans un cercle de 68 px.
- **Primary:** lavande avec contraste calculé pour le texte; variantes remplies, tonales et avec icône utilisent les composants Material 3.
- **Hover / Focus:** comportements Material natifs; le champ sombre expose explicitement une bordure lavande au focus.
- **Outlined:** bord blanc à 20 % en thème sombre; style Material clair par défaut en thème clair.
- **Playback state:** l’icône lecture/pause bascule par mise à l’échelle en 180 ms.

### Chips

- **Style:** `ChoiceChip` Material avec icône de 18 px pour Clair, Sombre et Auto.
- **State:** le choix sélectionné suit le rôle primaire du thème et ne change que le mode d’apparence.

### Cards / Containers

- **Corner Style:** panneau à 16 px; tuiles et actions compactes à 14 px.
- **Background:** ardoise relevée en sombre, panneau clair en clair, via `surfaceContainerHighest`.
- **Shadow Strategy:** plat au repos; seules les cartes éditoriales ou actives utilisent le relief éditorial.
- **Internal Padding:** 16 px pour les réglages et actions, 20–24 px pour les panneaux éditoriaux.

### Inputs / Fields

- **Style:** champ sombre rempli par l’ardoise relevée, sans trait au repos, avec rayon de 14 px.
- **Focus:** trait lavande d’un pixel en thème sombre; comportement Material 3 par défaut en clair.
- **Use:** recherche présentée comme une surface de 54 px de haut; code de séance limité à six caractères et associé à une action carrée de 56 px.

### Navigation

- **Large:** rail de 88/216 px sur surface ardoise à 96 %, séparé par un trait blanc à 6 %; indicateur sélectionné lavande à 18 %.
- **Compact:** barre basse Material 3 de 72 px, cinq destinations, icônes contour puis pleines à la sélection.
- **State:** lavande pour l’élément actif; texte et icônes inactifs à 54–58 %.

### Mini Player

Surface persistante avec une pochette de 44 px, titre et artiste tronqués sur une ligne, commandes précédent/lecture-suivant et séparateur supérieur à 7 %. Un toucher sur la barre ouvre le lecteur complet; l’état Cast remplace l’artiste par le nom de l’appareil en lavande.

### Featured Track

Panneau d’au moins 280 px combinant une pochette de 300 px à 68 % d’opacité, un fondu de surface de gauche à droite et une action Écouter maintenant. Le titre accepte deux lignes et l’ombre éditoriale distingue ce point de départ des listes récentes.

## Do's and Don'ts

### Do:

- **Do** garder le lecteur compact visible sous chaque destination tant qu’un morceau est en cours.
- **Do** utiliser les pochettes réelles comme matière immersive dans l’accueil et le lecteur.
- **Do** faire évoluer la navigation, les colonnes et la file d’attente aux seuils observés sans changer l’histoire fonctionnelle.
- **Do** traiter les thèmes sombre, clair et AMOLED comme des apparences nommées, avec leurs surfaces propres.
- **Do** conserver les composants et états Material 3, les zones sûres et les cibles tactiles de plateforme.

### Don't:

- **Don't** transformer l’accueil en grille de catalogue générique; la grille reste dans Explorer.
- **Don't** utiliser le cyan comme action principale ni disperser le vert et l’ambre hors de leurs raccourcis d’humeur.
- **Don't** ajouter des ombres à toutes les cartes; la séparation tonale est le comportement par défaut.
- **Don't** masquer la pochette, la progression ou les contrôles essentiels derrière un traitement décoratif.
- **Don't** figer les couleurs sombres quand une palette Sonora ou le mode AMOLED fournit les rôles actifs.
