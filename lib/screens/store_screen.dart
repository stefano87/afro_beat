import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/feature_flags.dart';
import '../data/premium_beats_data.dart';
import '../data/store_products_data.dart';
import '../services/admob_service.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/info_modal.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Store',
        subtitle: kEnableBeatPacksInStore
            ? 'Exclusive beats & ad-free experience'
            : 'Remove full-screen ads — one-time purchase',
        onInfoTap: () => InfoModal.show(context),
      ),
      body: Consumer<PurchaseService>(
        builder: (context, purchases, _) {
          if (purchases.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }

          final packs =
              kEnableBeatPacksInStore ? getBeatPacksCatalog() : <BeatPack>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (!purchases.isAvailable && !kDebugMode)
                _InfoBanner(
                  icon: Icons.phone_android,
                  text:
                      'Purchases work on the Android app via Google Play. '
                      'No account needed — your Google account handles everything.',
                ),
              if (kDebugMode && !purchases.isAvailable)
                _InfoBanner(
                  icon: Icons.bug_report,
                  text:
                      'Debug mode: use "Test unlock" to preview premium beats without Play Store.',
                  color: Colors.orange,
                ),
              if (purchases.hasAnyPremium) ...[
                _OwnedSection(purchases: purchases),
                const SizedBox(height: 16),
              ],
              const Text(
                'App Upgrade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'One-time purchase. Restores on new devices with the same Google account.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _RemoveInterstitialAdsCard(
                owned: purchases.hasRemovedInterstitials,
                price: purchases.priceLabel(
                  kRemoveInterstitialAdsProductId,
                  fallback: kRemoveInterstitialAdsFallbackPrice,
                ),
                onBuy: () => _buy(
                  context,
                  purchases,
                  kRemoveInterstitialAdsProductId,
                ),
                onDebugUnlock: kDebugMode
                    ? () => purchases.debugUnlockPack(
                          kRemoveInterstitialAdsProductId,
                        )
                    : null,
              ),
              if (kEnableBeatPacksInStore) ...[
                const SizedBox(height: 24),
                const Text(
                  'Beat Packs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'One-time purchase. Yours forever. Restore anytime with the same Google account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...packs.map(
                  (pack) => _PackCard(
                    pack: pack,
                    owned: purchases.ownsProduct(pack.productId) ||
                        (pack.productId != 'beat_pack_full' &&
                            purchases.ownsProduct('beat_pack_full')),
                    price: purchases.priceLabel(
                      pack.productId,
                      fallback: pack.productId == 'beat_pack_full'
                          ? '€7.99'
                          : '€2.99',
                    ),
                    onBuy: () => _buy(context, purchases, pack.productId),
                    onDebugUnlock: kDebugMode
                        ? () => purchases.debugUnlockPack(pack.productId)
                        : null,
                  ),
                ),
              ],
              if (purchases.isAvailable) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await purchases.restorePurchases();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Purchases restored'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore, color: Colors.white70),
                  label: const Text(
                    'Restore purchases',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
              if (purchases.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  purchases.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              const _WhyGooglePlay(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _buy(
    BuildContext context,
    PurchaseService purchases,
    String productId,
  ) async {
    context.read<AnalyticsService>().logPageView('purchase_attempt_$productId');
    await purchases.buy(productId);
    if (!context.mounted || !purchases.ownsProduct(productId)) return;

    if (productId == kRemoveInterstitialAdsProductId) {
      context.read<AdMobService>().cancelInterstitialAd();
    }

    final message = productId == kRemoveInterstitialAdsProductId
        ? 'Purchase successful! Full-screen ads are now disabled.'
        : 'Purchase successful! Check the Beat tab for your new beats.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    this.color = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _OwnedSection extends StatelessWidget {
  final PurchaseService purchases;

  const _OwnedSection({required this.purchases});

  @override
  Widget build(BuildContext context) {
    final beatCount =
        getUnlockedPremiumBeats(purchases.ownedProductIds).length;
    final lines = <String>[];
    if (beatCount > 0) {
      lines.add('$beatCount premium beats in the Beat tab');
    }
    if (purchases.hasRemovedInterstitials) {
      lines.add('Full-screen ads removed');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withValues(alpha: 0.2),
            AppColors.accentGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your purchases',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...lines.map(
                  (line) => Text(
                    line,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveInterstitialAdsCard extends StatelessWidget {
  final bool owned;
  final String price;
  final VoidCallback onBuy;
  final VoidCallback? onDebugUnlock;

  const _RemoveInterstitialAdsCard({
    required this.owned,
    required this.price,
    required this.onBuy,
    this.onDebugUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: owned
            ? Border.all(color: AppColors.accentGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('🚫', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remove Interstitial Ads',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'No more full-screen interruptions',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (owned)
                  const Icon(Icons.lock_open, color: Colors.white, size: 28)
                else
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enjoy a smoother app experience. This one-time purchase '
                  'removes all full-screen (interstitial) ads from the app.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'What you get:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...kRemoveInterstitialAdsIncludes.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check,
                            color: AppColors.accentGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'What is not included:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...kRemoveInterstitialAdsExclusions.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.accentOrange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (owned)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: AppColors.accentGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Owned — full-screen ads are disabled',
                        style: TextStyle(color: AppColors.accentGreen),
                      ),
                    ],
                  )
                else ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF5500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5500).withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onBuy,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                color: Color(0xFF1A1A1A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Buy for $price',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onDebugUnlock != null)
                    TextButton(
                      onPressed: onDebugUnlock,
                      child: const Text(
                        'Test unlock (debug)',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final BeatPack pack;
  final bool owned;
  final String price;
  final VoidCallback onBuy;
  final VoidCallback? onDebugUnlock;

  const _PackCard({
    required this.pack,
    required this.owned,
    required this.price,
    required this.onBuy,
    this.onDebugUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: owned
            ? Border.all(color: AppColors.accentGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pack.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(pack.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pack.beats.length} exclusive beats',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (owned)
                  const Icon(Icons.lock_open, color: Colors.white, size: 28)
                else
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  pack.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (owned)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: AppColors.accentGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Owned — find beats in the Beat tab',
                        style: TextStyle(color: AppColors.accentGreen),
                      ),
                    ],
                  )
                else ...[
                  FilledButton(
                    onPressed: onBuy,
                    style: FilledButton.styleFrom(
                      backgroundColor: pack.gradient.first,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Buy for $price'),
                  ),
                  if (onDebugUnlock != null)
                    TextButton(
                      onPressed: onDebugUnlock,
                      child: const Text(
                        'Test unlock (debug)',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyGooglePlay extends StatelessWidget {
  const _WhyGooglePlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Google Play?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Zero monthly fees for you\n'
            '• No custom account — uses Google account\n'
            '• Purchases restore on new devices\n'
            '• Required by Google for digital content\n'
            '• Google keeps ~15% commission on sales',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
