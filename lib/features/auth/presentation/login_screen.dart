import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/api/dio_provider.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/settings/auth_token_provider.dart';
import '../../../core/settings/settings_repository.dart';
import '../../bootstrap/providers/bootstrap_provider.dart';
import '../../../shared/theme/color_scheme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  bool _isSubmitting = false;
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      final token = data['access_token'] as String? ??
          (data['session'] as Map?)?['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Token manquant',
        );
      }

      await ref.read(settingsRepositoryProvider).setAuthToken(token);
      ref.invalidate(dioProvider);
      ref.invalidate(authTokenProvider);
      ref.invalidate(bootstrapProvider);
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.splash),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
