import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/config_provider.dart';
import '../models/app_config.dart';

final adSdkInitializedProvider = StateProvider<bool>((ref) => false);

final adServiceProvider = Provider<AdService>((ref) {
  final config = ref.watch(configProvider);
  final isInit = ref.watch(adSdkInitializedProvider);
  final service = AdService(config);
  
  if (isInit && service.adsAllowed) {
    service.loadAppOpenAd(showImmediately: true);
    service.loadInterstitialAd();
    service.loadRewardedAd();
  }

  ref.onDispose(() => service.dispose());
  return service;
});

class AdService {
  final AppConfig _config;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isShowingAd = false;
  bool _appOpenShownOnce = false;
  
  DateTime? _lastInterstitialTime;
  int _matchClickCount = 0;
  
  final int _clicksRequired = 4;
  final Duration _minInterval = const Duration(minutes: 2);

  AdService(this._config);

  bool get adsAllowed => _config.adsEnabled && !_config.reviewMode;

  String get bannerAdId => _config.bannerAdId;
  String get appOpenAdId => _config.appOpenAdId;
  String get interstitialAdId => _config.interstitialAdId;
  String get rewardedAdId => _config.rewardedAdId;

  void dispose() {
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  // --- App Open Ad ---
  void loadAppOpenAd({bool showImmediately = false}) {
    if (!adsAllowed || !_config.appOpenEnabled) return;

    AppOpenAd.load(
      adUnitId: appOpenAdId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          if (showImmediately && !_appOpenShownOnce) {
             showAppOpenAdIfAvailable();
             _appOpenShownOnce = true;
          }
        },
        onAdFailedToLoad: (error) => _appOpenAd = null,
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;
    if (!adsAllowed || _isShowingAd || ad == null) return;
    
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      }
    );
    ad.show();
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    if (!adsAllowed || !_config.interstitialEnabled) return;
    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onAdDismissed}) {
    _matchClickCount++;
    final now = DateTime.now();
    
    final lastTime = _lastInterstitialTime;
    bool timeReached = lastTime == null || 
                      now.difference(lastTime) > _minInterval;
    bool clicksReached = _matchClickCount >= _clicksRequired;

    final ad = _interstitialAd;

    if (!adsAllowed || ad == null || !timeReached || !clicksReached) {
      onAdDismissed();
      if (ad == null) loadInterstitialAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _lastInterstitialTime = DateTime.now();
        _matchClickCount = 0;
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
    );
    ad.show();
  }

  // --- Rewarded Ad ---
  void loadRewardedAd() {
    if (!adsAllowed || !_config.rewardedEnabled) return;
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void showRewardedAd({required void Function(RewardItem) onUserEarnedReward, VoidCallback? onAdDismissed}) {
    final ad = _rewardedAd;
    if (!adsAllowed || ad == null) {
      onAdDismissed?.call();
      loadRewardedAd();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdDismissed?.call();
      }
    );
    ad.show(onUserEarnedReward: (ad, reward) => onUserEarnedReward(reward));
  }
}
