import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_controller.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_provider.dart';

/// TV controls use Material focus traversal and remain usable with a D-pad.
class DeviceLoginPanel extends ConsumerWidget {
  const DeviceLoginPanel({super.key, this.beforeStart, this.enabled = true});
  final bool enabled;
  final Future<void> Function()? beforeStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceLoginProvider);
    final controller = ref.read(deviceLoginProvider.notifier);
    final waiting = state.phase == DeviceLoginPhase.waiting;
    final message = switch (state.phase) {
      DeviceLoginPhase.denied =>
        'Connexion refusée. Tu peux demander un nouveau code.',
      DeviceLoginPhase.expired =>
        'Ce code a expiré. Demande un nouveau code pour continuer.',
      DeviceLoginPhase.unavailable =>
        'Connexion par code indisponible. Réessaie ou utilise le navigateur.',
      DeviceLoginPhase.requesting => 'Préparation du code…',
      DeviceLoginPhase.saving => 'Enregistrement de la connexion…',
      _ => 'Connecte cette TV depuis ton téléphone ou ton ordinateur.',
    };
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Connecter la TV',
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      if (waiting) ...[
        const Text('Scanne le QR ou ouvre cette adresse :',
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        SelectableText(state.verificationUri.toString(),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Semantics(
            label: 'Code de connexion ${state.userCode}',
            child: Text(state.userCode!,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        ExcludeSemantics(
            child: ColoredBox(
                color: Colors.white,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                        data: state.qrUri.toString(),
                        size: 176,
                        backgroundColor: Colors.white)))),
        const SizedBox(height: 16),
        const Text(
            'Compare le code sur Kyros avant d’autoriser la TV.\nEn attente de ton accord…',
            textAlign: TextAlign.center),
      ] else
        Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      if (!state.busy)
        FilledButton.icon(
            autofocus: true,
            onPressed: !enabled
                ? null
                : () async {
                    try {
                      await beforeStart?.call();
                      if (context.mounted) {
                        await ref.read(deviceLoginProvider.notifier).start();
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Adresse du serveur invalide ou indisponible.')));
                      }
                    }
                  },
            icon: const Icon(Icons.tv),
            label: Text(state.phase == DeviceLoginPhase.idle
                ? 'Afficher un code'
                : 'Demander un nouveau code')),
      if (state.phase == DeviceLoginPhase.requesting ||
          state.phase == DeviceLoginPhase.saving)
        const LinearProgressIndicator(),
      if (state.busy && state.phase != DeviceLoginPhase.saving)
        TextButton(onPressed: controller.reset, child: const Text('Annuler')),
    ]);
  }
}
