import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/update/update_checker.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';
import 'package:harmonix_apps/core/api/api_exception.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/widgets/error_view.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _didCheckUpdate = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);

    bootstrap.whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _isNavigating) return;
        if (!_didCheckUpdate) {
          _didCheckUpdate = true;
          final canContinue = await _checkForUpdates();
          if (!canContinue || !mounted) return;
        }
        _isNavigating = true;
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

  Future<bool> _checkForUpdates() async {
    try {
      final dio = ref.read(dioProvider);
      final info = await checkForUpdate(
        dio: dio,
        packageInfo: await PackageInfo.fromPlatform(),
      );
      if (info == null) return true;
      final forceUpdate = info.forceUpdate;
      final updateAvailable = info.updateAvailable;
      final latest = info.latestVersion;
      final downloadUrl = info.downloadUrl;

      if (!forceUpdate && !updateAvailable) return true;

      await _showUpdateDialog(
        forceUpdate: forceUpdate,
        latest: latest,
        downloadUrl: downloadUrl,
      );
      return !forceUpdate;
    } catch (_) {
      return true;
    }
  }

  Future<void> _showUpdateDialog({
    required bool forceUpdate,
    String? latest,
    String? downloadUrl,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text(
          latest != null
              ? 'Une nouvelle version ($latest) est disponible.'
              : 'Une nouvelle version est disponible.',
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
          FilledButton(
            onPressed: () async {
              if (downloadUrl != null) {
                final uri = Uri.tryParse(downloadUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

}
