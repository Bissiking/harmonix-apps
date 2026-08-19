import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/features/cast/providers/cast_provider.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(castProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Séances')),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Écoute ensemble, où que vous soyez.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (state.isActive)
                  _ActiveSessionCard(
                    state: state,
                    onSync: () =>
                        ref.read(castProvider.notifier).syncPlaybackState(),
                    onLeave: () => ref.read(castProvider.notifier).leave(),
                    onEnd: () => ref.read(castProvider.notifier).end(),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final create = _CreateSessionCard(
                        loading: state.connecting,
                        onCreate: () =>
                            ref.read(castProvider.notifier).start(role: 'host'),
                      );
                      final join = _JoinSessionCard(
                        controller: _codeController,
                        loading: state.connecting,
                        onJoin: () => ref
                            .read(castProvider.notifier)
                            .joinByCode(code: _codeController.text),
                      );
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: create),
                                const SizedBox(width: 16),
                                Expanded(child: join),
                              ],
                            )
                          : Column(
                              children: [
                                create,
                                const SizedBox(height: 16),
                                join,
                              ],
                            );
                    },
                  ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  _SessionError(message: state.error!),
                ],
                const SizedBox(height: 32),
                Text(
                  'Comment ça marche',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const _HowItWorks(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateSessionCard extends StatelessWidget {
  const _CreateSessionCard({required this.loading, required this.onCreate});

  final bool loading;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SessionPanel(
      icon: Icons.waves_rounded,
      title: 'Créer une séance',
      description:
          'Tu pilotes la musique. Les personnes invitées suivent la même écoute en temps réel.',
      child: FilledButton.icon(
        onPressed: loading ? null : onCreate,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: Text(loading ? 'Création…' : 'Nouvelle séance'),
      ),
    );
  }
}

class _JoinSessionCard extends StatelessWidget {
  const _JoinSessionCard({
    required this.controller,
    required this.loading,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return _SessionPanel(
      icon: Icons.groups_2_outlined,
      title: 'Rejoindre',
      description:
          'Entre le code partagé par l’hôte pour retrouver la séance et sa file de lecture.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: 'CODE',
                counterText: '',
              ),
              maxLength: 6,
              onSubmitted: (_) => loading ? null : onJoin(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 56,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 56),
              ),
              onPressed: loading ? null : onJoin,
              child: const Tooltip(
                message: 'Rejoindre la séance',
                child: Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.state,
    required this.onSync,
    required this.onLeave,
    required this.onEnd,
  });

  final CastState state;
  final VoidCallback onSync;
  final VoidCallback onLeave;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final participants = state.lastSession?['participants'];
    final count = participants is List ? participants.length : 1;
    final isHost = state.role == 'host';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 14),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Séance active',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('$count participant${count > 1 ? 's' : ''}'),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  state.sessionCode ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Synchroniser'),
              ),
              OutlinedButton.icon(
                onPressed: isHost ? onEnd : onLeave,
                icon: Icon(isHost ? Icons.stop_circle_outlined : Icons.logout),
                label: Text(isHost ? 'Terminer' : 'Quitter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.share_outlined, 'Partage le code'),
      (Icons.headphones_rounded, 'Chacun rejoint'),
      (Icons.sync_rounded, 'La lecture reste synchronisée'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 20),
                const SizedBox(width: 8),
                Text(item.$2),
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
