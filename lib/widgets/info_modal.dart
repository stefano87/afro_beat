import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../screens/community_screen.dart';
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunityScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Community - Submit Your Song'),
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
  const RatingPopup({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final ratingService = context.read<RatingService>();
    if (await ratingService.shouldShowRatingPrompt()) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const RatingPopup(),
        );
      }
    }
  }

  Future<void> _rateNow(BuildContext context) async {
    final ratingService = context.read<RatingService>();
    await ratingService.rateApp();
    final uri = Uri.parse(
      AppConfig.playStoreMarketUrl,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _dismiss(BuildContext context) async {
    await context.read<RatingService>().dismissRating();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _dismiss(context),
                  child: const Text('❌ Close'),
                ),
              ),
              const Icon(Icons.star, size: 64, color: Colors.amber),
              const SizedBox(height: 12),
              const Text(
                '⭐ Do you like our app? ⭐',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your feedback means a lot to us! ❤️ If you enjoy using our app, '
                'please leave ⭐⭐⭐⭐⭐ or a review! 📝',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _rateNow(context),
                  child: const Text('📝 Leave a Review'),
                ),
              ),
              TextButton(
                onPressed: () => _dismiss(context),
                child: const Text('⏳ Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
