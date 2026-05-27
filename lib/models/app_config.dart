// lib/models/app_config.dart
// Central remote configuration model for YoSinTV.
// Deserializes remote/alt/local JSON into typed flags and URL fields.

class AppConfig {
  // --- Ad Control Flags ---
  final bool reviewMode;
  final bool streamingEnabled;
  final bool adsEnabled;
  final bool bannerEnabled;
  final bool rewardedEnabled;
  final bool appOpenEnabled;
  final bool interstitialEnabled;

  // --- AdMob Ad Unit IDs ---
  final String bannerAdId;
  final String rewardedAdId;
  final String appOpenAdId;
  final String interstitialAdId;

  // --- Maintenance & Messaging ---
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String appMessage;
  final String appMessageType; // "info" | "warning" | "error"

  // --- Social Links ---
  final String whatsappLink;
  final String telegramLink;

  // --- Popup ---
  final bool popupEnabled;
  final String popupTitle;
  final String popupText;

  // --- API Endpoints ---
  final String footballApiUrl;
  final String cricketApiUrl;
  final String articlesApiUrl;
  final String altConfigUrl;

  const AppConfig({
    required this.reviewMode,
    required this.streamingEnabled,
    required this.adsEnabled,
    required this.bannerEnabled,
    required this.rewardedEnabled,
    required this.appOpenEnabled,
    required this.interstitialEnabled,
    required this.bannerAdId,
    required this.rewardedAdId,
    required this.appOpenAdId,
    required this.interstitialAdId,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.appMessage,
    required this.appMessageType,
    required this.whatsappLink,
    required this.telegramLink,
    required this.popupEnabled,
    required this.popupTitle,
    required this.popupText,
    required this.footballApiUrl,
    required this.cricketApiUrl,
    required this.articlesApiUrl,
    required this.altConfigUrl,
  });

  /// Convenience: whether any ads should actually be served.
  /// reviewMode always overrides adsEnabled to false.
  bool get shouldShowAds => adsEnabled && !reviewMode;

  /// Convenience: whether banner ads should be injected.
  bool get shouldShowBanner => shouldShowAds && bannerEnabled;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      reviewMode: json['reviewMode'] as bool? ?? false,
      streamingEnabled: json['streamingEnabled'] as bool? ?? true,
      adsEnabled: json['adsEnabled'] as bool? ?? true,
      bannerEnabled: json['bannerEnabled'] as bool? ?? true,
      rewardedEnabled: json['rewardedEnabled'] as bool? ?? true,
      appOpenEnabled: json['appOpenEnabled'] as bool? ?? true,
      interstitialEnabled: json['interstitialEnabled'] as bool? ?? true,
      bannerAdId: json['bannerAdId'] as String? ??
          'ca-app-pub-3940256099942544/6300978111',
      rewardedAdId: json['rewardedAdId'] as String? ??
          'ca-app-pub-3940256099942544/5224354917',
      appOpenAdId: json['appOpenAdId'] as String? ??
          'ca-app-pub-3940256099942544/9257395921',
      interstitialAdId: json['interstitialAdId'] as String? ??
          'ca-app-pub-3940256099942544/1033173712',
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String? ??
          'App is under maintenance. Please try again later.',
      appMessage: json['appMessage'] as String? ?? '',
      appMessageType: json['appMessageType'] as String? ?? 'info',
      whatsappLink:
          json['whatsappLink'] as String? ?? 'https://wa.me/1234567890',
      telegramLink:
          json['telegramLink'] as String? ?? 'https://t.me/yosintv',
      popupEnabled: json['popupEnabled'] as bool? ?? false,
      popupTitle:
          json['popupTitle'] as String? ?? 'Welcome to YoSinTV',
      popupText: json['popupText'] as String? ??
          'Your daily sports companion!',
      footballApiUrl: json['footballApiUrl'] as String? ??
          'https://api.singhs.com.np/api/football-matches.json',
      cricketApiUrl: json['cricketApiUrl'] as String? ??
          'https://api.singhs.com.np/api/cricket-matches.json',
      articlesApiUrl: json['articlesApiUrl'] as String? ??
          'https://api.singhs.com.np/api/articles.json',
      altConfigUrl: json['altConfigUrl'] as String? ??
          'https://api.singhs.com.np/api/alt-config.json',
    );
  }

  /// Merges a remote config map on top of this instance.
  /// Remote values take precedence; null remote values fall back to this instance.
  AppConfig merge(Map<String, dynamic> remote) {
    return AppConfig.fromJson({
      'reviewMode': reviewMode,
      'streamingEnabled': streamingEnabled,
      'adsEnabled': adsEnabled,
      'bannerEnabled': bannerEnabled,
      'rewardedEnabled': rewardedEnabled,
      'appOpenEnabled': appOpenEnabled,
      'interstitialEnabled': interstitialEnabled,
      'bannerAdId': bannerAdId,
      'rewardedAdId': rewardedAdId,
      'appOpenAdId': appOpenAdId,
      'interstitialAdId': interstitialAdId,
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'appMessage': appMessage,
      'appMessageType': appMessageType,
      'whatsappLink': whatsappLink,
      'telegramLink': telegramLink,
      'popupEnabled': popupEnabled,
      'popupTitle': popupTitle,
      'popupText': popupText,
      'footballApiUrl': footballApiUrl,
      'cricketApiUrl': cricketApiUrl,
      'articlesApiUrl': articlesApiUrl,
      'altConfigUrl': altConfigUrl,
      ...remote, // remote keys override local defaults
    });
  }
}
