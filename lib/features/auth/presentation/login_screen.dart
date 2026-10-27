import 'package:flutter/material.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_controller.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_provider.dart';
import 'package:harmonix_apps/features/auth/presentation/device_login_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/auth/providers/sso_provider.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/widgets/harmonix_logo.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

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
    ref.invalidate(deviceLoginProvider);
    ref.invalidate(dioProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepositoryProvider);
    final sso = ref.watch(ssoProvider);
    final tv = ref.watch(isTelevisionProvider).valueOrNull ?? false;
    final device = ref.watch(deviceLoginProvider);
    final busy = sso.busy || device.busy;
    ref.listen(deviceLoginProvider, (previous, next) {
      if (next.phase == DeviceLoginPhase.done &&
          previous?.phase != DeviceLoginPhase.done) {
        context.goNamed(RouteNames.splash);
      }
    });

    ref.listen(ssoProvider, (previous, next) {
      if (next.phase == SsoPhase.done && previous?.phase != SsoPhase.done) {
        context.goNamed(RouteNames.splash);
      }
    });

    if (tv) return _buildTvScreen(context, busy, sso.error);

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
                  const HarmonixLogo(size: 120),
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
                  if (tv) ...[
                    DeviceLoginPanel(
                        beforeStart: _saveServerIfChanged, enabled: !sso.busy),
                    const SizedBox(height: 24),
                  ],
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
                            : (tv
                                ? 'Utiliser le navigateur'
                                : 'Connexion avec Kyros'),
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
                  TextButton.icon(
                      onPressed: device.phase == DeviceLoginPhase.saving
                          ? null
                          : () async {
                              ref.read(deviceLoginProvider.notifier).reset();
                              ref.read(ssoProvider.notifier).reset();
                              await ref
                                  .read(offlineModeProvider.notifier)
                                  .setEnabled(true);
                              if (context.mounted) context.go('/library');
                            },
                      icon: const Icon(Icons.cloud_off),
                      label: const Text('Écouter hors connexion')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: device.phase == DeviceLoginPhase.saving
                        ? null
                        : () {
                            ref.read(deviceLoginProvider.notifier).reset();
                            ref.read(ssoProvider.notifier).reset();
                            ref.read(requireLoginProvider.notifier).state =
                                false;
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

  Widget _buildTvScreen(BuildContext context, bool busy, String? error) {
    final settings = ref.watch(settingsRepositoryProvider);
    final saving =
        ref.watch(deviceLoginProvider).phase == DeviceLoginPhase.saving;
    final controls = Column(mainAxisSize: MainAxisSize.min, children: [
      const HarmonixLogo(size: 80),
      const SizedBox(height: 16),
      Text('Harmonix', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
              onPressed: busy ? null : _startSso,
              icon: const Icon(Icons.open_in_browser),
              label: Text(ref.watch(ssoProvider).busy
                  ? 'En attente du navigateur…'
                  : 'Utiliser le navigateur'))),
      if (error != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 24),
      _buildServerSection(context, settings),
      const SizedBox(height: 16),
      TextButton.icon(
          onPressed: saving
              ? null
              : () async {
                  ref.read(deviceLoginProvider.notifier).reset();
                  ref.read(ssoProvider.notifier).reset();
                  await ref.read(offlineModeProvider.notifier).setEnabled(true);
                  if (context.mounted) context.go('/library');
                },
          icon: const Icon(Icons.cloud_off),
          label: const Text('Écouter hors connexion')),
      TextButton(
          onPressed: saving
              ? null
              : () {
                  ref.read(deviceLoginProvider.notifier).reset();
                  ref.read(ssoProvider.notifier).reset();
                  ref.read(requireLoginProvider.notifier).state = false;
                  context.goNamed(RouteNames.splash);
                },
          child: const Text('Retour')),
    ]);
    final panel = DeviceLoginPanel(
        beforeStart: _saveServerIfChanged,
        enabled: !ref.watch(ssoProvider).busy);
    return Scaffold(
        backgroundColor: HarmonixColors.darkBackground,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 48),
                                          child: panel)),
                                  SizedBox(width: 380, child: controls),
                                ]);
                          }
                          return Column(children: [
                            panel,
                            const SizedBox(height: 32),
                            controls
                          ]);
                        }))))));
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
            onChanged: ref.watch(deviceLoginProvider).busy ||
                    ref.watch(ssoProvider).busy
                ? null
                : (value) => setState(() => _changeServer = value ?? false),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Changer de serveur'),
          ),
          if (_changeServer) ...[
            TextField(
              controller: _urlController,
              enabled: !ref.watch(deviceLoginProvider).busy &&
                  !ref.watch(ssoProvider).busy,
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
