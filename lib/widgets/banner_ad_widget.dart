import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/config_provider.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  void _loadAd() {
    if (_isLoading || _bannerAd != null) return;

    final config = ref.read(configProvider);
    if (!config.adsEnabled || !config.bannerEnabled || config.reviewMode ||
        config.bannerAdId.isEmpty) {
      return;
    }

    _isLoading = true;
    _bannerAd = BannerAd(
      adUnitId: config.bannerAdId,
      size: AdSize.banner,
      request: AdService.buildRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() { _isLoaded = true; _isLoading = false; });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() { _isLoaded = false; _bannerAd = null; _isLoading = false; });
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && _bannerAd == null && !_isLoading) _loadAd();
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(adSdkInitializedProvider, (_, isInit) {
      if (isInit && _bannerAd == null && !_isLoading) _loadAd();
    });

    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 2),
      alignment: Alignment.center,
      width: double.infinity,
      height: ad.size.height.toDouble() + 4,
      child: AdWidget(ad: ad),
    );
  }
}
