import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  FirebaseAnalytics? _analytics;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('[Analytics] init error: $e');
    }
  }

  Future<void> logPageView(String page) async {
    try {
      await _analytics?.logEvent(name: 'page_view', parameters: {'page': page});
    } catch (e) {
      debugPrint('[Analytics] log error: $e');
    }
  }
}
