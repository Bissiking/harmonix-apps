import 'package:dart_cast/dart_cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

Future<void> showCastSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HarmonixColors.darkSurface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const CastSheet(),
  );
}

class CastSheet extends ConsumerWidget {
  const CastSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(googleCastProvider);
    final controller = ref.read(googleCastProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.connected
                      ? Icons.cast_connected
                      : Icons.cast,
                  color: state.connected
                      ? HarmonixColors.accent
                      : Colors.white70,
                ),
                const SizedBox(width: 10),
                Text(
                  'Cast',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (state.discovering)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.connected) ...[
              _DeviceHeader(
                name: state.deviceName ?? '',
                casting: state.casting,
                isPlaying: state.isPlaying,
              ),
              if (state.casting) ...[
                const SizedBox(height: 12),
                _CastControls(
                  isPlaying: state.isPlaying,
                  onPlayPause: () {
                    final notifier = ref.read(googleCastProvider.notifier);
                    state.isPlaying ? notifier.pause() : notifier.play();
                  },
                  onNext: controller.skipToNext,
                  onPrevious: controller.skipToPrevious,
                  onSeek: controller.seek,
                  position: state.position,
                  duration: state.duration ?? Duration.zero,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.casting
                          ? controller.stopCasting
                          : controller.castCurrent,
                      icon: Icon(
                        state.casting
                            ? Icons.smartphone
                            : Icons.cast,
                      ),
                      label: Text(
                        state.casting
                            ? 'Revenir sur cet appareil'
                            : 'Lancer sur ${state.deviceName}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: controller.disconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Déconnecter'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (state.lastDeviceName != null) ...[
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(state.lastDeviceName!),
                  subtitle: const Text('Dernier appareil'),
                  trailing: state.connecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: state.connecting
                      ? null
                      : () => controller.reconnectLastDevice(),
                ),
                const SizedBox(height: 4),
              ],
              FilledButton.tonalIcon(
                onPressed: state.connecting
                    ? null
                    : () {
                        if (state.devices.isEmpty) {
                          controller.startDiscovery();
                        } else {
                          controller.stopDiscovery();
                        }
                      },
                icon: Icon(
                  state.discovering
                      ? Icons.stop_circle_outlined
                      : Icons.search,
                ),
                label: Text(
                  state.devices.isEmpty
                      ? (state.discovering
                          ? 'Recherche en cours...'
                          : 'Rechercher des appareils')
                      : 'Arrêter la recherche',
                ),
              ),
              if (state.devices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = state.devices[index];
                      return _DeviceTile(
                        device: device,
                        connecting: state.connecting,
                        onTap: () => controller.connect(device),
                      );
                    },
                  ),
                ),
              ],
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.connecting,
    required this.onTap,
  });

  final CastDevice device;
  final bool connecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isChromecast = device.protocol == CastProtocol.chromecast;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isChromecast ? Icons.cast : Icons.devices_other,
        color: HarmonixColors.accent,
      ),
      title: Text(device.name),
      subtitle: Text(isChromecast ? 'Chromecast / Home' : device.protocol.name),
      trailing: connecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: connecting ? null : onTap,
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({
    required this.name,
    required this.casting,
    required this.isPlaying,
  });

  final String name;
  final bool casting;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.wifi_tethering, color: HarmonixColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                casting
                    ? (isPlaying ? 'En cours de lecture' : 'En pause')
                    : 'Connecté',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CastControls extends StatelessWidget {
  const _CastControls({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.position,
    required this.duration,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<Duration> onSeek;
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: (position.inMilliseconds.toDouble())
              .clamp(0.0, duration.inMilliseconds.toDouble().clamp(0.0, 1.0)),
          max: duration.inMilliseconds > 0
              ? duration.inMilliseconds.toDouble()
              : 1.0,
          activeColor: HarmonixColors.accent,
          inactiveColor: Colors.white24,
          onChanged: (value) => onSeek(Duration(milliseconds: value.round())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_previous),
              onPressed: onPrevious,
            ),
            IconButton(
              iconSize: 40,
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              color: HarmonixColors.accent,
              onPressed: onPlayPause,
            ),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_next),
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}
