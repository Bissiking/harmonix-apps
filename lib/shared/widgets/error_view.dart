import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _message(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }

  String _message(Object error) => switch (error) {
        NetworkTimeoutException() =>
          'Délai dépassé. Vérifiez votre connexion.',
        NetworkException(:final message) => 'Connexion impossible : $message',
        NotFoundException() => 'Ressource introuvable.',
        UnauthorizedException() => 'Authentification requise.',
        ServerException(:final code, :final feature) =>
          feature != null ? 'Fonctionnalité "$feature" à venir.' : 'Erreur serveur : $code',
        _ => error.toString(),
      };
}
