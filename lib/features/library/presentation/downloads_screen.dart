// downloads_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/features/library/data/audio_cache.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

final _cacheSettingsRevisionProvider = StateProvider<int>((ref) => 0);

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(deviceTracksProvider).valueOrNull ?? [];
    ref.watch(_cacheSettingsRevisionProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final cached = ref.watch(audioCacheEntriesProvider).valueOrNull ?? [];
    final cacheBytes =
        cached.fold<int>(0, (sum, row) => sum + (row['file']['bytes'] as int));
    final downloads =
        files.where((f) => f.source == MusicSource.downloaded).toList();
    final transfers = ref.watch(transfersProvider).values.toList();
    final bytes = downloads.fold<int>(0, (sum, file) => sum + file.bytes);
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Téléchargements')),
        body: !supportsDeviceFiles
            ? const FlowEmptyState(
                icon: Icons.download_for_offline_outlined,
                title: 'Écoute hors connexion sur l’application native',
                message:
                    'Le navigateur conserve les métadonnées. Les fichiers audio persistants nécessitent Android, iOS ou un ordinateur.')
            : ListView(padding: const EdgeInsets.all(24), children: [
                Text(
                    '${downloads.length} titres · ${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                    'Qualité originale du flux Sonora. Les téléchargements conservés ne sont pas supprimés automatiquement.'),
                const SizedBox(height: 24),
                Text('Cache audio temporaire',
                    style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Réutiliser les titres écoutés'),
                    subtitle: Text(
                        '${(cacheBytes / (1024 * 1024)).toStringAsFixed(1)} Mo · récupération supplémentaire du flux sur toute connexion. Désactivé par défaut.'),
                    value: settings.audioCacheEnabled,
                    onChanged: (value) async {
                      await settings.setAudioCacheEnabled(value);
                      ref.invalidate(audioCacheControllerProvider);
                      ref.read(_cacheSettingsRevisionProvider.notifier).state++;
                    }),
                DropdownButtonFormField<int>(
                    initialValue: settings.audioCacheLimitMb,
                    decoration: const InputDecoration(
                        labelText: 'Limite du cache temporaire'),
                    items: [
                      for (final size in [64, 128, 256, 512])
                        DropdownMenuItem(value: size, child: Text('$size Mo'))
                    ],
                    onChanged: (value) => runFlowAction(context, () async {
                          if (value == null) return;
                          await settings.setAudioCacheLimitMb(value);
                          ref.invalidate(audioCacheControllerProvider);
                          await ref
                              .read(audioCacheControllerProvider)
                              .trim(value * 1024 * 1024);
                          ref
                              .read(_cacheSettingsRevisionProvider.notifier)
                              .state++;
                        })),
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Vider le cache temporaire'),
                        onPressed: () => runFlowAction(
                            context,
                            () => ref
                                .read(audioCacheControllerProvider)
                                .clear()))),
                const SizedBox(height: 24),
                for (final transfer in transfers.where((t) =>
                    t.status != TransferStatus.completed &&
                    t.status != TransferStatus.cancelled)) ...[
                  ListTile(
                      title: Text(transfer.track.title),
                      subtitle: Text(transfer.error ??
                          switch (transfer.status) {
                            TransferStatus.running => 'Téléchargement en cours',
                            TransferStatus.paused =>
                              'En pause · reprise depuis le début',
                            _ => 'Transfert interrompu'
                          }),
                      trailing: Wrap(children: [
                        FlowIconButton(
                            tooltip: transfer.status == TransferStatus.running
                                ? 'Pause'
                                : 'Réessayer',
                            icon: Icon(transfer.status == TransferStatus.running
                                ? Icons.pause
                                : Icons.refresh),
                            onPressed: () =>
                                transfer.status == TransferStatus.running
                                    ? ref
                                        .read(transfersProvider.notifier)
                                        .pause(transfer.track.id)
                                    : ref
                                        .read(playerProvider.notifier)
                                        .downloadTrack(transfer.track)),
                        FlowIconButton(
                            tooltip: 'Annuler',
                            icon: const Icon(Icons.close),
                            onPressed: () => ref
                                .read(transfersProvider.notifier)
                                .cancel(transfer.track.id)),
                      ])),
                  LinearProgressIndicator(
                      value: transfer.total > 0
                          ? transfer.received / transfer.total
                          : null),
                ],
                const SizedBox(height: 24),
                if (downloads.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                          'Télécharge un titre depuis son menu pour le garder disponible hors connexion.')),
                for (final file in downloads)
                  ListTile(
                      leading: const Icon(Icons.offline_pin_outlined),
                      title: Text(file.track.title),
                      subtitle: Text(file.track.artist),
                      onTap: () => runFlowAction(
                          context,
                          () => ref
                              .read(playerProvider.notifier)
                              .playTrack(file.track)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        FlowIconButton(
                            tooltip: 'Vérifier l’intégrité locale',
                            icon: const Icon(Icons.verified_outlined),
                            onPressed: () => runFlowAction(context, () async {
                                  final valid = await verifyDeviceFile(file);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(valid
                                            ? 'Fichier conforme à son empreinte locale.'
                                            : 'Fichier absent ou modifié. Supprime puis télécharge une nouvelle copie.')));
                                  }
                                })),
                        FlowIconButton(
                            tooltip: 'Supprimer le téléchargement',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => runFlowAction(context, () async {
                                  final library = await ref
                                      .read(deviceLibraryProvider.future);
                                  await removeDeviceFile(
                                      file.path, library.store.scope);
                                  await library.store
                                      .remove('files', file.track.id);
                                  ref.invalidate(deviceTracksProvider);
                                  ref
                                      .read(libraryRevisionProvider.notifier)
                                      .state++;
                                }))
                      ])),
              ]));
  }
}
