import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/rating_service.dart';

class InfoModal extends StatelessWidget {
  const InfoModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Column(
              children: [
                const Icon(Icons.code, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'App 4 Lov',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Creativity & Innovation',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: const [
                    _FeatureCard(
                      icon: Icons.rocket_launch_outlined,
                      color: Colors.green,
                      title: 'Innovation',
                      subtitle: 'Cutting-edge solutions for your needs',
                    ),
                    _FeatureCard(
                      icon: Icons.favorite_outline,
                      color: Colors.red,
                      title: 'Passion',
                      subtitle: 'We love what we do',
                    ),
                    _FeatureCard(
                      icon: Icons.speed_outlined,
                      color: Colors.green,
                      title: 'Performance',
                      subtitle: 'Fast and optimized apps',
                    ),
                    _FeatureCard(
                      icon: Icons.people_outline,
                      color: Colors.orange,
                      title: 'User-Friendly',
                      subtitle: 'Focused on user experience',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'We are a team of passionate developers specializing in creating '
                  'innovative and intuitive solutions. With a mix of creativity and '
                  'technology, we develop high-performance apps designed to offer you '
                  'the best possible experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.6),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const InfoModal(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingPopup extends StatelessWidget {
  static Future<void> showIfNeeded(
    BuildContext context, {
    RatingPromptTrigger trigger = RatingPromptTrigger.recordingPlayback,
  }) async {
    final ratingService = context.read<RatingService>();
    if (!await ratingService.shouldShowForTrigger(trigger)) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => RatingPopup(
          onDismiss: () => ratingService.dismissRating(),
        ),
      );
    }
  }

  Future<void> _rateNow(BuildContext context) async {
    final ratingService = context.read<RatingService>();
    await ratingService.rateApp();
    final uri = Uri.parse(AppConfig.playStoreMarketUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse(AppConfig.playStoreWebUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  final Future<void> Function() onDismiss;

  const RatingPopup({super.key, required this.onDismiss});

  Future<void> _dismiss(BuildContext context) async {
    await onDismiss();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _dismiss(context);
      },
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF5500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Column(
                    children: [
                      Text('🎤🔥', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text(
                        'Loving the vibes?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () => _dismiss(context),
                    icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  const Text(
                    '⭐ ⭐ ⭐ ⭐ ⭐',
                    style: TextStyle(fontSize: 28, letterSpacing: 4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'If ${AppConfig.appTitle} is helping your flow, a quick '
                    '5-star review on Google Play would mean the world to us! 🌍',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'It takes 10 seconds and helps us drop even more fire beats '
                    'for you. Thank you! 🙏🎶',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _rateNow(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5500),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '⭐ Rate 5 Stars on Google Play',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _dismiss(context),
                    child: const Text(
                      'Maybe later 😊',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
