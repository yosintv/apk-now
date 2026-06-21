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

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  DateTime? _lastFailTime;

  @override
  bool get wantKeepAlive => _isLoaded;

  @override
  void initState() {
    super.initState();
    // Start loading on the first frame — earliest possible moment.
    // Uses addPostFrameCallback so the widget is fully in the tree
    // and ref/context are safe to use.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(adSdkInitializedProvider)) { _loadAd(); }
    });
  }

  void _loadAd() {
    final lastFail = _lastFailTime;
    if (lastFail != null &&
        DateTime.now().difference(lastFail).inSeconds < 5) return;
    if (_isLoading || _bannerAd != null) return;

    final adService = ref.read(adServiceProvider);
    final config = ref.read(configProvider);
    if (!adService.adsAllowed ||
        !config.bannerEnabled ||
        adService.bannerAdId.isEmpty) { return; }

    _isLoading = true;

    // AdSize.banner (320×50) is synchronous — no async platform call needed.
    // getLargeAnchoredAdaptiveBannerAdSize was causing ~40px of whitespace
    // inside AdWidget and added ~100ms of latency.
    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdId,
      size: AdSize.banner,
      request: AdService.buildRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
            updateKeepAlive();
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
    super.build(context);
    ref.listen<bool>(adSdkInitializedProvider, (_, isInit) {
      if (isInit && _bannerAd == null && !_isLoading) _loadAd();
    });

    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 50,
      color: Colors.white,
      alignment: Alignment.center,
      child: SizedBox(
        width: 320,
        height: 50,
        child: AdWidget(ad: ad),
      ),
    );
  }
}
