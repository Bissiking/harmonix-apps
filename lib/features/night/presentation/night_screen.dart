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
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/shared/widgets/music_collection.dart';

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
  bool showOtherTracks = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(nightTracksProvider);
    final tracks = catalog.valueOrNull ?? [];
    final metadataState = ref.watch(nightMetadataProvider);
    final metadata = metadataState.valueOrNull ?? {};
    final session = ref.watch(nightSessionProvider);
    final habit = ref.watch(nightHabitProvider).valueOrNull;
    final settings = ref.watch(settingsRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final allowed = metadataState.isLoading || !metadataState.hasValue
        ? <Track>[]
        : tracks.where((track) {
            final data = metadata[track.id] ?? const NightMetadata();
            return classifyNight(data, catalogEligible: track.nightEligible)
                    .allowed &&
                (category == nightCategories.first ||
                    category == data.category);
          }).toList();
    final allowedIds = allowed.map((t) => t.id).toSet();
    final otherTracks =
        tracks.where((t) => !allowedIds.contains(t.id)).toList();
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Harmonix Night'), actions: [
          FlowIconButton(
              tooltip: 'Actualiser la bibliothèque Night',
              icon: const Icon(Icons.refresh),
              onPressed: catalog.isLoading
                  ? null
                  : () => ref.invalidate(nightTracksProvider)),
        ]),
        body: CollectionWidth(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                children: [
              LayoutBuilder(builder: (context, constraints) {
                final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Un peu de calme.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  fontSize:
                                      constraints.maxWidth > 900 ? 46 : 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1)),
                      const SizedBox(height: 12),
                      Text('Ta sélection Night. Un arrêt en douceur.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 28),
                      if (allowed.isNotEmpty && constraints.maxWidth >= 680)
                        MusicCoverShelf(
                            tracks: allowed.take(6).toList(),
                            size: constraints.maxWidth > 900 ? 160 : 132,
                            onPlay: (index) => runFlowAction(
                                context,
                                () => ref
                                    .read(playerProvider.notifier)
                                    .playFromQueue(allowed, index,
                                        allowNightOnly: true))),
                      if (allowed.isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                                catalog.isLoading || metadataState.isLoading
                                    ? 'Préparation de ta sélection…'
                                    : 'Choisis les titres qui accompagnent ta nuit.',
                                style:
                                    TextStyle(color: scheme.onSurfaceVariant))),
                    ]);
                final timer = _timer(allowed, session);
                if (constraints.maxWidth >= 680) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: intro),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: timer),
                      ]);
                }
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      intro,
                      const SizedBox(height: 24),
                      timer,
                      if (allowed.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        MusicCoverShelf(
                            tracks: allowed.take(6).toList(),
                            size: 132,
                            onPlay: (index) => runFlowAction(
                                context,
                                () => ref
                                    .read(playerProvider.notifier)
                                    .playFromQueue(allowed, index,
                                        allowNightOnly: true))),
                      ],
                    ]);
              }),
              const SizedBox(height: 36),
              CollectionHeading(
                  title: 'Ta sélection',
                  subtitle: '${allowed.length} titres pour cette ambiance'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final name in nightCategories)
                  ChoiceChip(
                      label: Text(name),
                      selected: category == name,
                      onSelected: (_) => setState(() => category = name)),
              ]),
              const SizedBox(height: 16),
              if (catalog.isLoading || metadataState.isLoading)
                const LinearProgressIndicator(),
              if (catalog.hasError || metadataState.hasError)
                FlowEmptyState(
                    icon: Icons.cloud_off,
                    title: 'La sélection est indisponible',
                    message: 'Réessaie de charger la bibliothèque Night.',
                    action: TextButton(
                        onPressed: () {
                          ref.invalidate(nightTracksProvider);
                          ref.invalidate(nightMetadataProvider);
                        },
                        child: const Text('Réessayer'))),
              if (!catalog.isLoading && allowed.isEmpty && !catalog.hasError)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                        'Aucun titre autorisé pour cette catégorie. Choisis une autre ambiance ou ajoute des titres ci-dessous.')),
              for (final track in allowed)
                nightTrackRow(context, ref, track, metadata),
              if (otherTracks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        onPressed: () =>
                            setState(() => showOtherTracks = !showOtherTracks),
                        icon: Icon(showOtherTracks
                            ? Icons.expand_less
                            : Icons.add_rounded),
                        label: Text(showOtherTracks
                            ? 'Masquer les autres titres'
                            : 'Choisir dans le catalogue · ${otherTracks.length}'))),
                if (showOtherTracks)
                  for (final track in otherTracks)
                    nightTrackRow(context, ref, track, metadata),
              ],
              const SizedBox(height: 32),
              const Divider(),
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Night Sense'),
                  subtitle: Text(settings.nightSenseEnabled
                      ? 'Activé sur cet appareil'
                      : 'Un horaire adapté à tes habitudes'),
                  children: [
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Apprendre mes horaires sur cet appareil'),
                        subtitle: const Text(
                            'Volontaire et local. Horaires de session uniquement, sans localisation ni analyse du sommeil.'),
                        value: settings.nightSenseEnabled,
                        onChanged: (value) async {
                          await settings.setNightSenseEnabled(value);
                          if (!mounted) return;
                          ref.invalidate(nightHabitProvider);
                          setState(() {});
                        }),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(habit == null
                            ? 'Au moins cinq sessions comparables sont nécessaires pour proposer un horaire.'
                            : 'Horaire habituel : ${habit.label} · ${habit.observations} sessions')),
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
                  ]),
            ])));
  }

  Widget _timer(List<Track> allowed, NightTimer? session) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(
                        session == null
                            ? Icons.bedtime_outlined
                            : Icons.graphic_eq,
                        color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            session == null
                                ? 'Ta session'
                                : 'La nuit est à toi',
                            style: Theme.of(context).textTheme.titleMedium))
                  ]),
                  const SizedBox(height: 20),
                  if (session == null) ...[
                    Text('$minutes min',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1)),
                    const SizedBox(height: 8),
                    Text(
                        endOfTrack
                            ? 'Le dernier morceau ira jusqu’au bout.'
                            : 'Le volume baisse pendant les 3 dernières minutes.',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    Wrap(spacing: 6, runSpacing: 8, children: [
                      for (final duration in [15, 30, 45, 60, 90])
                        ChoiceChip(
                            label: Text('$duration min'),
                            selected: minutes == duration,
                            onSelected: (_) =>
                                setState(() => minutes = duration)),
                    ]),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            onPressed: _chooseTime,
                            icon: const Icon(Icons.schedule, size: 18),
                            label: const Text('Arrêt à une heure précise'))),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Terminer le morceau'),
                        subtitle: const Text('À l’échéance, sans fondu'),
                        value: endOfTrack,
                        onChanged: (value) =>
                            setState(() => endOfTrack = value)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
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
                                          duration: Duration(minutes: minutes),
                                          endOfTrack: endOfTrack);
                                }),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('Démarrer · $minutes min')),
                  ] else ...[
                    _NightCountdown(session: session),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                        onPressed: () => runFlowAction(
                            context,
                            () => ref
                                .read(nightSessionProvider.notifier)
                                .finish(pause: true)),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Terminer la session')),
                  ],
                ])));
  }

  Future<void> _chooseTime() async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final now = DateTime.now();
    var end = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
    setState(() => minutes = end.difference(now).inMinutes.clamp(1, 1440));
  }
}

