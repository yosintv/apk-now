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
    // Use ref.read here to avoid re-triggering logic on every build cycle
    final isInit = ref.read(adSdkInitializedProvider);
    if (isInit && _bannerAd == null && !_isLoading) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final lastFail = _lastFailTime;
    if (lastFail != null && 
        DateTime.now().difference(lastFail).inSeconds < 15) {
      return;
    }

    final adService = ref.read(adServiceProvider);
    final config = ref.read(configProvider);

    if (!adService.adsAllowed || !config.bannerEnabled || adService.bannerAdId.isEmpty) return;

    if (!mounted) return;
    
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return;

    setState(() => _isLoading = true);

    try {
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          mediaQuery.size.width.truncate());

      if (size == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: adService.bannerAdId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
                _isLoading = false;
                _adSize = size;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
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
    final ad = _bannerAd;
    final size = _adSize;
    
    if (_isLoaded && ad != null && size != null) {
      return Container(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: AdWidget(ad: ad),
      );
    }
    return const SizedBox(height: 50);
  }
}
