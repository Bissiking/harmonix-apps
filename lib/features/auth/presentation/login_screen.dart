import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/auth/providers/sso_provider.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _urlController;
  bool _changeServer = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _urlController = TextEditingController(text: settings.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveServerIfChanged() async {
    final url = _urlController.text.trim();
    if (!_changeServer || url.isEmpty) return;
    final settings = ref.read(settingsRepositoryProvider);
    if (url == settings.serverUrl) return;
    await settings.setServerUrl(url);
    ref.invalidate(dioProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepositoryProvider);
    final sso = ref.watch(ssoProvider);
    final busy = sso.busy;

    ref.listen(ssoProvider, (previous, next) {
      if (next.phase == SsoPhase.done && previous?.phase != SsoPhase.done) {
        context.goNamed(RouteNames.splash);
      }
    });

    return Scaffold(
      backgroundColor: HarmonixColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_harmonix.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connecte-toi avec ton compte Kyros pour activer les API Harmonix.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _startSso,
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_pin_outlined),
                      label: Text(
                        busy
                            ? 'En attente du navigateur…'
                            : 'Connexion avec Kyros',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (sso.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      sso.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildServerSection(context, settings),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(ssoProvider.notifier).reset();
                      ref.read(requireLoginProvider.notifier).state = false;
                      context.goNamed(RouteNames.splash);
                    },
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startSso() async {
    await _saveServerIfChanged();
    return ref.read(ssoProvider.notifier).start();
  }

  Widget _buildServerSection(
      BuildContext context, SettingsRepository settings) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, color: color.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Serveur : ${_displayUrl(settings.serverUrl)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _changeServer,
            onChanged: (value) =>
                setState(() => _changeServer = value ?? false),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Changer de serveur'),
          ),
          if (_changeServer) ...[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL du serveur',
                hintText: 'https://sonora.mhemery.fr',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  String _displayUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'sonora.mhemery.fr';
    return trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : trimmed;
  }
}