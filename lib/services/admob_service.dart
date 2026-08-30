import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

/// Google AdMob banner and interstitial ads.
///
/// Used for the main banner at the bottom and interstitial ads (e.g., game over).
class AdmobService {
  AdmobService._();
  static final AdmobService instance = AdmobService._();

  bool _sdkReady = false;
  bool get isSdkReady => _sdkReady;

  BannerAd? _bannerAd;
  bool get isBannerReady => _bannerAd != null;

  InterstitialAd? _interstitialAd;
  bool get isInterstitialReady => _interstitialAd != null;

  RewardedAd? _rewardedAd;
  DateTime _lastLoadAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether this platform can show AdMob ads at all.
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Timer? _initRetryTimer;
  int _initRetryCount = 0;
  static const int _maxInitRetries = 3;

  /// Initialize the AdMob SDK (safe to call on any platform).
  Future<void> initialize() async {
    if (!isSupported || _sdkReady) return;
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
      debugPrint('AdMob initialized successfully');
      loadRewarded();
      loadBannerAd();
      loadInterstitial();
    } catch (e) {
      debugPrint('AdMob initialize error: $e');
      // Retry initialization with backoff
      if (_initRetryCount < _maxInitRetries) {
        _initRetryCount++;
        final delay = Duration(seconds: 3 * _initRetryCount);
        _initRetryTimer?.cancel();
        _initRetryTimer = Timer(delay, () => initialize());
      }
    }
  }

  /// Load a rewarded ad.
  void loadRewarded({bool force = false}) {
    if (!isSupported || !_sdkReady) return;
    if (_rewardedAd != null) return;
    // AdMob rate-limits ad requests; avoid hammering it in tight loops.
    if (!force &&
        DateTime.now().difference(_lastLoadAttempt) <
            const Duration(seconds: 10)) {
      return;
    }
    _lastLoadAttempt = DateTime.now();

    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('AdMob rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          debugPrint('AdMob rewarded failed to load: $error');
        },
      ),
    );
  }

  /// Whether a rewarded ad is loaded and ready to show.
  bool get isRewardedReady => _rewardedAd != null;

  /// Show the loaded rewarded ad.
  ///
  /// Returns true only when the user actually earned the reward (watched
  /// enough of the video). Always triggers a background reload afterwards.
  Future<bool> showRewarded() async {
    final ad = _rewardedAd;
    if (!isSupported || !_sdkReady || ad == null) return false;
    _rewardedAd = null;

    bool earned = false;
    final closed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
        loadRewarded(force: true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob rewarded failed to show: $error');
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
        loadRewarded(force: true);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) => earned = true,
      );
    } catch (e) {
      debugPrint('AdMob rewarded show error: $e');
      ad.dispose();
      loadRewarded(force: true);
      return false;
    }

    // Wait until the user closes the ad (or showing fails) before reporting.
    await closed.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    return earned;
  }

  Timer? _bannerRetryTimer;
  int _bannerRetryCount = 0;
  static const int _maxBannerRetries = 5;

  /// Load a banner ad with automatic retry on failure.
  void loadBannerAd() {
    if (!isSupported || !_sdkReady) return;
    _bannerAd?.dispose();
    _bannerAd = null;

    _bannerAd = BannerAd(
      adUnitId: AppConfig.admobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerRetryCount = 0;
          debugPrint('AdMob banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          // Retry with exponential backoff
          if (_bannerRetryCount < _maxBannerRetries) {
            _bannerRetryCount++;
            final delay = Duration(seconds: 2 * _bannerRetryCount);
            _bannerRetryTimer?.cancel();
            _bannerRetryTimer = Timer(delay, () {
              if (_sdkReady && _bannerAd == null) loadBannerAd();
            });
          }
        },
      ),
    )..load();
  }

  /// Show the banner widget.
  Widget getBannerWidget({
    required double width,
    required double height,
  }) {
    if (!isSupported || !_sdkReady || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Timer? _interstitialRetryTimer;
  int _interstitialRetryCount = 0;
  static const int _maxInterstitialRetries = 5;

  /// Load an interstitial ad with automatic retry on failure.
  void loadInterstitial() {
    if (!isSupported || !_sdkReady) return;
    InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialRetryCount = 0;
          _interstitialAd = ad;
          debugPrint('AdMob interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob interstitial failed to load: $error');
          _interstitialAd?.dispose();
          _interstitialAd = null;
          // Retry with exponential backoff
          if (_interstitialRetryCount < _maxInterstitialRetries) {
            _interstitialRetryCount++;
            final delay = Duration(seconds: 2 * _interstitialRetryCount);
            _interstitialRetryTimer?.cancel();
            _interstitialRetryTimer = Timer(delay, () {
              if (_sdkReady && _interstitialAd == null) loadInterstitial();
            });
          }
        },
      ),
    );
  }

  /// Show the interstitial ad if loaded.
  ///
  /// Returns true only when the ad was shown.
  Future<bool> showInterstitial() async {
    if (!isSupported || !_sdkReady || _interstitialAd == null) return false;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    try {
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('AdMob interstitial show error: $e');
      ad.dispose();
      return false;
    } finally {
      loadInterstitial();
    }
  }
}