import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/beat.dart';
import '../services/analytics_service.dart';
import '../services/beat_audio_service.dart';
import '../services/favorites_service.dart';
import '../services/recording_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/info_modal.dart';
import '../widgets/playing_beat_card.dart';
import '../widgets/recording_panel.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logPageView('favorites');
    });
  }

  Future<void> _stopRecording(Beat beat) async {
    final session = context.read<RecordingSession>();
    await session.stopRecording(beat);
    if (!mounted) return;
    final message = session.hasRecording
        ? 'Recording completed'
        : 'Recording failed — try again';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            session.hasRecording ? AppColors.success : AppColors.danger,
      ),
    );
    setState(() {});
  }

  Future<void> _playBeat(Beat beat) async {
    try {
      await context.read<BeatAudioService>().playBeat(beat);
      setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nella riproduzione del beat'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FavoritesService, RecordingSession, BeatAudioService>(
      builder: (context, favorites, session, audio, _) {
        final list = favorites.favorites;
        final recordingMode = session.isAnyBeatRecording;
        final selected = session.selectedBeat;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppHeader(
            title: 'Favorites',
            subtitle: 'Your Favorites Instrumentals',
            onInfoTap: () => InfoModal.show(context),
          ),
          body: Stack(
            children: [
              Container(
                color: Colors.black,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    selected != null ? 320 : 100,
                  ),
                  itemCount: list.isEmpty ? 1 : list.length,
                  itemBuilder: (context, index) {
                    if (list.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.itemBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No favorites selected, add one by clicking on the heart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    final beat = list[index];
                    final isRecording = session.selectedBeat?.id == beat.id &&
                        session.isAnyBeatRecording;
                    if (recordingMode && !isRecording) {
                      return const SizedBox.shrink();
                    }

                    final isPlaying = audio.isBeatPlaying(beat);

                    return PlayingBeatCard(
                      isPlaying: isPlaying && !isRecording,
                      child: Row(
                        children: [
                          if (isPlaying && !isRecording) ...[
                            const PlayingBeatIndicator(),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  beat.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isPlaying && !isRecording
                                        ? AppColors.accentGreen
                                        : Colors.white,
                                    shadows: isPlaying && !isRecording
                                        ? [
                                            Shadow(
                                              color: AppColors.accentGreen
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const Text(
                                  AppConfig.favoritesSubtitle,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _IconBtn(
                            icon: isPlaying ? Icons.pause : Icons.play_arrow,
                            onTap: () => _playBeat(beat),
                            highlight: isPlaying && !isRecording,
                          ),
                          if (!isRecording)
                            _LabelBtn(
                              label: 'Record',
                              icon: Icons.radio,
                              color: AppColors.success,
                              onTap: () => session.startRecording(beat),
                            )
                          else
                            _LabelBtn(
                              label: 'Stop',
                              icon: Icons.stop,
                              color: AppColors.danger,
                              onTap: () => session.stopRecording(beat),
                            ),
                          _IconBtn(
                            icon: Icons.heart_broken,
                            color: AppColors.danger,
                            onTap: () => favorites.toggleFavorite(beat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (selected != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RecordingPanel(
                    beat: selected,
                    onStopRecording: () => _stopRecording(selected),
                  ),
                ),
              if (session.showCountdown || session.isPreparing)
                Positioned.fill(
                  child: CountdownOverlay(
                    countdownNumber: session.countdownNumber,
                    isPreparing: session.isPreparing,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool highlight;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: highlight
            ? AppColors.accentGreen.withValues(alpha: 0.2)
            : AppColors.buttonBg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color ?? (highlight ? AppColors.accentGreen : Colors.white),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LabelBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
