import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

class AdMobService {
  static const _bannerId = AppConfig.admobBannerUnitId;
  static const _interstitialId = AppConfig.admobInterstitialUnitId;

  static const _periodicInterval = Duration(minutes: 3);

  bool _initialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  Timer? _periodicInterstitialTimer;
  bool _isShowingInterstitial = false;
  bool Function()? _interstitialGate;
  bool Function()? _periodicInterstitialBlockGate;

  void bindInterstitialGate(bool Function() gate) {
    _interstitialGate = gate;
  }

  void bindPeriodicInterstitialBlockGate(bool Function() gate) {
    _periodicInterstitialBlockGate = gate;
  }

  bool get _skipInterstitials => _interstitialGate?.call() ?? false;

  bool get _blockPeriodicInterstitial =>
      _periodicInterstitialBlockGate?.call() ?? false;

  BannerAd? get bannerAd => _bannerAd;

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Show Google's UMP consent form. Must be called before [initialize].
  Future<void> requestUmpConsent(BuildContext context) async {
    if (!_isMobile) return;

    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // Info updated — show form if required
        if (!context.mounted) {
          completer.complete();
          return;
        }
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('UMP form error: ${formError.message}');
          }
          completer.complete();
        });
      },
      (FormError error) {
        debugPrint('UMP consent info error: ${error.message}');
        completer.complete();
      },
    );

    await completer.future;
  }

  Future<void> initialize() async {
    if (!_isMobile) return;
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdMob initialized');
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
  }

  Future<void> showBanner() async {
    if (!_initialized) await initialize();
    if (!_initialized || kIsWeb) return;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    await _bannerAd!.load();
  }

  Future<void> hideBanner() async {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  void cancelInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  Future<void> prepareInterstitial() async {
    if (_skipInterstitials) return;
    if (!_initialized) await initialize();
    if (!_initialized || kIsWeb) return;

    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial load failed: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void startPeriodicInterstitials() {
    stopPeriodicInterstitials();
    _periodicInterstitialTimer = Timer.periodic(
      _periodicInterval,
      (_) => _tryShowPeriodicInterstitial(),
    );
  }

  void stopPeriodicInterstitials() {
    _periodicInterstitialTimer?.cancel();
    _periodicInterstitialTimer = null;
  }

  Future<void> _tryShowPeriodicInterstitial() async {
    if (_blockPeriodicInterstitial) return;
    await showInterstitial();
  }

  Future<void> showInterstitial() async {
    if (_skipInterstitials || _isShowingInterstitial) return;
    if (!_initialized) await initialize();
    if (!_initialized || kIsWeb) return;

    if (_interstitialAd == null) {
      await prepareInterstitial();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final ad = _interstitialAd;
    if (ad == null) return;

    _isShowingInterstitial = true;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        prepareInterstitial();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        completer.complete();
      },
    );
    try {
      await ad.show();
      await completer.future;
    } finally {
      _isShowingInterstitial = false;
    }
  }

  void dispose() {
    stopPeriodicInterstitials();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
