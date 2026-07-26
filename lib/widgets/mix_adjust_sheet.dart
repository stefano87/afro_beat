import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_recording.dart';
import '../services/beat_audio_service.dart';
import '../services/mix_playback_service.dart';
import '../theme/app_theme.dart';
import 'mix_controls.dart';

/// Opens the mix adjust bottom sheet (voice / beat sliders + preview + save).
Future<void> showMixAdjustSheet(
  BuildContext context, {
  required SavedRecording recording,
  Future<void> Function()? onSaveMix,
}) async {
  if (!recording.canMix) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beat not found for this recording'),
        backgroundColor: AppColors.danger,
      ),
    );
    return;
  }

  final mix = context.read<MixPlaybackService>();
  final audio = context.read<BeatAudioService>();

  await audio.stop();
  await mix.stop(notifyEnded: false);
  mix.setPreviewExtraBeat(false);
  await mix.setBeatVolume(recording.mixBeatVolume);
  await mix.setVoiceVolume(recording.mixVoiceVolume);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MixAdjustSheetContent(
      recording: recording,
      onSaveMix: onSaveMix,
    ),
  );

  if (context.mounted) {
    await context.read<MixPlaybackService>().stop(notifyEnded: false);
  }
}

class _MixAdjustSheetContent extends StatelessWidget {
  const _MixAdjustSheetContent({
    required this.recording,
    this.onSaveMix,
  });

  final SavedRecording recording;
  final Future<void> Function()? onSaveMix;

  Future<void> _togglePreview(BuildContext context) async {
    final mix = context.read<MixPlaybackService>();
    final audio = context.read<BeatAudioService>();

    if (mix.isPlayingRecording(recording.id)) {
      await mix.stop(notifyEnded: false);
      return;
    }

    await audio.stop();
    final ok = await mix.play(
      recordingId: recording.id,
      voicePath: recording.filePath,
      beatUrl: recording.mixBeatUrl!,
      includeSeparateBeat: true,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not preview mix — check your connection'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Adjust Mix',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              recording.displayName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adjust levels, preview the mix, then save a new version.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            MixControlsPanel(
              recordingId: recording.id,
              compact: true,
              recording: recording,
              onSaveMix: onSaveMix == null
                  ? null
                  : () async {
                      await context.read<MixPlaybackService>().stop(
                            notifyEnded: false,
                          );
                      if (context.mounted) Navigator.pop(context);
                      await onSaveMix!();
                    },
            ),
            const SizedBox(height: 12),
            Consumer<MixPlaybackService>(
              builder: (context, mix, _) {
                final previewing = mix.isPlayingRecording(recording.id);
                return OutlinedButton.icon(
                  onPressed: () => _togglePreview(context),
                  icon: Icon(
                    previewing
                        ? Icons.stop_outlined
                        : Icons.play_arrow_outlined,
                  ),
                  label: Text(previewing ? 'Stop preview' : 'Preview mix'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        previewing ? AppColors.danger : AppColors.accentGreen,
                    side: BorderSide(
                      color: previewing ? AppColors.danger : AppColors.accentGreen,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
