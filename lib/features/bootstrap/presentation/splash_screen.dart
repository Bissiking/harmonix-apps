import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonix_apps/core/update/update_checker.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';
import 'package:harmonix_apps/core/api/api_exception.dart';
import 'package:harmonix_apps/core/theme/theme_provider.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/widgets/error_view.dart';
import 'package:harmonix_apps/shared/widgets/update_download_dialog.dart';

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
          await ref.read(themeControllerProvider.notifier).syncFromApi();
          final canContinue = await _checkForUpdates();
          if (!canContinue || !mounted) return;
        }
        _isNavigating = true;
        if (context.mounted) context.go('/home');
      });
    });

    return Scaffold(
      backgroundColor: HarmonixColors.darkBackground,
      body: bootstrap.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HarmonixColors.accent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: HarmonixColors.accent.withValues(alpha: 0.55),
                  ),
                ),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    HarmonixColors.accent,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/logo_harmonix.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Harmonix',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: HarmonixColors.accent,
                  letterSpacing: -0.4,
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
                    onPressed: () => context.go('/home'),
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
      final info = await checkForUpdate(
        packageInfo: await PackageInfo.fromPlatform(),
      );
      if (info == null) return true;

      if (!info.forceUpdate && !info.updateAvailable) return true;

      await _showUpdateDialog(info: info);
      return !info.forceUpdate;
    } catch (_) {
      return true;
    }
  }

  Future<void> _showUpdateDialog({required UpdateInfo info}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.latestVersion != null
                  ? 'Une nouvelle version (${info.latestVersion}) est disponible.'
                  : 'Une nouvelle version est disponible.',
            ),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                info.releaseNotes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (isDesktopPlatform) {
                await _downloadAndInstall(info);
              } else {
                final uri = Uri.tryParse(info.downloadUrl ?? '');
                if (uri != null) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (!mounted) return;
    final file = await showUpdateDownloadDialog(context, info);
    if (file == null || !mounted) return;
    final opened = await launchUrl(
      Uri.file(file.path),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mise à jour vérifiée (SHA-256 OK). Fichier : ${file.path}',
          ),
        ),
      );
    }
  }
}
