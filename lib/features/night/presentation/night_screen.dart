// night_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/harmonix_mark.dart';

const nightCategories = [
  'Mélange relaxant',
  'Lo-Fi',
  'Ambient',
  'Chill',
  'Piano',
  'Nature',
  'Instrumental'
];
final nightTracksProvider = FutureProvider<List<Track>>((ref) async {
  ref.watch(libraryRevisionProvider);
  ref.watch(offlineModeProvider);
  return ref.watch(catalogRepositoryProvider).getTracks();
});

class NightScreen extends ConsumerStatefulWidget {
  const NightScreen({super.key});
  @override
  ConsumerState<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends ConsumerState<NightScreen> {
  int minutes = 45;
  String category = nightCategories.first;
  bool endOfTrack = false;
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(nightTracksProvider);
    final tracks = catalog.valueOrNull ?? [];
    final metadataState = ref.watch(nightMetadataProvider);
    final metadata = metadataState.valueOrNull ?? {};
    final session = ref.watch(nightSessionProvider);
    final habit = ref.watch(nightHabitProvider).valueOrNull;
    final settings = ref.watch(settingsRepositoryProvider);
    // Wait for local choices before honouring the editorial opt-in.
    final allowed = metadataState.isLoading || !metadataState.hasValue
        ? <Track>[]
        : tracks.where((track) {
            final data = metadata[track.id] ?? const NightMetadata();
            return classifyNight(data, catalogEligible: track.nightEligible)
                    .allowed &&
                (category == nightCategories.first ||
                    category == data.category);
          }).toList();
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Harmonix Night'), actions: [
          Semantics(
            container: true,
            child: FlowIconButton(
              tooltip: 'Actualiser la bibliothèque Night',
              icon: const Icon(Icons.refresh),
              onPressed: catalog.isLoading
                  ? null
                  : () => ref.invalidate(nightTracksProvider),
            ),
          ),
        ]),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: HarmonixMark(size: 80, night: true)),
                  const SizedBox(height: 16),
                  Text('Laisse la nuit s’installer.',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Une sélection choisie par toi. Un arrêt progressif. Tout reste sur cet appareil.'),
                  const SizedBox(height: 24),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final name in nightCategories)
                      ChoiceChip(
                          label: Text(name),
                          selected: category == name,
                          onSelected: (_) => setState(() => category = name))
                  ]),
                  const SizedBox(height: 24),
                  if (session == null) ...[
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final duration in [15, 30, 45, 60, 90])
                        ChoiceChip(
                            label: Text('$duration min'),
                            selected: minutes == duration,
                            onSelected: (_) =>
                                setState(() => minutes = duration)),
                      OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                                context: context, initialTime: TimeOfDay.now());
                            if (time == null || !mounted) return;
                            final now = DateTime.now();
                            var end = DateTime(now.year, now.month, now.day,
                                time.hour, time.minute);
                            if (!end.isAfter(now)) {
                              end = end.add(const Duration(days: 1));
                            }
                            setState(() => minutes =
                                end.difference(now).inMinutes.clamp(1, 1440));
                          },
                          child: const Text('Arrêt à une heure précise'))
                    ]),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Terminer le morceau à l’échéance'),
                        subtitle:
                            const Text('Le fondu est désactivé pour ce mode.'),
                        value: endOfTrack,
                        onChanged: (value) =>
                            setState(() => endOfTrack = value)),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                            onPressed: allowed.isEmpty
                                ? null
                                : () => runFlowAction(context, () async {
                                      await ref
                                          .read(playerProvider.notifier)
                                          .playFromQueue(allowed, 0,
                                              allowNightOnly: true);
                                      await ref
                                          .read(nightSessionProvider.notifier)
                                          .start(
                                              duration:
                                                  Duration(minutes: minutes),
                                              endOfTrack: endOfTrack);
                                    }),
                            icon: const Icon(Icons.nightlight_round),
                            label: Text('Démarrer · $minutes min'))),
                    if (allowed.isEmpty)
                      const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                              'Autorise des titres ci-dessous pour préparer ta session.')),
                  ] else ...[
                    StreamBuilder<int>(
                        stream: Stream.periodic(
                            const Duration(seconds: 1), (i) => i),
                        builder: (context, snapshot) => Text(
                            '${session.remaining(DateTime.now()).inMinutes} min restantes',
                            style: Theme.of(context).textTheme.headlineSmall)),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(nightSessionProvider.notifier)
                                .finish(pause: true),
                            icon: const Icon(Icons.stop),
                            label: const Text('Terminer la session'))),
                  ],
                  const SizedBox(height: 32),
                  Text('Night Sense',
                      style: Theme.of(context).textTheme.titleLarge),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title:
                          const Text('Apprendre mes horaires sur cet appareil'),
                      subtitle: const Text(
                          'Volontaire et local. Horaires de session uniquement, sans localisation ni analyse du sommeil.'),
                      value: settings.nightSenseEnabled,
                      onChanged: (value) async {
                        await settings.setNightSenseEnabled(value);
                        ref.invalidate(nightHabitProvider);
                        if (mounted) setState(() {});
                      }),
                  Text(habit == null
                      ? 'Au moins cinq sessions comparables sont nécessaires pour proposer un horaire.'
                      : 'Horaire habituel : ${habit.label} · ${habit.observations} sessions'),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                          onPressed: () => runFlowAction(context, () async {
                                await (await ref
                                        .read(localStoreProvider.future))
                                    .replace('night_observations', {});
                                ref.invalidate(nightHabitProvider);
                              }),
                          child: const Text('Effacer l’apprentissage'))),
                  const SizedBox(height: 24),
                  Text('Ta bibliothèque Night',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Les métadonnées donnent une indication de calme. Tes choix manuels restent prioritaires.'),
                  if (catalog.isLoading || metadataState.isLoading)
                    const LinearProgressIndicator(),
                  if (catalog.hasError || metadataState.hasError)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                          'Impossible de charger la bibliothèque. Réessaie avec le bouton Actualiser.'),
                    ),
                  if (tracks.isEmpty &&
                      !catalog.isLoading &&
                      !catalog.hasError &&
                      !metadataState.isLoading &&
                      !metadataState.hasError)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                            'Charge Sonora ou importe de la musique depuis la bibliothèque.')),
                  for (final track in tracks)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(track.title),
                        subtitle: Text(
                            '${track.artist} · ${classifyNight(metadata[track.id] ?? const NightMetadata(), catalogEligible: track.nightEligible).reason}'),
                        trailing: FlowIconButton(
                            tooltip: 'Configurer Night',
                            icon: const Icon(Icons.tune),
                            onPressed: () => configureNightTrack(
                                context,
                                ref,
                                track,
                                metadata[track.id] ?? const NightMetadata()))),
                ]))));
  }
}

