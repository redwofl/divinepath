import 'dart:async';
import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';
import '../config/app_config.dart';

/// Start.io (StartApp) powered ad service.
///
/// Wires the app's existing ad surface (banner / interstitial / rewarded) to
/// the Start.io Flutter SDK. Everything is a no-op when [AppConfig.enableAds]
/// is false, so ads stay off for clean/development builds.
class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  final StartAppSdk _sdk = StartAppSdk();

  /// Whether ads are enabled at all (AppConfig.enableAds).
  bool get isEnabled => AppConfig.enableAds;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  StartAppInterstitialAd? _interstitialAd;
  bool get isInterstitialReady => _interstitialAd != null;

  StartAppRewardedVideoAd? _rewardedVideoAd;
  bool get isRewardedReady => _rewardedVideoAd != null;

  /// Completer for an in-flight rewarded video (completes on video close).
  Completer<bool>? _rewardCompleter;

  /// Banner ad, loaded once and kept (auto-refreshing).
  StartAppBannerAd? _bannerAd;
  final ValueNotifier<StartAppBannerAd?> _bannerNotifier =
      ValueNotifier<StartAppBannerAd?>(null);

  /// Auto-refreshing banner backing the [AdBannerWidget].
  EdgeInsets padding = EdgeInsets.zero;

  Future<void> initialize() async {
    if (!isEnabled) return;
    _initialized = true;
    loadBannerAd();
    loadInterstitial();
  }

  /// Load the auto-refreshing banner once (kept for the whole session).
  Future<void> loadBannerAd() async {
    if (!isEnabled || _bannerAd != null) return;
    try {
      final ad = await _sdk.loadBannerAd(StartAppBannerType.BANNER);
      _bannerAd = ad;
      _bannerNotifier.value = ad;
    } catch (e) {
      debugPrint('Start.io banner load error: $e');
    }
  }

  void loadInterstitial() {
    if (!isEnabled || _interstitialAd != null) return;
    _sdk.loadInterstitialAd(
      onAdNotDisplayed: _clearInterstitial,
      onAdHidden: _clearInterstitial,
    ).then((ad) {
      _interstitialAd = ad;
    }).catchError((Object e, StackTrace st) {
      debugPrint('Start.io interstitial load error: $e');
    });
  }

  void loadRewarded() {
    if (!isEnabled || _rewardedVideoAd != null) return;
    final completer = Completer<bool>();
    _rewardCompleter = completer;
    _sdk.loadRewardedVideoAd(
      onVideoCompleted: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdNotDisplayed: () {
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdHidden: () {
        if (!completer.isCompleted) completer.complete(false);
      },
    ).then((ad) {
      _rewardedVideoAd = ad;
    }).catchError((Object e, StackTrace st) {
      debugPrint('Start.io rewarded load error: $e');
      if (!completer.isCompleted) completer.complete(false);
    });
  }

  void _clearInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    loadInterstitial();
  }

  Future<bool> showInterstitial({bool recordAsAppOpen = false}) async {
    if (!isEnabled || _interstitialAd == null) return false;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    try {
      final shown = await ad.show();
      if (!shown) ad.dispose();
      return shown;
    } catch (e) {
      ad.dispose();
      return false;
    } finally {
      loadInterstitial();
    }
  }

  Future<bool> showRewarded() async {
    if (!isEnabled || _rewardedVideoAd == null) return false;
    final ad = _rewardedVideoAd!;
    _rewardedVideoAd = null;
    try {
      final shown = await ad.show();
      if (!shown) {
        ad.dispose();
        loadRewarded();
        return false;
      }
    } catch (e) {
      ad.dispose();
      loadRewarded();
      return false;
    }

    final completer = _rewardCompleter;
    _rewardCompleter = null;
    ad.dispose();

    if (completer == null) {
      loadRewarded();
      return false;
    }
    final earned = await completer.future
        .timeout(const Duration(seconds: 60), onTimeout: () => false);
    loadRewarded();
    return earned;
  }

  /// App-open splash is handled automatically by the Start.io SDK (splash +
  /// return ads), so no manual app-open ad is shown here.
  Future<void> showAppOpenOnStartup() async {}

  Future<void> showAppOpenIfAvailable() async {}
}

/// Renders the Start.io auto-refreshing banner (empty widget when disabled).
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key, this.adUnitId});

  /// Kept for API compatibility (harmless, Start.io has no ad-unit ids).
  final String? adUnitId;

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.isEnabled) return const SizedBox.shrink();
    return ValueListenableBuilder<StartAppBannerAd?>(
      valueListenable: AdService.instance._bannerNotifier,
      builder: (context, ad, _) {
        if (ad == null) return const SizedBox.shrink();
        return Center(
          child: StartAppBanner(ad),
        );
      },
    );
  }
}