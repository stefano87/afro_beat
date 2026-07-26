import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_recording.dart';
import '../services/beat_audio_service.dart';
import '../services/mix_playback_service.dart';
import '../services/recording_session.dart';
import '../services/saved_recordings_service.dart';
import '../theme/app_theme.dart';

class MixControlsPanel extends StatelessWidget {
  const MixControlsPanel({
    super.key,
    required this.recordingId,
    this.compact = false,
    this.recording,
    this.onSaveMix,
  });

  final String recordingId;
  final bool compact;
  final SavedRecording? recording;
  final VoidCallback? onSaveMix;

  @override
  Widget build(BuildContext context) {
    return Consumer<MixPlaybackService>(
      builder: (context, mix, _) {
        return Container(
          margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 8 : 12),
          decoration: BoxDecoration(
            color: compact
                ? AppColors.surface
                : AppColors.purple.withValues(alpha: 0.12),
            borderRadius: compact ? null : BorderRadius.circular(12),
            border: compact
                ? Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  )
                : Border.all(
                    color: AppColors.purple.withValues(alpha: 0.4),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                const Text(
                  'Mix levels',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (!compact) const SizedBox(height: 8),
              if (!compact)
                Text(
                  'Preview plays your saved recording. Use Save mix to export '
                  'voice + beat with these levels.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              if (!compact) const SizedBox(height: 8),
              if (!compact)
                Consumer<MixPlaybackService>(
                  builder: (context, mixService, _) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text(
                        'Add extra beat layer on preview',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Off by default — beat is already in the recording',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      value: mixService.previewExtraBeat,
                      activeThumbColor: AppColors.accentOrange,
                      onChanged: mixService.setPreviewExtraBeat,
                    );
                  },
                ),
              if (!compact) const SizedBox(height: 4),
              _MixSlider(
                label: 'Voice',
                icon: Icons.mic,
                color: AppColors.accentGreen,
                value: mix.voiceVolume,
        onChanged: (v) async {
                  await mix.setVoiceVolume(v);
                  if (recordingId != RecordingSession.panelPreviewId) {
                    await context.read<SavedRecordingsService>().updateMixLevels(
                          id: recordingId,
                          mixBeatVolume: mix.beatVolume,
                          mixVoiceVolume: v,
                        );
                  }
                },
              ),
              const SizedBox(height: 4),
              _MixSlider(
                label: 'Beat',
                icon: Icons.music_note,
                color: AppColors.accentOrange,
                value: mix.beatVolume,
                onChanged: (v) async {
                  await mix.setBeatVolume(v);
                  if (recordingId != RecordingSession.panelPreviewId) {
                    await context.read<SavedRecordingsService>().updateMixLevels(
                          id: recordingId,
                          mixBeatVolume: v,
                          mixVoiceVolume: mix.voiceVolume,
                        );
                  }
                },
              ),
              if (onSaveMix != null && recording != null && recording!.canMix) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onSaveMix,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save mix'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class MonitorBeatSlider extends StatelessWidget {
  const MonitorBeatSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MixPlaybackService, RecordingSession>(
      builder: (context, mix, session, _) {
        final live = session.isAnyBeatRecording;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentOrange.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.accentOrange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      live ? 'Beat volume (live)' : 'Beat volume while recording',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  live
                      ? 'Adjust now — changes apply to the beat you hear.'
                      : 'Lower = cleaner voice. Use headphones for best results.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white54, size: 18),
                    Expanded(
                      child: Slider(
                        value: mix.monitorBeatVolume,
                        min: 0.15,
                        max: 0.85,
                        activeColor: AppColors.accentOrange,
                        onChanged: (v) async {
                          await mix.setMonitorBeatVolume(v);
                          if (session.isAnyBeatRecording) {
                            await context.read<BeatAudioService>().setVolume(v);
                          }
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white54, size: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MixSlider extends StatelessWidget {
  const _MixSlider({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
