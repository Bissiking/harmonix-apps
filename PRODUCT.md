# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Harmonix s'adresse aux personnes qui écoutent leur bibliothèque Sonora sur téléphone, navigateur et ordinateur, avec une continuité de lecture entre leurs appareils.

## Product Purpose

Harmonix permet de parcourir un catalogue musical public, rechercher des pistes et albums, lancer et reprendre une lecture, gérer ses favoris, rejoindre des séances d'écoute partagées et régler l'application depuis une interface cohérente sur chaque plateforme.

## Positioning

Une seule application Flutter relie le catalogue auto-hébergé Sonora, la lecture locale ou castée et les séances Rift, avec une session Kyros commune et renouvelée à chaud.

## Operating Context

L'application est utilisée sur mobile, web, Windows et macOS. Sur mobile, les destinations principales restent accessibles au pouce. Sur les écrans larges, un rail latéral libère l'espace pour le catalogue et la file de lecture. Le backend Sonora reste la source de vérité des morceaux, albums, favoris, états de lecture, thèmes et séances Rift.

## Capabilities and Constraints

- Conserver Flutter et Riverpod comme socle partagé.
- Utiliser uniquement les morceaux publics dans Harmonix.
- Préserver l'authentification Kyros, le refresh à chaud et les contrats Sonora existants lorsque possible.
- Les destinations principales confirmées sont Accueil, Explorer, Lecteur, Séances et Profil.
- La navigation doit s'adapter entre barre inférieure mobile et rail latéral web/desktop.
- Toute modification backend nécessaire est autorisée dans le dépôt Sonora adjacent.

## Brand Commitments

Le nom Harmonix et son logo existant sont conservés. La référence visuelle fournie par l'utilisateur est contraignante : univers nocturne bleu encre, surfaces légèrement relevées, accents violet/lavande et cyan, grandes pochettes immersives et iconographie sobre.

## Evidence on Hand

- Logo : `assets/images/logo_harmonix.png`.
- Données et parcours réels présents dans les dépôts `harmonix-apps` et `sonora`.
- Maquette multi-plateforme fournie dans la conversation comme référence de composition et de niveau de finition.
- Aucun témoignage, prix ou argument commercial ne doit être inventé.

## Product Principles

- La musique en cours reste visible et contrôlable depuis toutes les destinations.
- La même hiérarchie fonctionnelle s'adapte aux conventions de chaque taille d'écran.
- Les données réelles remplacent tout contenu décoratif fictif de la maquette.
- Une interruption réseau ne doit pas casser brutalement l'écoute ou la session.
- L'interface privilégie la lisibilité, les gestes familiers et les cibles tactiles accessibles.

## Accessibility & Inclusion

Respecter les zones sûres, les gestes Retour natifs, des cibles tactiles d'au moins 48 dp sur Android et 44 pt sur iOS, le redimensionnement du texte, le contraste en thème sombre et la réduction des animations du système.
