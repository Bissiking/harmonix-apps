import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:harmonix_apps/core/api/api_exception.dart';

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

  String _message(Object error) {
    final apiError = _apiError(error);
    return switch (apiError ?? error) {
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

  ApiException? _apiError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }
}
