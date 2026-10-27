import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';
import 'package:harmonix_apps/features/night/presentation/night_screen.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';

class _Catalog extends CatalogRepository {
  _Catalog(super.ref);
  bool tagged = true;
  int loads = 0;
  @override
  Future<List<Track>> getTracks() async {
    loads++;
    return [
      Track(
          id: 'night-tagged',
          title: 'Ambient',
          artist: 'Test',
          nightEligible: tagged)
    ];
  }
}

void main() {
  testWidgets('Night loads Studio tags directly and keeps manual exclusions',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsRepository(await SharedPreferences.getInstance());
    var metadata = <String, NightMetadata>{};
    Completer<Map<String, NightMetadata>>? pending;
    late _Catalog catalog;
    final container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      catalogRepositoryProvider.overrideWith((ref) => catalog = _Catalog(ref)),
      nightMetadataProvider.overrideWith(
          (ref) async => pending == null ? metadata : await pending.future),
      nightHabitProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const MaterialApp(home: NightScreen())));
    await tester.pumpAndSettle();
    FilledButton start() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Démarrer · 45 min'));
    expect(catalog.loads, 1);
    expect(start().onPressed, isNotNull);
    expect(find.byTooltip('Autorisé depuis SonoraStudio'), findsOneWidget);

    pending = Completer<Map<String, NightMetadata>>();
    container.invalidate(nightMetadataProvider);
    expect(container.read(nightMetadataProvider).isLoading, isTrue);
    await tester.pump();
    await tester.pump();
    expect(start().onPressed, isNull,
        reason: 'Local exclusions must load before server tags allow playback');
    metadata = {
      'night-tagged': const NightMetadata(assignment: NightAssignment.excluded)
    };
    pending.complete(metadata);
    pending = null;
    await tester.pumpAndSettle();
    expect(start().onPressed, isNull);

    metadata = {};
    catalog.tagged = false;
    container.invalidate(nightMetadataProvider);
    await tester.tap(find.byTooltip('Actualiser la bibliothèque Night'));
    await tester.pumpAndSettle();
    expect(catalog.loads, 2);
    expect(start().onPressed, isNull);

    metadata = {
      'night-tagged': const NightMetadata(assignment: NightAssignment.allowed)
    };
    container.invalidate(nightMetadataProvider);
    await tester.pumpAndSettle();
    expect(start().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
