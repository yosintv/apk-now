import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/config_provider.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  AdSize? _adSize;
  DateTime? _lastFailTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isInit = ref.watch(adSdkInitializedProvider);
    if (isInit && _bannerAd == null && !_isLoading) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // Basic cooldown to prevent "Too many recently failed requests" (Error Code 1)
    if (_lastFailTime != null && 
        DateTime.now().difference(_lastFailTime!).inSeconds < 15) {
      return;
    }

    final adService = ref.read(adServiceProvider);
    final config = ref.read(configProvider);

    if (!adService.adsAllowed || !config.bannerEnabled) return;

    setState(() => _isLoading = true);

    try {
      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate());

      if (size == null) {
        setState(() => _isLoading = false);
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: adService.bannerAdId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('AdMob: [Banner] Loaded Successfully ✅');
            if (mounted) {
              setState(() {
                _isLoaded = true;
                _isLoading = false;
                _adSize = size;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('AdMob: [Banner] Failed ❌ Code: ${error.code} - ${error.message}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
                _isLoading = false;
                _lastFailTime = DateTime.now();
              });
            }
          },
        ),
      )..load();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Return a fixed height placeholder while loading or if failed to prevent layout jumping
    return const SizedBox(height: 50);
  }
}
