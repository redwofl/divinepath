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

  /// Initialize the AdMob SDK (safe to call on any platform).
  Future<void> initialize() async {
    if (!isSupported || _sdkReady) return;
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
      debugPrint('AdMob initialized');
      loadRewarded();
      loadBannerAd();
      loadInterstitial();
    } catch (e) {
      debugPrint('AdMob initialize error: $e');
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

  /// Load a banner ad.
  void loadBannerAd() {
    if (!isSupported || !_sdkReady) return;
    if (_bannerAd != null) _bannerAd!.dispose();

    _bannerAd = BannerAd(
      adUnitId: AppConfig.admobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdMob banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner failed to load: $error');
          ad.dispose();
          _bannerAd = null;
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

  /// Load an interstitial ad.
  void loadInterstitial() {
    if (!isSupported || !_sdkReady) return;
    InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdMob interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob interstitial failed to load: $error');
          _interstitialAd?.dispose();
          _interstitialAd = null;
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