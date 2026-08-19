import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signal déclenché quand un appel API échoue pour une raison de connexion
/// (réseau, timeout, 401, erreur serveur...). Tant qu'il est à `true`,
/// le routeur redirige vers l'écran de connexion.
final requireLoginProvider = StateProvider<bool>((ref) => false);