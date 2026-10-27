// rift_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/features/cast/providers/cast_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';

class RiftScreen extends ConsumerStatefulWidget {
  const RiftScreen({super.key});
  @override
  ConsumerState<RiftScreen> createState() => _RiftScreenState();
}

class _RiftScreenState extends ConsumerState<RiftScreen> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(riftProvider);
    final controller = ref.read(riftProvider.notifier);
    final tracks = ref.watch(tracksProvider).valueOrNull ?? [];
    final sharedQueue = session.lastSession?['queue'];
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Rift')),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text('La même musique. Ensemble.',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  const Text(
                      'Crée une séance Sonora ou rejoins tes proches avec leur code. Les fichiers personnels restent sur cet appareil.'),
                  const SizedBox(height: 24),
                  if (session.error != null)
                    Text(session.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  if (!session.isActive) ...[
                    Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                            onPressed: session.connecting
                                ? null
                                : () => controller.start(),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer une séance'))),
                    const SizedBox(height: 24),
                    TextField(
                        controller: code,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Code d’invitation'),
                        onSubmitted: (_) =>
                            controller.joinByCode(code: code.text)),
                    const SizedBox(height: 12),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                            onPressed: session.connecting
                                ? null
                                : () => controller.joinByCode(code: code.text),
                            child: const Text('Rejoindre'))),
                  ] else ...[
                    SelectableText(
                        'Code : ${session.sessionCode ?? session.sessionId}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Wrap(spacing: 12, children: [
                      TextButton.icon(
                          onPressed: () => Clipboard.setData(ClipboardData(
                              text: session.sessionCode ?? session.sessionId!)),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier le code')),
                      TextButton(
                          onPressed: () =>
                              runFlowAction(context, controller.leave),
                          child: const Text('Quitter la séance'))
                    ]),
                    const SizedBox(height: 24),
                    Text('File partagée',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (sharedQueue is List)
                      for (final id in sharedQueue.whereType<String>())
                        ListTile(
                            title: Text(tracks
                                    .where((t) => t.id == id)
                                    .map((t) => t.title)
                                    .firstOrNull ??
                                id),
                            onTap: () => runFlowAction(
                                context, () => controller.queuePlay(id)),
                            trailing: FlowIconButton(
                                tooltip: 'Retirer de la file',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => runFlowAction(context,
                                    () => controller.queueRemove(id)))),
                    const SizedBox(height: 24),
                    Text('Ajouter une musique',
                        style: Theme.of(context).textTheme.titleLarge),
                    for (final track
                        in tracks.where((t) => !t.id.startsWith('local:')))
                      ListTile(
                          title: Text(track.title),
                          subtitle: Text(track.artist),
                          trailing: FlowIconButton(
                              tooltip: 'Ajouter à la file partagée',
                              icon: const Icon(Icons.add),
                              onPressed: () => runFlowAction(context,
                                  () => controller.queueAdd(track.id)))),
                  ],
                  if (session.connecting)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: LinearProgressIndicator()),
                ]))));
  }
}
