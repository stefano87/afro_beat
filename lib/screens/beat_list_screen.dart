import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/feature_flags.dart';
import '../data/beats_data.dart';
import '../models/beat.dart';
import '../services/analytics_service.dart';
import '../services/beat_audio_service.dart';
import '../services/favorites_service.dart';
import '../data/premium_beats_data.dart';
import '../services/purchase_service.dart';
import '../services/recording_session.dart';
import '../services/tab_navigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/info_modal.dart';
import '../widgets/playing_beat_card.dart';
import '../widgets/recording_panel.dart';

class BeatListScreen extends StatefulWidget {
  const BeatListScreen({super.key});

  @override
  State<BeatListScreen> createState() => _BeatListScreenState();
}

class _BeatListScreenState extends State<BeatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logPageView('home');
    });
  }

  List<Beat> _allBeats(PurchaseService? purchases) {
    if (!kEnablePremiumStore) return generateBeats();
    final premium = getUnlockedPremiumBeats(purchases!.ownedProductIds);
    return [...premium, ...generateBeats()];
  }

  double _listBottomPadding(RecordingSession session, Beat? selected) {
    if (selected == null) return 100;
    if (session.hasRecording && session.isRecordingDownloaded) return 380;
    if (session.isAnyBeatRecording) return 260;
    return 300;
  }

  void _syncBeatStates(List<Beat> beats) {
    final audio = context.read<BeatAudioService>();
    final session = context.read<RecordingSession>();
    for (var i = 0; i < beats.length; i++) {
      beats[i] = beats[i].copyWith(
        isPlaying: audio.isBeatPlaying(beats[i]),
        isRecording: session.selectedBeat?.id == beats[i].id &&
            session.isAnyBeatRecording,
      );
    }
  }

  Future<void> _playBeat(List<Beat> beats, Beat beat) async {
    final audio = context.read<BeatAudioService>();
    try {
      await audio.playBeat(beat);
      setState(() => _syncBeatStates(beats));
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

  Future<void> _startRecording(List<Beat> beats, Beat beat) async {
    final session = context.read<RecordingSession>();
    try {
      await session.startRecording(beat);
      setState(() => _syncBeatStates(beats));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error starting the recording'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording(List<Beat> beats, Beat beat) async {
    final session = context.read<RecordingSession>();
    await session.stopRecording(beat);
    setState(() => _syncBeatStates(beats));
    if (mounted) {
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
    }
  }

  Widget _buildBody(
    List<Beat> beats,
    RecordingSession session,
    FavoritesService favorites,
    PurchaseService? purchases,
  ) {
    _syncBeatStates(beats);
    final recordingMode = session.isAnyBeatRecording;
    final selected = session.selectedBeat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppConfig.beatTabTitle,
        subtitle: AppConfig.beatTabSubtitle,
        onInfoTap: () => InfoModal.show(context),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConfig.listBackgroundAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                5,
                16,
                5,
                _listBottomPadding(session, selected),
              ),
              children: [
                if (kEnablePremiumStore && purchases != null) ...[
                  if (!purchases.hasRemovedInterstitials ||
                      (kEnableBeatPacksInStore &&
                          !purchases.hasAnyPremiumBeats))
                    _StorePromoBanner(
                      showRemoveAds: !purchases.hasRemovedInterstitials,
                      showBeatPacks: kEnableBeatPacksInStore &&
                          !purchases.hasAnyPremiumBeats,
                    )
                  else if (kEnableBeatPacksInStore &&
                      purchases.hasAnyPremiumBeats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.accentOrange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${getUnlockedPremiumBeats(purchases.ownedProductIds).length} Premium Beats',
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                ...beats.map((beat) {
                  if (recordingMode && !beat.isRecording) {
                    return const SizedBox.shrink();
                  }
                  final isPremium =
                      kEnablePremiumStore && beat.id >= 10001;
                  return _BeatListItem(
                    beat: beat,
                    isPremium: isPremium,
                    isFavorite: favorites.isFavorite(beat),
                    isPlaying: beat.isPlaying,
                    isRecording: session.selectedBeat?.id == beat.id &&
                        session.isAnyBeatRecording,
                    onPlay: () => _playBeat(beats, beat),
                    onFavorite: () => favorites.toggleFavorite(beat),
                    onRecord: () => _startRecording(beats, beat),
                    onStop: () => _stopRecording(beats, beat),
                  );
                }),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RecordingPanel(
                beat: selected,
                onStopRecording: () => _stopRecording(beats, selected),
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
  }

  @override
  Widget build(BuildContext context) {
    if (kEnablePremiumStore) {
      return Consumer4<BeatAudioService, RecordingSession, FavoritesService,
          PurchaseService>(
        builder: (context, audio, session, favorites, purchases, _) {
          return _buildBody(
            _allBeats(purchases),
            session,
            favorites,
            purchases,
          );
        },
      );
    }
    return Consumer3<BeatAudioService, RecordingSession, FavoritesService>(
      builder: (context, audio, session, favorites, _) {
        return _buildBody(_allBeats(null), session, favorites, null);
      },
    );
  }
}

class _StorePromoBanner extends StatelessWidget {
  final bool showRemoveAds;
  final bool showBeatPacks;

  const _StorePromoBanner({
    required this.showRemoveAds,
    required this.showBeatPacks,
  });

  @override
  Widget build(BuildContext context) {
    final message = showRemoveAds && showBeatPacks
        ? 'Remove full-screen ads & unlock premium beats → Store'
        : showRemoveAds
            ? 'Remove full-screen ads — one-time €5.99 → Store'
            : 'Unlock exclusive premium beats → Store';

    return GestureDetector(
      onTap: () => context.read<TabNavigationService>().openStore(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E44AD), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BeatListItem extends StatelessWidget {
  final Beat beat;
  final bool isPremium;
  final bool isFavorite;
  final bool isPlaying;
  final bool isRecording;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final VoidCallback onRecord;
  final VoidCallback onStop;

  const _BeatListItem({
    required this.beat,
    this.isPremium = false,
    required this.isFavorite,
    this.isPlaying = false,
    this.isRecording = false,
    required this.onPlay,
    required this.onFavorite,
    required this.onRecord,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return PlayingBeatCard(
      isPlaying: isPlaying && !isRecording,
      isPremium: isPremium,
      child: Row(
        children: [
          if (isPlaying && !isRecording) ...[
            const PlayingBeatIndicator(),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Row(
              children: [
                if (isPremium) ...[
                  const Icon(Icons.star,
                      color: AppColors.accentOrange, size: 16),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    beat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPlaying && !isRecording
                          ? AppColors.accentGreen
                          : Colors.white,
                      letterSpacing: 0.3,
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
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: onPlay,
            highlight: isPlaying && !isRecording,
          ),
          _IconBtn(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            color: AppColors.danger,
            onTap: onFavorite,
          ),
          if (!isRecording)
            _LabelBtn(
              label: 'Sing & Record',
              icon: Icons.radio,
              color: AppColors.success,
              onTap: onRecord,
            )
          else
            _LabelBtn(
              label: 'Stop',
              icon: Icons.stop,
              color: AppColors.danger,
              onTap: onStop,
            ),
        ],
      ),
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
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
