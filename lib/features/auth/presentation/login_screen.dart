import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/session/auth_session_tokens.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/auth/providers/sso_provider.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  bool _isSubmitting = false;
  bool _remember = true;
  bool _changeServer = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _urlController = TextEditingController(text: settings.serverUrl);
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant et mot de passe requis.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _saveServerIfChanged();
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/api/auth/login',
        options: Options(contentType: Headers.jsonContentType),
        data: {
          'identifier': identifier,
          'password': password,
          'remember': _remember,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Réponse inattendue',
        );
      }
      if (data['ok'] != true) {
        final code = data['code'] as String?;
        throw DioException(
          requestOptions: response.requestOptions,
          message: code ?? 'auth_failed',
          response: response,
        );
      }
      final tokens = AuthSessionTokens.fromJson(
        data['session'] is Map ? data['session'] : data,
      );
      if (tokens == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Token manquant',
        );
      }

      await ref.read(settingsRepositoryProvider).setAuthSession(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresInSeconds: tokens.expiresInSeconds,
          );
      ref.invalidate(dioProvider);
      ref.invalidate(authTokenProvider);
      ref.invalidate(bootstrapProvider);
      ref.read(requireLoginProvider.notifier).state = false;
      TextInput.finishAutofillContext(shouldSave: true);
      if (!mounted) return;
      context.goNamed(RouteNames.splash);
    } on DioException catch (error) {
      if (!mounted) return;
      final code = (error.response?.data is Map<String, dynamic>)
          ? (error.response?.data['code'] as String?)
          : null;
      final friendly = switch (code) {
        'unsupported_media_type' => 'Format non supporté.',
        'missing_credentials' => 'Identifiants manquants.',
        'invalid_credentials' => 'Identifiants invalides.',
        'too_many_attempts' => 'Trop de tentatives, réessaie plus tard.',
        'auth_failed' => 'Échec de l’authentification.',
        _ => null,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendly ?? 'Connexion échouée: ${error.message ?? 'erreur'}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepositoryProvider);
    final sso = ref.watch(ssoProvider);

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
                  'Connecte-toi pour activer les API Harmonix.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                _buildServerSection(context, settings),
                const SizedBox(height: 16),
                AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: 'Email ou pseudo',
                          hintText: 'toi@exemple.com',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          border: OutlineInputBorder(),
                        ),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isSubmitting) _login();
                        },
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _remember,
                  onChanged: (value) => setState(() => _remember = value),
                  title: const Text('Rester connecté'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _login,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        (_isSubmitting || sso.busy) ? null : () => _startSso(),
                    icon: sso.busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_pin_outlined),
                    label: Text(
                      sso.phase == SsoPhase.waiting
                          ? 'En attente du navigateur…'
                          : 'Se connecter avec SSO',
                    ),
                  ),
                ),
                if (sso.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    sso.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
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
    );
  }

  Future<void> _startSso() {
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
