import '../config/feature_flags.dart';
import '../data/premium_beats_data.dart';

/// Product ID must match Google Play Console → Monetize → Products.
const kRemoveInterstitialAdsProductId = 'remove_interstitial_ads';

const kRemoveInterstitialAdsFallbackPrice = '€5.99';

Set<String> get kAllStoreProductIds => {
      if (kEnableBeatPacksInStore) ...kAllBeatPackProductIds,
      kRemoveInterstitialAdsProductId,
    };

const kRemoveInterstitialAdsIncludes = [
  'No full-screen ads after a successful recording',
  'No periodic full-screen ads while browsing the app',
  'No full-screen ads when opening Community',
  'No full-screen ads while using the Radio tab',
];

const kRemoveInterstitialAdsNotIncluded = [
  'The small banner at the bottom of the screen may still show',
];

const kRemoveInterstitialAdsNotIncludedWithBeatPacks = [
  'The small banner at the bottom of the screen may still show',
  'Premium beat packs are sold separately in this store',
];

List<String> get kRemoveInterstitialAdsExclusions => kEnableBeatPacksInStore
    ? kRemoveInterstitialAdsNotIncludedWithBeatPacks
    : kRemoveInterstitialAdsNotIncluded;
