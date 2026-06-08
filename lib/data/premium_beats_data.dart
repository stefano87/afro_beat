import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/beat.dart';

/// Product IDs must match Google Play Console → Monetize → Products.
const kAllBeatPackProductIds = {
  'beat_pack_afrobeats',
  'beat_pack_afrotrap',
  'beat_pack_afropop',
  'beat_pack_full',
};

const kAfrobeatsPremiumBeatCount = 15;
const kAfroTrapPremiumBeatCount = 15;
const kAfroPopPremiumBeatCount = 15;

int get kPremiumBeatTotalCount =>
    kAfrobeatsPremiumBeatCount +
    kAfroTrapPremiumBeatCount +
    kAfroPopPremiumBeatCount;

List<BeatPack> getBeatPacksCatalog() {
  return [
    BeatPack(
      productId: 'beat_pack_afrobeats',
      title: 'Afrobeats Pack',
      description:
          '$kAfrobeatsPremiumBeatCount exclusive afrobeats instrumentals for freestyle and recording.',
      emoji: '🌍',
      gradient: const [Color(0xFFE67E22), Color(0xFFF1C40F)],
      beats: _generatePackBeats(
        packId: 'afrobeats',
        prefix: 'Afrobeats',
        startId: 10001,
        count: kAfrobeatsPremiumBeatCount,
      ),
    ),
    BeatPack(
      productId: 'beat_pack_afrotrap',
      title: 'Afro Trap Pack',
      description:
          '$kAfroTrapPremiumBeatCount exclusive afro trap beats — dark, bouncy and melodic.',
      emoji: '🔥',
      gradient: const [Color(0xFF8E44AD), Color(0xFFE94560)],
      beats: _generatePackBeats(
        packId: 'afrotrap',
        prefix: 'Afro Trap',
        startId: 10101,
        count: kAfroTrapPremiumBeatCount,
      ),
    ),
    BeatPack(
      productId: 'beat_pack_afropop',
      title: 'Afro Pop Pack',
      description:
          '$kAfroPopPremiumBeatCount exclusive afro pop beats — danceable and radio-ready.',
      emoji: '🎶',
      gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      beats: _generatePackBeats(
        packId: 'afropop',
        prefix: 'Afro Pop',
        startId: 10201,
        count: kAfroPopPremiumBeatCount,
      ),
    ),
    BeatPack(
      productId: 'beat_pack_full',
      title: 'Full Premium Bundle',
      description:
          'All $kPremiumBeatTotalCount beats: $kAfrobeatsPremiumBeatCount afrobeats + '
          '$kAfroTrapPremiumBeatCount afro trap + $kAfroPopPremiumBeatCount afro pop. Best value.',
      emoji: '👑',
      gradient: const [Color(0xFFFFD700), Color(0xFFE67E22)],
      beats: [
        ..._generatePackBeats(
          packId: 'afrobeats',
          prefix: 'Afrobeats',
          startId: 10001,
          count: kAfrobeatsPremiumBeatCount,
        ),
        ..._generatePackBeats(
          packId: 'afrotrap',
          prefix: 'Afro Trap',
          startId: 10101,
          count: kAfroTrapPremiumBeatCount,
        ),
        ..._generatePackBeats(
          packId: 'afropop',
          prefix: 'Afro Pop',
          startId: 10201,
          count: kAfroPopPremiumBeatCount,
        ),
      ],
    ),
  ];
}

List<Beat> _generatePackBeats({
  required String packId,
  required String prefix,
  required int startId,
  required int count,
}) {
  return List.generate(count, (i) {
    final n = i + 1;
    return Beat(
      id: startId + i,
      name: '$prefix $n',
      url: '${AppConfig.premiumCdnBaseUrl}$packId$n.mp3',
    );
  });
}

List<Beat> getUnlockedPremiumBeats(Set<String> ownedProductIds) {
  if (ownedProductIds.contains('beat_pack_full')) {
    return getBeatPacksCatalog()
        .firstWhere((p) => p.productId == 'beat_pack_full')
        .beats;
  }

  final beats = <Beat>[];
  final seenIds = <int>{};
  for (final pack in getBeatPacksCatalog()) {
    if (pack.productId == 'beat_pack_full') continue;
    if (!ownedProductIds.contains(pack.productId)) continue;
    for (final beat in pack.beats) {
      if (seenIds.add(beat.id)) beats.add(beat);
    }
  }
  return beats;
}

class BeatPack {
  final String productId;
  final String title;
  final String description;
  final String emoji;
  final List<Color> gradient;
  final List<Beat> beats;

  const BeatPack({
    required this.productId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.gradient,
    required this.beats,
  });
}
