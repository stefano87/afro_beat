/// Central branding & content config for Afro Beat Trap Studio 2026.
/// Update CDN paths, radio stations, and store IDs when ready.
class AppConfig {
  AppConfig._();

  // ── Identity ──────────────────────────────────────────────────────────────
  static const appTitle = 'Afro Beat Trap Studio 2026';
  static const beatTabTitle = 'Afro Beats';
  static const beatTabSubtitle = 'Afro Beat & Afro Trap instrumentals';
  static const radioTabTitle = 'Afro Radio';
  static const radioTabSubtitle =
      'Live afrobeat stations & more — in our dedicated radio app';

  static const afroRadioAppTitle = 'Afrobeats Radio & Afro Beats';
  static const afroRadioAppPackageId = 'com.afroradio.android';
  static const afroRadioPlayStoreMarketUrl =
      'market://details?id=com.afroradio.android';
  static const afroRadioPlayStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.afroradio.android';
  static const afroRadioAppIconAsset = 'assets/afro_radio_app_icon.png';
  static const favoritesSubtitle = 'Afro Beat';

  /// New Play Store listing (Flutter rebuild).
  static const androidPackageId = 'com.afrobeattrap.studio';
  static const playStoreMarketUrl =
      'market://details?id=com.afrobeattrap.studio';
  static const playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.afrobeattrap.studio';

  /// Legacy Andromo listing — link from old app description only.
  static const legacyAndroidPackageId = 'com.andromo.dev127586.app1066667';
  static const legacyPlayStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.andromo.dev127586.app1066667';

  // ── Assets (replace under assets/ when you have afro artwork) ───────────
  static const logoAsset = 'assets/app_icon.png';
  static const listBackgroundAsset = 'assets/background-afro.png';

  // ── Free beats CDN ────────────────────────────────────────────────────────
  static const beatsCdnBaseUrl =
      'https://www.gadgetchespaccano.it/beat/';
  static const freeBeatFileName = 'beat.mp3';
  static const freeBeatCount = 120;
  static const freeBeatNamePrefix = 'AFRO BEAT TRAP';

  static const afroCdnBaseUrl = 'https://www.gadgetchespaccano.it/afro/';
  static const afroBeatCount = 48;
  static const afroBeatNamePrefix = 'AFRO';

  // ── Premium beats CDN (TODO) ──────────────────────────────────────────────
  static const premiumCdnBaseUrl =
      'https://www.gadgetchespaccano.it/afrobeat/premium/';

  // ── SharedPreferences keys (prefixed to avoid clashes with Hip Hop app) ───
  static const licenseAcceptedKey = 'afrobeat_license_accepted';
  static const ownedBeatPackIdsKey = 'afro_owned_beat_pack_ids';
  static const favoritesStorageKey = 'afro_favorite_beats';
  static const savedRecordingsKey = 'afro_saved_recordings_index';
  static const ratingStatusKey = 'afro_rating_status';
  static const lastRatingPromptKey = 'afro_last_rating_prompt';

  // ── AdMob (TODO: create dedicated ad units for this app on AdMob) ─────────
  static const admobAppId = 'ca-app-pub-5162875721816233~4035290375';
  static const admobBannerUnitId = 'ca-app-pub-5162875721816233/5947137845';
  static const admobInterstitialUnitId =
      'ca-app-pub-5162875721816233/9997726787';
}
