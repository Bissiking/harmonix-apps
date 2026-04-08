import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../providers/bootstrap_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/theme/color_scheme.dart';
import '../../../shared/widgets/error_view.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);

    bootstrap.whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/catalog');
      });
    });

    return Scaffold(
      backgroundColor: HarmonixColors.darkBackground,
      body: bootstrap.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_harmonix.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'harmonix',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: HarmonixColors.accent,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: HarmonixColors.accent),
            ],
          ),
        ),
        data: (_) => const SizedBox.shrink(),
        error: (e, _) {
          final apiError = _apiError(e);
          final isOffline = apiError is NetworkException ||
              apiError is NetworkTimeoutException;
          final isUnauthorized = apiError is UnauthorizedException;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ErrorView(
                error: e,
                onRetry: () => ref.invalidate(bootstrapProvider),
              ),
              if (isOffline)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.tonal(
                    onPressed: () => context.go('/catalog'),
                    child: const Text('Continuer hors ligne'),
                  ),
                ),
              if (isUnauthorized)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Se connecter'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ApiException? _apiError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }
}
