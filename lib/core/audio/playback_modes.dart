// playback_modes.dart
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:harmonix_apps/core/audio/audio_handler.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

/// Restores the last "Aléatoire" / "Boucle" choice at startup, then writes
/// every later change back to [settings] — wherever it comes from: the player
/// UI, the media notification or Android Auto.
///
/// The subscriptions live as long as the handler, which is created once per
/// process, so they are intentionally never cancelled.
Future<void> bindPlaybackModes(
  HarmonixAudioHandler handler,
  SettingsRepository settings,
) async {
  // Restore before listening: just_audio replays its default values to new
  // subscribers, which would otherwise overwrite the saved modes mid-restore.
  await _restore(handler, settings);

  handler.player.shuffleModeEnabledStream.listen((enabled) {
    unawaited(settings.setShuffleEnabled(enabled));
  });
  handler.player.loopModeStream.listen((mode) {
    unawaited(settings.setRepeatMode(repeatModeFromLoop(mode).name));
  });
}

Future<void> _restore(
  HarmonixAudioHandler handler,
  SettingsRepository settings,
) async {
  await handler.setShuffleMode(
    settings.shuffleEnabled
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none,
  );
  await handler.setRepeatMode(_repeatModeFromName(settings.repeatMode));
}

/// Mirrors the mapping used by `HarmonixAudioHandler.setRepeatMode`.
AudioServiceRepeatMode repeatModeFromLoop(LoopMode mode) => switch (mode) {
      LoopMode.off => AudioServiceRepeatMode.none,
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
    };

AudioServiceRepeatMode _repeatModeFromName(String name) =>
    AudioServiceRepeatMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AudioServiceRepeatMode.none,
    );

/// Icon for a repeat mode, shared by every player surface.
IconData repeatModeIcon(AudioServiceRepeatMode mode) => switch (mode) {
      AudioServiceRepeatMode.one => Icons.repeat_one,
      _ => Icons.repeat,
    };

/// Repeat cycle: none → all → one → none.
AudioServiceRepeatMode nextRepeatMode(AudioServiceRepeatMode current) =>
    switch (current) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
