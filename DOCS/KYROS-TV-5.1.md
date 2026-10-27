# Connexion TV Kyros — Harmonix V4

27 octobre 2026. Branche `matheo`, version `4.0.0-dev.1+40000` en cours.

La détection TV V4 ouvre une connexion par appareil : URL/code manuel et QR,
attente de l’approbation sur Kyros, refus/expiration et nouvelle demande.
Le bouton « Utiliser le navigateur » conserve le relais Sonora existant.
L’annulation ignore toute réponse encore en vol. Aucun secret client Kyros
n’est embarqué ; le code d’appareil reste en mémoire et n’entre pas dans le QR.

## Activation

- Kyros SSO v4 : activer explicitement la connexion appareil sur le client Sonora
  existant ; conserver ses scopes, audiences et callbacks.
- Sonora 6.2.2 corrigé : définir `KYROS_DEVICE_AUTHORIZATION_ENABLED=true`,
  `KYROS_BASE_URL` et `KYROS_TOKEN_URL` sur la même origine HTTPS Kyros.
- Le client charge `/api/harmonix/apps/v2/sso/device-config` sur le serveur Sonora
  choisi, puis appelle directement Kyros avec le seul `client_id` public.
- Le renouvellement reste `/api/auth/refresh` côté Sonora. Une panne doit renvoyer
  `503` ; seul un refus définitif doit renvoyer `401`.

Hors loopback, HTTP et les redirections sont refusés par le client appareil.
Une capacité absente propose la nouvelle tentative, le navigateur ou l’écoute
hors connexion ; elle n’active pas silencieusement un client Kyros.

## Validation locale

- `flutter test` : 57 tests réussis, dont 15 tests TV nouveaux. Le test réseau
  optionnel est ignoré hors du lanceur Kyros.
- `flutter analyze --no-pub` : aucun problème.
- `flutter build apk --debug --no-pub` : APK compilé.
- `test/device_login_live_test.dart` : exécuté séparément par le lanceur Kyros
  `npm run qa:harmonix-live` avec les deux checkouts indiqués par variables
  d’environnement ; vrais Kyros/PostgreSQL et Sonora/SQLite jetables.
- Réseau réel : approbation, autre compte refusé, tokens acceptés par Sonora,
  stockage sécurisé simulé/relecture, refresh concurrent, panne, refus/expiration,
  repli navigateur PAR/PKCE et consommation unique, révocation.
- Captures `validation/tv-login-{1280,1920,390}.png`, code et QR contrôlés ; QR
  décodés vers l’URL de vérification avec le seul code utilisateur.

La validation utilise Flutter sur Windows, pas une TV physique. Le coffre natif
est simulé par Flutter ; télécommande/OS Android, lancement du navigateur système
et stockage sécurisé réel restent à essayer sur matériel. La V4 reste en cours.
