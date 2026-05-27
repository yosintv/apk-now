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
  
  // Adjusted thresholds for premium UX
  final int _clicksRequired = 4; // Show ad every 4th match click
  final Duration _minInterval = const Duration(minutes: 2); // At least 2 mins apart

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
    if (!adsAllowed || _isShowingAd || _appOpenAd == null) return;
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
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
    
    bool timeReached = _lastInterstitialTime == null || 
                      now.difference(_lastInterstitialTime!) > _minInterval;
    bool clicksReached = _matchClickCount >= _clicksRequired;

    // Logic: If not ready or cap not met, bypass silently (No "failed" alert to user)
    if (!adsAllowed || _interstitialAd == null || !timeReached || !clicksReached) {
      onAdDismissed();
      if (_interstitialAd == null) loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
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
    _interstitialAd!.show();
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
    if (!adsAllowed || _rewardedAd == null) {
      onAdDismissed?.call();
      loadRewardedAd();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdDismissed?.call();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onUserEarnedReward(reward));
  }
}
