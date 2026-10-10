# Changelog

## 4.0.0-dev.1 — 10 octobre 2026

- Identité Moon Resonance, masters SVG, icônes natives/web/TV et quatre thèmes.
- Navigation mobile, tablette portrait/paysage, desktop et TV ; recherche clavier.
- Lecteur : progression isolée des pochettes et commandes, en local et Cast ;
  suppression du log de pochette à chaque reconstruction et frontières
  d’accessibilité autour des boutons à infobulle (contournement Windows AXTree).
- Infobulles des boutons Harmonix sur Windows via OverlayEntry, avec descriptions
  accessibles conservées ; remplacement des ancres OverlayPortal concernées.
- Index SQLite isolé par serveur/compte ; migration des jetons vers le coffre.
- Imports volontaires avec métadonnées, pochettes et SHA-256 ; lecture locale
  prioritaire ; copies téléchargées sans doublon Sonora.
- Mode local, catalogues/albums/favoris/playlists mémorisés et recherche locale.
- Téléchargements : progression, pause/reprise depuis le début, restauration des
  transferts interrompus et suppression. Cache audio temporaire limité et
  désactivé par défaut, distinct des fichiers explicitement conservés.
- Playlists mixtes : révisions locales, opérations durables, synchronisation
  Sonora, conflits explicites et maintien hors connexion propre à l’appareil.
- Night, exclusions manuelles, Night Only, minuteur et fade du lecteur ; Night
  Sense déterministe et volontaire, avec suppression de l’apprentissage.
- Tag Studio `harmonix:night` reconnu par Sonora et Harmonix Night, actualisation
  du catalogue, conservation hors connexion et priorité des choix manuels.
- Écran Rift utilisable ; fichiers locaux exclus de Rift et Chromecast.
- SSO : fenêtre web préparée au clic, fermeture pilotée par l’app, retour mobile
  et premier plan desktop ; page de fin sécurisée côté Sonora.

Statut de développement : consulter `DOCS/V4-DELIVERY.md` pour les preuves,
plateformes non testées et fonctions à compléter avant la release 4.0.0.
