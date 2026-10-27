# Sonora — intégration Harmonix Flow

Code modifié dans `D:/DEV/NODEJS/sonora`, version initialement vérifiée 6.1.0,
puis 6.2.0 pour l’intégration des tags Night. Aucun déploiement effectué.
Studio 0.2.0 transmet `/auth` et `/api` à Sonora ; l’intégration SSO n’exige pas
de modification Studio. Le parcours d’édition Night ajoute un champ de tags
dans Studio. Les anciens endpoints v2 restent présents.

`sonora-v4.patch` fournit une copie des changements pour un checkout Sonora
correspondant au même état de départ. Le dépôt local indiqué est déjà modifié :
ne pas lui appliquer le patch une seconde fois.

## Tag Night depuis SonoraStudio

Dans **Musique → Modifier la piste → Genres et tags**, ajouter
`harmonix:night`, séparé des autres valeurs par `;`, puis enregistrer.
Le champ est également disponible à la publication. Exemple :
`Ambient ; harmonix:night`. Le morceau doit être public pour être visible dans
le catalogue Harmonix, comme avant cette intégration.

Sonora reconnaît un tag entier après suppression des espaces périphériques,
sans tenir compte de la casse. `night`, `harmonix:night-only` et les genres
`Ambient`/`Piano` seuls n’activent pas cet opt-in. Le marqueur exprime une
affectation Night éditoriale ; il ne certifie pas les caractéristiques audio.

Le mapper des pistes Harmonix ajoute `night_eligible: true|false` aux réponses
catalogue, recherche, détail, albums et autres routes qui utilisent ce mapper.
L’indicateur est calculé depuis les genres enregistrés, sans migration SQL.
`PATCH /api/studio/music/:id` accepte maintenant `genres` sous forme de chaîne
séparée par `;`, tableau de chaînes ou `null` (effacement). Un champ omis conserve
les genres existants ; les types invalides retournent `INVALID_GENRES` (400).
La permission `tracks:update` et les règles de visibilité ne changent pas.

Harmonix Night charge le catalogue à sa première ouverture ; le bouton
**Actualiser la bibliothèque Night** recharge les changements Studio. En mode
**Automatique**, le tag autorise le morceau. **Toujours exclu** et **Toujours
autorisé** restent prioritaires sur cet appareil. Retirer le tag retire
l’autorisation automatique après actualisation, sans modifier les choix manuels.
Le tag n’active pas **Night Only** et ne choisit pas une catégorie. Les morceaux
apparaissent par défaut dans **Mélange relaxant** ; la catégorie reste réglable
dans Harmonix.

L’indicateur est conservé dans le catalogue SQLite pour les sessions hors
connexion. Les métadonnées du catalogue actualisé priment sur une ancienne
copie téléchargée, sans supprimer son fichier audio. Un ancien serveur qui ne
renvoie pas le champ conserve le comportement manuel précédent.

Patches additionnels : `sonora-night-tag.patch` (base Sonora 6.2.0) et
`sonora-studio-night-tag.patch` (Studio 0.2.0). Ils sont déjà appliqués aux dépôts
locaux ; ne pas les y appliquer une seconde fois. Déployer Sonora et Studio,
puis utiliser une build Harmonix contenant ce changement.

Validation : 21 tests Sonora, 40 tests Flutter, analyse Flutter et build Studio.
Le parcours sur le serveur public reste à vérifier après déploiement.

## SSO

Le relais `GET /api/harmonix/apps/v2/sso/start?state=...&platform=...` conserve la
plateforme. Le callback Sonora `/auth/callback` termine le flow app par une page
HTML avec CSP à nonce, `no-store` et `no-referrer`, sans jeton dans le HTML.
La page retire les paramètres de sa propre URL. Android/iOS utilisent uniquement
le lien autorisé `harmonix://auth/sso-complete`. Le client continue de récupérer
la session via le polling `v2/sso/status`, dont la consommation est unique.

Le web ouvre une fenêtre au clic puis l’app ferme cette fenêtre après réception
des jetons. Sur mobile, un navigateur intégré est privilégié. Sur desktop,
l’application revient au premier plan. Un onglet externe non créé par un script
ne peut pas être forcé à se fermer : la page propose le retour et explique ce cas.
Le callback historique Studio avec cookie n’est pas remplacé.

## Playlists mixtes : contrat implémenté

Préfixe : `/api/harmonix/apps/v2/mixed-playlists`.

| Méthode | Route | Permission | Effet |
|---|---|---|---|
| GET | `/` | `playlists:read` | Versions du compte, suppressions comprises |
| PUT | `/:id` | `playlists:own` | Compare-and-swap et replay idempotent |

Le bootstrap annonce `capabilities.mixed_playlists: true`. Un ancien serveur
sans cette capacité reste utilisable : les playlists mixtes restent locales.

Identifiant playlist : `device:` + 32 caractères hexadécimaux. Body PUT :

```json
{
  "operationId": "0123456789abcdef0123456789abcdef",
  "baseRevision": 0,
  "name": "Mon mix",
  "deleted": false,
  "entries": [
    {"trackId":"sonora-id","source":"sonora","title":"Piano","artist":"Artiste","durationMs":180000},
    {"trackId":"local:<sha256>","source":"local","fingerprint":"<sha256>","title":"Mon fichier","artist":"Moi","durationMs":120000}
  ]
}
```

Les placeholders `<sha256>` représentent 64 caractères hexadécimaux ; ils ne
sont pas des valeurs acceptées telles quelles. Les références sont ordonnées et
uniques. Au maximum 2 000 entrées. Seules les métadonnées autorisées sont
persistées : aucun chemin, streamUrl, coverUrl ou fichier audio.

Réponse réussie : `{ok:true,data:{id,name,entries,deleted,revision}}`.
Création à baseRevision 0 puis révisions serveur croissantes. Une requête obsolète
répond 409 `{ok:false,error:"playlist_conflict",current:...}`. Les écritures
SQLite sont atomiques. Rejouer la dernière opération identique ne crée pas de
nouvelle révision. Une opération ancienne dépassée produit un conflit plutôt
qu’un double effet. Les suppressions sont des tombstones.

Migration additive : table `harmonix_mixed_playlists`, clé `(owner,id)` ; aucune
altération des tables de playlists existantes. Vérifier les permissions Kyros des
comptes concernés avant mise en production.

## Comportement client

SQLite conserve compositions, révisions serveur connues, opération aléatoire
persistante et suppressions en attente. Synchronisation au démarrage, à la
reconnexion du mode local et périodiquement tant que l’app est ouverte ; bouton
manuel disponible. Un conflit conserve la composition locale et la version
distante. La résolution explicite crée une copie locale avant d’accepter la
version distante. Une suppression locale conflictuelle peut être annulée par
l’acceptation explicite de la version distante.

`keepOffline` reste propre à l’appareil et n’est pas envoyé à Sonora. Les
téléchargements automatiques ne transportent que les titres Sonora. Les fichiers
personnels absents restent référencés et peuvent être retrouvés par import d’une
copie identique, reconnue au SHA-256.

## Vérification et limites

`npm test` : tests existants, page SSO, validation de payload, concurrence,
idempotence et isolation des propriétaires. Ajouter une validation réseau de
bout en bout avec Kyros configuré avant déploiement. L’API actuelle ne garantit
pas un choix de qualité transcodée, un checksum distant ni une reprise Range/ETag.
Harmonix conserve donc la qualité originale, valide longueur/type et empreinte
locale, et reprend les téléchargements depuis le début.
