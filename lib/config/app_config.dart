class AppConfig {
  // Gemini AI
  static const String geminiApiKey = '';

  // Dev toggles
  static const bool useSampleStoriesOnly = true;

  // Start.io ads
  static const bool enableAds = false;
  static const bool enableTestAds = false;

  // AdMob — Set to true for testing, false for production (Play Store release)
  static const bool useTestAds = false;

  // AdMob App ID
  static const String admobAppId = 'ca-app-pub-3333666454328224~4248449307';

  // ── Test Ad Unit IDs (Google's official test IDs — always work) ──
  static const String _testBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // ── Production Ad Unit IDs (your real ads — used after Play Store publish) ──
  static const String _prodBannerUnitId = 'ca-app-pub-3333666454328224/1469532281';
  static const String _prodInterstitialUnitId = 'ca-app-pub-3333666454328224/8804719523';
  static const String _prodRewardedUnitId = 'ca-app-pub-3333666454328224/1179201328';

  // Public getters — auto-select test or production IDs
  static String get admobBannerUnitId => useTestAds ? _testBannerUnitId : _prodBannerUnitId;
  static String get admobInterstitialUnitId => useTestAds ? _testInterstitialUnitId : _prodInterstitialUnitId;
  static String get admobRewardedUnitId => useTestAds ? _testRewardedUnitId : _prodRewardedUnitId;
}
