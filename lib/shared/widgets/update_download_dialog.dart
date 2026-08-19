import 'dart:io';

import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/update/update_checker.dart';

/// Télécharge l'artefact de mise à jour, vérifie son empreinte SHA-256 et
/// renvoie le fichier local vérifié, ou `null` si l'utilisateur ferme.
Future<File?> showUpdateDownloadDialog(
  BuildContext context,
  UpdateInfo info,
) {
  return showDialog<File>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpdateDownloadDialog(info: info),
  );
}

class UpdateDownloadDialog extends StatefulWidget {
  const UpdateDownloadDialog({super.key, required this.info});

  final UpdateInfo info;

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  int _received = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final file = await downloadArtifactAndVerify(
        update: widget.info,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final progress = _total > 0 ? _received / _total : null;
    return AlertDialog(
      title: Text(error == null ? 'Téléchargement…' : 'Vérification échouée'),
      content: SizedBox(
        width: 320,
        child: error != null
            ? Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    progress == null
                        ? 'Téléchargement et vérification SHA-256…'
                        : 'Vérification SHA-256 : '
                            '${(_received / 1048576).toStringAsFixed(1)} Mo'
                            ' / ${(_total / 1048576).toStringAsFixed(1)} Mo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
      actions: [
        if (error != null)
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Fermer'),
          ),
      ],
    );
  }
}