# Kyros V5 — besoins Harmonix à transmettre

Document d’intégration, 10 octobre 2026. **Harmonix 4.0.0, Sonora 6.1.0 et le
protocole Kyros v4 ont des versions indépendantes.** Aucun code Kyros V5 ni Vault
n’a été inventé ou activé dans Harmonix. Les chemins proposés ci-dessous ne
signifient pas que ces services existent aujourd’hui.

## Contrat actuellement consommé et vérifié dans Sonora

Sonora utilise des URL configurables `KYROS_PAR_URL`, `KYROS_AUTHORIZE_URL`,
`KYROS_TOKEN_URL`, `KYROS_REVOKE_URL`, avec replis `${KYROS_BASE_URL}/par`,
`/authorize`, `/token`, `/revoke`.

| Endpoint actuel | Contenu consommé |
|---|---|
| POST `/par` | JSON client_id, secret côté serveur selon client_auth, redirect_uri, scope, state, code_challenge S256 et handshake Kyros |
| GET `/authorize` | client_id et request_uri retourné par PAR |
| POST `/token` | authorization_code + code_verifier, ou refresh_token ; réponse access_token, refresh_token, expires_in |
| POST `/revoke` | Révocation côté serveur selon la configuration actuelle |

Le handshake contient `kyros_sso_version` (défaut v4), `kyros_edition` et
`kyros_application_scope`. Le callback configuré est le domaine Studio suivi de
`/auth/callback`, relayé à Sonora. Il vérifie l’issuer et la transaction PKCE.
Les clients Harmonix ne possèdent jamais le client_secret.

Validation des access tokens : issuer, audience et algorithmes configurés ;
JWKS explicites ou configurés, ou `KYROS_VALIDATION_URL`. `sub` doit être une
identité stable du compte. Sonora expose ensuite ses routes de relais :

- GET `/api/harmonix/apps/v2/sso/start` : state aléatoire et plateforme.
- GET `/api/harmonix/apps/v2/sso/status` : jetons consommables une seule fois.
- POST `/api/auth/refresh` : body refresh_token, rotation de session.
- POST `/api/auth/login` et `/session` répondent actuellement 410 : navigateur
  requis ; ne pas réintroduire un écran mot de passe propriétaire dans Harmonix.

## Besoin V5 : connexion Android TV depuis un autre appareil

**Contrat proposé, non implémenté.** Prévoir un flow d’autorisation d’appareil
avec chemins configurables, par exemple POST `/device/authorize` et POST
`/token`. La première réponse fournirait device_code, user_code,
verification_uri, verification_uri_complete, expires_in et interval. Le client
TV afficherait URL/code/QR, puis sonderait `/token` avec le grant d’appareil.

États nécessaires : authorization_pending, slow_down, access_denied,
expired_token. Borner essais et durée, rendre le code consommable une seule fois,
limiter les tentatives et lier son approbation au compte et à l’appareil affiché.
Un refus ou une expiration ne doit pas connecter un autre compte. Aucun secret
confidentiel distribué dans l’application TV. Le fallback actuel reste le
navigateur SSO quand l’appareil le permet ; ne pas annoncer un flow QR fonctionnel
tant que le service Kyros ne l’expose pas.

## Besoin V5 : identité, rotation et déconnexion

- Garder `sub` stable lors des rotations, afin de retrouver les médias locaux du
  bon compte. Ne pas changer d’identité locale avec chaque access_token.
- Documenter issuer, audience, permissions et leur découverte ; conserver les
  routes Sonora musicales v2, indépendantes de la version SSO.
- Distinguer refresh invalide/révoqué (400/401) et indisponibilité temporaire
  (5xx/timeout). Une panne Kyros ne doit pas effacer une session locale valide.
- Documenter une révocation de refresh token et ses effets. Le logout applicatif
  et la suppression des fichiers locaux sont deux opérations distinctes.

## Besoin futur Vault : synchronisation privée volontaire

**Proposition uniquement.** Familles de capacités à définir côté Kyros :
consentements par catégorie, export/import versionné, effacement, révocation,
révisions et conflits. Catégories séparées : bibliothèque, historique de lecture,
préférences et Night Sense. Un consentement bibliothèque n’autorise pas les
habitudes Night. Ne jamais transférer les fichiers musicaux personnels au titre
d’une synchronisation des références.

L’API doit rendre visibles destinataire, portée, durée et révocation du
consentement. Prévoir suppression serveur et locale séparées. Décider le modèle
de chiffrement et la gestion des clés avant de publier des endpoints Vault.
Dans Harmonix livré ici, Night Sense est local, désactivé par défaut, isolé par
compte/serveur et effaçable ; aucun appel Vault n’est effectué.

## Tests d’acceptation à prévoir côté V5

PKCE/PAR complet, state incorrect/rejoué, issuer incorrect, code expiré,
rotation concurrente, panne temporaire, révocation, connexion TV sans navigateur,
refus TV, limitation de polling, changement de compte et consentements granulaires.
La fermeture d’un onglet externe est une contrainte navigateur ; Kyros peut
fournir une bonne page de retour mais ne peut pas forcer tous les navigateurs.
