import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/feature_flags.dart';
import '../services/admob_service.dart';
import '../services/beat_audio_service.dart';
import '../services/purchase_service.dart';
import '../services/recording_session.dart';
import '../services/rating_service.dart';
import '../services/tab_navigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/info_modal.dart';
import 'beat_list_screen.dart';
import 'community_screen.dart';
import 'favorites_screen.dart';
import 'recordings_screen.dart';
import 'store_screen.dart';
import 'webradio_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  PurchaseService? _purchases;
  Timer? _ratingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final adMob = context.read<AdMobService>();
      final beatAudio = context.read<BeatAudioService>();
      final session = context.read<RecordingSession>();
      final rating = context.read<RatingService>();

      await rating.ensureFirstLaunchRecorded();
      _ratingTimer = Timer(const Duration(minutes: 5), () async {
        if (!mounted) return;
        await RatingPopup.showIfNeeded(
          context,
          trigger: RatingPromptTrigger.timeInApp,
        );
      });

      adMob.bindPeriodicInterstitialBlockGate(
        () =>
            beatAudio.isPlaying ||
            session.isAnyBeatRecording ||
            session.showCountdown ||
            session.isPreparing ||
            session.isStopping,
      );

      if (kEnablePremiumStore) {
        _purchases = context.read<PurchaseService>();
        _purchases!.addListener(_syncInterstitialAds);
        _syncInterstitialAds();
      } else {
        adMob.startPeriodicInterstitials();
      }
    });
  }

  void _syncInterstitialAds() {
    if (!mounted || _purchases == null) return;

    final adMob = context.read<AdMobService>();
    if (_purchases!.hasRemovedInterstitials) {
      adMob.stopPeriodicInterstitials();
      adMob.cancelInterstitialAd();
      return;
    }

    adMob.startPeriodicInterstitials();
  }

  @override
  void dispose() {
    _ratingTimer?.cancel();
    _purchases?.removeListener(_syncInterstitialAds);
    context.read<AdMobService>().stopPeriodicInterstitials();
    super.dispose();
  }

  static final _screens = kEnablePremiumStore
      ? const [
          BeatListScreen(),
          StoreScreen(),
          RecordingsScreen(),
          FavoritesScreen(),
          WebradioScreen(),
        ]
      : const [
          BeatListScreen(),
          RecordingsScreen(),
          FavoritesScreen(),
          WebradioScreen(),
        ];

  @override
  Widget build(BuildContext context) {
    final adMob = context.watch<AdMobService>();
    final nav = context.watch<TabNavigationService>();
    final banner = adMob.bannerAd;

    return Scaffold(
      body: IndexedStack(
        index: nav.currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (banner != null)
            SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tabBarStart, AppColors.tabBarEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: nav.currentTab,
                onTap: nav.setTab,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.music_note),
                    label: 'Beat',
                  ),
                  if (kEnablePremiumStore)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.storefront),
                      label: 'Store',
                    ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.library_music),
                    label: 'Recordings',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.mic),
                    label: 'Favorites',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.radio),
                    label: 'Radio',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void openCommunity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }
}

