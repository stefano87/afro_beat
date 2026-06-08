import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_recording.dart';
import '../services/analytics_service.dart';
import 'package:just_audio/just_audio.dart';

import '../services/beat_audio_service.dart';
import '../services/saved_recordings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/info_modal.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logPageView('recordings');
      context.read<SavedRecordingsService>().load();
    });
  }

  Future<void> _play(SavedRecording recording) async {
    final library = context.read<SavedRecordingsService>();
    final audio = context.read<BeatAudioService>();

    if (library.isPlaying(recording.id)) {
      await audio.stop();
      library.setPlayingId(null);
      return;
    }

    final ok = await audio.playLocalFile(recording.filePath);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not play recording'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    library.setPlayingId(recording.id);
    audio.playerStateStream.firstWhere(
      (s) => s.processingState == ProcessingState.completed,
    ).then((_) {
      if (mounted) library.setPlayingId(null);
    });
  }

  Future<void> _confirmDelete(SavedRecording recording) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Delete recording', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${recording.displayName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final library = context.read<SavedRecordingsService>();
    final audio = context.read<BeatAudioService>();
    if (library.isPlaying(recording.id)) await audio.stop();
    await library.delete(recording.id);
  }

  Future<void> _rename(SavedRecording recording) async {
    final controller = TextEditingController(text: recording.displayName);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Rename recording',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.accentGreen),
              ),
            ),
          ],
        ),
      );

      if (ok != true || !mounted) return;

      final library = context.read<SavedRecordingsService>();
      final saved = await library.rename(recording.id, controller.text);

      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not rename recording'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'My Recordings',
        subtitle: 'Saved on your phone',
        onInfoTap: () => InfoModal.show(context),
      ),
      body: Consumer<SavedRecordingsService>(
        builder: (context, library, _) {
          if (library.recordings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_none, size: 64, color: Colors.white38),
                    SizedBox(height: 16),
                    Text(
                      'No saved recordings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use Sing & Record on a beat.\n'
                      'When you finish, your recording is saved here.',
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            itemCount: library.recordings.length,
            itemBuilder: (context, index) {
              final r = library.recordings[index];
              final playing = library.isPlaying(r.id);
              final d = r.createdAt;
              final date =
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
                  '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.itemBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  title: Text(
                    r.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    r.displayName != r.beatName
                        ? '${r.beatName}  ·  $date  ·  ${r.durationLabel.isNotEmpty ? r.durationLabel : '—'}'
                        : '$date  ·  ${r.durationLabel.isNotEmpty ? r.durationLabel : '—'}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white70),
                        onPressed: () => _rename(r),
                      ),
                      IconButton(
                        icon: Icon(
                          playing ? Icons.stop_circle : Icons.play_circle_fill,
                          color: AppColors.accentGreen,
                          size: 32,
                        ),
                        onPressed: () => _play(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: () => _confirmDelete(r),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
