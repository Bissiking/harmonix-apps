import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/api/dio_provider.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/settings/auth_token_provider.dart';
import '../../../core/settings/settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

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

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsRepositoryProvider);
    final authToken = ref.watch(authTokenProvider);
    final hasToken = authToken?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Serveur',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL du serveur',
              hintText: 'http://192.168.1.x:3000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final url = _urlController.text.trim();
              if (url.isEmpty) return;
              await ref
                  .read(settingsRepositoryProvider)
                  .setServerUrl(url);
              ref.invalidate(dioProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL mise à jour — relancez l\'app.')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
          const SizedBox(height: 24),
          Text(
            'Authentification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (!hasToken)
            FilledButton(
              onPressed: () => context.goNamed(RouteNames.login),
              child: const Text('Se connecter'),
            )
          else
            TextButton(
              onPressed: () async {
                await ref.read(settingsRepositoryProvider).setAuthToken(null);
                ref.invalidate(dioProvider);
                ref.invalidate(authTokenProvider);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnecté.')),
                  );
                }
              },
              child: const Text('Se déconnecter'),
            ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'À propos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info == null
                  ? '...'
                  : 'v${info.version}+${info.buildNumber}';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Harmonix Apps'),
                subtitle: Text(version),
              );
            },
          ),
        ],
      ),
    );
  }
}
