import 'package:flutter/material.dart';

import '../models/saved_recording.dart';
import '../theme/app_theme.dart';

class RecordingListCard extends StatelessWidget {
  const RecordingListCard({
    super.key,
    required this.recording,
    required this.playing,
    required this.onPlay,
    required this.onAdjust,
    required this.onShare,
    required this.onRename,
    required this.onDelete,
  });

  final SavedRecording recording;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onAdjust;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final d = recording.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final duration =
        recording.durationLabel.isNotEmpty ? recording.durationLabel : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: playing
            ? AppColors.accentGreen.withValues(alpha: 0.12)
            : AppColors.itemBg,
        borderRadius: BorderRadius.circular(10),
        border: playing
            ? Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.45),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              recording.beatName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (recording.displayName != recording.beatName) ...[
              const SizedBox(height: 4),
              Text(
                recording.displayName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '$date  ·  $duration',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (recording.canMix)
                  TextButton.icon(
                    onPressed: onAdjust,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Adjust'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.accentOrange),
                  tooltip: 'Share',
                  onPressed: onShare,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                  tooltip: 'Rename',
                  onPressed: onRename,
                ),
                IconButton(
                  icon: Icon(
                    playing ? Icons.stop_circle : Icons.play_circle_fill,
                    color: playing ? AppColors.danger : AppColors.accentGreen,
                    size: 32,
                  ),
                  tooltip: playing ? 'Stop' : 'Play',
                  onPressed: onPlay,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