class _NightCountdown extends StatefulWidget {
  const _NightCountdown({required this.session});
  final NightTimer session;
  @override
  State<_NightCountdown> createState() => _NightCountdownState();
}

class _NightCountdownState extends State<_NightCountdown> {
  late final ticks = Stream.periodic(const Duration(seconds: 1), (i) => i);
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
      stream: ticks,
      builder: (context, _) {
        final remaining = widget.session.remaining(DateTime.now());
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${remaining.inMinutes}:$seconds',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('avant la fin de ta session'),
        ]);
      });
}

Widget nightTrackRow(BuildContext context, WidgetRef ref, Track track,
    Map<String, NightMetadata> metadata) {
  final data = metadata[track.id] ?? const NightMetadata();
  return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: TrackArtwork(
          trackId: track.id,
          coverFile: track.coverFile,
          coverUrl: track.coverUrl,
          size: 48,
          borderRadius: 10),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Tooltip(
          message:
              classifyNight(data, catalogEligible: track.nightEligible).reason,
          child:
              Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis)),
      trailing: FlowIconButton(
          tooltip: 'Configurer Night',
          icon: const Icon(Icons.tune),
          onPressed: () => configureNightTrack(context, ref, track, data)));
}

Future<void> configureNightTrack(BuildContext context, WidgetRef ref,
    Track track, NightMetadata current) async {
  var assignment = current.assignment;
  final tagged = track.nightEligible;
  var only = tagged || current.nightOnly;
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
                        title: const Text('Réserver à Night'),
                        subtitle: Text(tagged
                            ? 'Réservé à Night depuis SonoraStudio.'
                            : 'Masquer dans la bibliothèque principale'),
                        value: only,
                        onChanged:
                            tagged ? null : (v) => setState(() => only = v)),
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
                                nightOnly: tagged ? current.nightOnly : only,
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