Future<void> configureNightTrack(BuildContext context, WidgetRef ref,
    Track track, NightMetadata current) async {
  var assignment = current.assignment;
  var only = current.nightOnly;
  var category = current.category;
  final result = await showDialog<NightMetadata>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: Text(track.title),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<NightAssignment>(
                        initialValue: assignment,
                        decoration: const InputDecoration(
                            labelText: 'Utilisation Night'),
                        items: const [
                          DropdownMenuItem(
                              value: NightAssignment.automatic,
                              child: Text('Automatique')),
                          DropdownMenuItem(
                              value: NightAssignment.allowed,
                              child: Text('Toujours autorisé')),
                          DropdownMenuItem(
                              value: NightAssignment.excluded,
                              child: Text('Toujours exclu'))
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => assignment = v);
                        }),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration:
                            const InputDecoration(labelText: 'Catégorie'),
                        items: [
                          for (final name in nightCategories)
                            DropdownMenuItem(value: name, child: Text(name))
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => category = v);
                        }),
                    SwitchListTile(
                        title: const Text('Night Only'),
                        subtitle: const Text(
                            'Masquer dans la bibliothèque principale'),
                        value: only,
                        onChanged: (v) => setState(() => only = v)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(
                            context,
                            NightMetadata(
                                assignment: assignment,
                                nightOnly: only,
                                category: category,
                                bpm: current.bpm)),
                        child: const Text('Enregistrer'))
                  ])));
  if (result != null && context.mounted) {
    await runFlowAction(context, () async {
      await (await ref.read(localStoreProvider.future)).put(
          'night_metadata', track.id, {'id': track.id, ...result.toJson()});
      ref.read(libraryRevisionProvider.notifier).state++;
    });
  }
}
