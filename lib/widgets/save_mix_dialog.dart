import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_recording.dart';
import '../services/mix_playback_service.dart';
import '../services/saved_recordings_service.dart';
import '../services/wav_mix_export_service.dart';
import '../theme/app_theme.dart';

enum SaveMixMode { overwrite, saveAsNew }

class _SaveMixChoice {
  const _SaveMixChoice({required this.mode, required this.title});

  final SaveMixMode mode;
  final String title;
}

Future<bool> showSaveMixDialog(
  BuildContext context, {
  required SavedRecording recording,
}) async {
  if (!recording.canMix) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beat not found for this recording'),
        backgroundColor: AppColors.danger,
      ),
    );
    return false;
  }

  final mix = context.read<MixPlaybackService>();
  final defaultName = _defaultMixName(recording);

  final choice = await showDialog<_SaveMixChoice>(
    context: context,
    builder: (ctx) => _SaveMixDialog(
      recording: recording,
      voicePercent: (mix.voiceVolume * 100).round(),
      beatPercent: (mix.beatVolume * 100).round(),
      initialName: defaultName,
    ),
  );

  if (choice == null || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Creating mixed version...'),
      duration: Duration(seconds: 30),
    ),
  );

  final exportedPath = await WavMixExportService.exportMix(
    voicePath: recording.filePath,
    beatUrl: recording.mixBeatUrl!,
    voiceVolume: mix.voiceVolume,
    beatVolume: mix.beatVolume,
  );

  if (!context.mounted) return false;
  messenger.hideCurrentSnackBar();

  if (exportedPath == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not create mix — check connection'),
        backgroundColor: AppColors.danger,
      ),
    );
    return false;
  }

  final library = context.read<SavedRecordingsService>();
  final ok = choice.mode == SaveMixMode.overwrite
      ? await library.overwriteWithMix(
          id: recording.id,
          mixedFilePath: exportedPath,
          mixBeatVolume: mix.beatVolume,
          mixVoiceVolume: mix.voiceVolume,
          title: choice.title,
        )
      : await library.addMixedCopy(
          source: recording,
          mixedFilePath: exportedPath,
          mixBeatVolume: mix.beatVolume,
          mixVoiceVolume: mix.voiceVolume,
          title: choice.title,
        ) !=
          null;

  if (!context.mounted) return false;

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? choice.mode == SaveMixMode.overwrite
                ? 'Recording updated with new mix'
                : 'New mixed recording saved'
            : 'Could not save to library',
      ),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ),
  );
  return ok;
}

String _defaultMixName(SavedRecording recording) {
  final name = recording.displayName;
  if (name.endsWith(' (mix)')) return name;
  return '$name (mix)';
}

class _SaveMixDialog extends StatefulWidget {
  const _SaveMixDialog({
    required this.recording,
    required this.voicePercent,
    required this.beatPercent,
    required this.initialName,
  });

  final SavedRecording recording;
  final int voicePercent;
  final int beatPercent;
  final String initialName;

  @override
  State<_SaveMixDialog> createState() => _SaveMixDialogState();
}

class _SaveMixDialogState extends State<_SaveMixDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _resolvedName {
    final trimmed = _nameController.text.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return widget.recording.displayName;
  }

  void _submit(SaveMixMode mode) {
    Navigator.pop(
      context,
      _SaveMixChoice(mode: mode, title: _resolvedName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text(
        'Save mixed recording',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Voice ${widget.voicePercent}%  ·  Beat ${widget.beatPercent}%',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Name',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 48,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Recording name',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
            onSubmitted: (_) => _submit(SaveMixMode.saveAsNew),
          ),
          const SizedBox(height: 4),
          const Text(
            'Export a new audio file with these levels.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(SaveMixMode.overwrite),
          child: const Text(
            'Overwrite',
            style: TextStyle(color: AppColors.accentOrange),
          ),
        ),
        TextButton(
          onPressed: () => _submit(SaveMixMode.saveAsNew),
          child: const Text(
            'Save as new',
            style: TextStyle(color: AppColors.accentGreen),
          ),
        ),
      ],
    );
  }
}
