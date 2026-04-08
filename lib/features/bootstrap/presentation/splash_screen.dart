import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/bootstrap_provider.dart';
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
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'harmonix',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: HarmonixColors.accent,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: HarmonixColors.accent),
            ],
          ),
        ),
        data: (_) => const SizedBox.shrink(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(bootstrapProvider),
        ),
      ),
    );
  }
}
