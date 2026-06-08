import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/feature_flags.dart';
import 'services/admob_service.dart';
import 'services/analytics_service.dart';
import 'services/beat_audio_service.dart';
import 'services/favorites_service.dart';
import 'services/purchase_service.dart';
import 'services/tab_navigation_service.dart';
import 'services/rating_service.dart';
import 'services/recording_session.dart';
import 'services/saved_recordings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config added via google-services.json on Android build.
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final beatAudio = BeatAudioService();
  final adMob = AdMobService();
  final favorites = FavoritesService();
  await favorites.load();

  final savedRecordings = SavedRecordingsService();
  await savedRecordings.load();

  final analytics = AnalyticsService();
  await analytics.initialize();

  final purchases = PurchaseService();
  if (kEnablePremiumStore) {
    await purchases.initialize();
    adMob.bindInterstitialGate(() => purchases.hasRemovedInterstitials);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: analytics),
        Provider.value(value: adMob),
        Provider.value(value: RatingService()),
        ChangeNotifierProvider(create: (_) => TabNavigationService()),
        ChangeNotifierProvider.value(value: purchases),
        ChangeNotifierProvider.value(value: favorites),
        ChangeNotifierProvider.value(value: savedRecordings),
        ChangeNotifierProvider.value(value: beatAudio),
        ChangeNotifierProvider(
          create: (_) => RecordingSession(
            beatAudio: beatAudio,
            adMob: adMob,
            savedRecordings: savedRecordings,
          ),
        ),
      ],
      child: const AfroBeatTrapApp(),
    ),
  );
}
