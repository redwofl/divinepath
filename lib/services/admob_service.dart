import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

/// Google AdMob rewarded ads.
///
/// Used specifically for the "+1 mala bonus" flow, because Start.io's
/// rewarded inventory was unreliable for this app. Everything no-ops on
/// unsupported platforms (web/desktop): [isSupported] is false there and
/// [showRewarded] returns false without touching the SDK.
class AdmobService {
  AdmobService._();
  static final AdmobService instance = AdmobService._();

  bool _sdkReady = false;
  bool get isSdkReady => _sdkReady;

  RewardedAd? _rewardedAd;
  DateTime _lastLoadAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether this platform can show AdMob ads at all.
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// A rewarded ad is loaded and ready to show right now.
  bool get isRewardedReady => _rewardedAd != null;

  /// Initialize the AdMob SDK (safe to call on any platform).
  Future<void> initialize() async {
    if (!isSupported || _sdkReady) return;
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
      debugPrint('AdMob initialized');
      loadRewarded();
    } catch (e) {
      debugPrint('AdMob initialize error: $e');
    }
  }

  /// Preload a rewarded ad. [force] bypasses the retry throttle so a user
  /// tap can trigger an immediate load attempt.
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
}
