// lib/models/app_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

bool _toBool(dynamic value, bool defaultValue) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  if (value is num) return value == 1;
  return defaultValue;
}

class AppUpdateInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String popupTitle;
  final String popupMessage;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.popupTitle,
    required this.popupMessage,
  });

  factory AppUpdateInfo.fromJson(Map<dynamic, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: (json['latest_version'] ?? json['latestVersion'] ?? '1.0.0').toString(),
      forceUpdate: _toBool(json['force_update'] ?? json['forceUpdate'], false),
      updateUrl: (json['update_url'] ?? json['updateUrl'] ?? '').toString(),
      popupTitle: (json['popup_title'] ?? json['popupTitle'] ?? 'New Update Available!').toString(),
      popupMessage: (json['popup_message'] ?? json['popupMessage'] ?? 'A new version is available.').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'force_update': forceUpdate,
    'update_url': updateUrl,
    'popup_title': popupTitle,
    'popup_message': popupMessage,
  };
}

class AppConfig {
  final bool reviewMode;
  final bool streamingEnabled;
  final String streamingUrl;
  final bool adsEnabled;
  final bool bannerEnabled;
  final bool rewardedEnabled;
  final bool appOpenEnabled;
  final bool interstitialEnabled;

  final String bannerAdId;
  final String rewardedAdId;
  final String appOpenAdId;
  final String interstitialAdId;
  final String rewardedInterstitialAdId;
  final String nativeAdvancedAdId;

  final bool analyticsEnabled;
  final String googleAnalyticsId;

  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool appMessageEnabled;
  final String appMessage;
  final String appMessageType;

  final String whatsappLink;
  final String telegramLink;
  final String aboutUsLink;
  final String privacyPolicyLink;

  final bool popupEnabled;
  final String popupTitle;
  final String popupText;

  final int rewardedAdTime;

  final String footballApiUrl;
  final String cricketApiUrl;
  final String articlesApiUrl;
  final String altConfigUrl;

  final AppUpdateInfo? appUpdate;

  const AppConfig({
    required this.reviewMode,
    required this.streamingEnabled,
    required this.streamingUrl,
    required this.adsEnabled,
    required this.bannerEnabled,
    required this.rewardedEnabled,
    required this.appOpenEnabled,
    required this.interstitialEnabled,
    required this.bannerAdId,
    required this.rewardedAdId,
    required this.appOpenAdId,
    required this.interstitialAdId,
    required this.rewardedInterstitialAdId,
    required this.nativeAdvancedAdId,
    required this.analyticsEnabled,
    required this.googleAnalyticsId,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.appMessageEnabled,
    required this.appMessage,
    required this.appMessageType,
    required this.whatsappLink,
    required this.telegramLink,
    required this.aboutUsLink,
    required this.privacyPolicyLink,
    required this.popupEnabled,
    required this.popupTitle,
    required this.popupText,
    required this.rewardedAdTime,
    required this.footballApiUrl,
    required this.cricketApiUrl,
    required this.articlesApiUrl,
    required this.altConfigUrl,
    this.appUpdate,
  });

  factory AppConfig.empty() => AppConfig(
    reviewMode: false,
    streamingEnabled: true,
    streamingUrl: '',
    adsEnabled: true,
    bannerEnabled: true,
    rewardedEnabled: true,
    appOpenEnabled: true,
    interstitialEnabled: true,
    bannerAdId: '',
    rewardedAdId: '',
    appOpenAdId: '',
    interstitialAdId: '',
    rewardedInterstitialAdId: '',
    nativeAdvancedAdId: '',
    analyticsEnabled: false,
    googleAnalyticsId: '',
    maintenanceMode: false,
    maintenanceMessage: '',
    appMessageEnabled: false,
    appMessage: '',
    appMessageType: 'info',
    whatsappLink: '',
    telegramLink: '',
    aboutUsLink: dotenv.env['ABOUT_US_URL'] ?? 'https://yosintv.github.io/about-us.html',
    privacyPolicyLink: dotenv.env['PRIVACY_POLICY_URL'] ?? 'https://yosintv.github.io/privacy-policy.html',
    popupEnabled: false,
    popupTitle: '',
    popupText: '',
    rewardedAdTime: 1,
    footballApiUrl: '',
    cricketApiUrl: '',
    articlesApiUrl: '',
    altConfigUrl: '',
  );

  bool get shouldShowAds => adsEnabled;

  // True only when both flags allow it.
  // review_mode: true  → always false (store review safety)
  // streaming_enabled: false → false (time-based kill-switch)
  bool get shouldShowLinks => streamingEnabled && !reviewMode;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    AppUpdateInfo? update;
    try {
      final updateJson = json['app_update'] ?? json['appUpdate'];
      if (updateJson != null && updateJson is Map) {
        update = AppUpdateInfo.fromJson(updateJson);
      }
    } catch (e) {
      debugPrint("Error parsing AppUpdateInfo: $e");
    }

    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return AppConfig(
      reviewMode: _toBool(json['review_mode'] ?? json['reviewMode'], false),
      streamingEnabled: _toBool(json['streaming_enabled'] ?? json['streamingEnabled'], true),
      streamingUrl: (json['streaming_url'] ?? json['streamingUrl'] ?? '').toString(),
      adsEnabled: _toBool(json['ads_enabled'] ?? json['adsEnabled'], true),
      bannerEnabled: _toBool(json['banner_enabled'] ?? json['bannerEnabled'], true),
      rewardedEnabled: _toBool(json['rewarded_enabled'] ?? json['rewardedEnabled'], true),
      appOpenEnabled: _toBool(json['app_open_enabled'] ?? json['appOpenEnabled'], true),
      interstitialEnabled: _toBool(json['interstitial_enabled'] ?? json['interstitialEnabled'], true),
      
      bannerAdId: isIOS 
          ? (dotenv.env['IOS_BANNER_AD_ID'] ?? json['ios_banner_ad_id'] ?? json['iosBannerAdId'] ?? json['banner_ad_id'] ?? json['bannerAdId'] ?? '').toString()
          : (dotenv.env['BANNER_AD_ID'] ?? json['banner_ad_id'] ?? json['bannerAdId'] ?? '').toString(),
      rewardedAdId: isIOS 
          ? (dotenv.env['IOS_REWARDED_AD_ID'] ?? json['ios_rewarded_ad_id'] ?? json['iosRewardedAdId'] ?? json['rewarded_ad_id'] ?? json['rewardedAdId'] ?? '').toString()
          : (dotenv.env['REWARDED_AD_ID'] ?? json['rewarded_ad_id'] ?? json['rewardedAdId'] ?? '').toString(),
      appOpenAdId: isIOS 
          ? (dotenv.env['IOS_APP_OPEN_AD_ID'] ?? json['ios_app_open_ad_id'] ?? json['iosAppOpenAdId'] ?? json['app_open_ad_id'] ?? json['appOpenAdId'] ?? '').toString()
          : (dotenv.env['APP_OPEN_AD_ID'] ?? json['app_open_ad_id'] ?? json['appOpenAdId'] ?? '').toString(),
      interstitialAdId: isIOS 
          ? (dotenv.env['IOS_INTERSTITIAL_AD_ID'] ?? json['ios_interstitial_ad_id'] ?? json['iosInterstitialAdId'] ?? json['interstitial_ad_id'] ?? json['interstitialAdId'] ?? '').toString()
          : (dotenv.env['INTERSTITIAL_AD_ID'] ?? json['interstitial_ad_id'] ?? json['interstitialAdId'] ?? '').toString(),
      rewardedInterstitialAdId: isIOS 
          ? (dotenv.env['IOS_REWARDED_INTERSTITIAL_AD_ID'] ?? json['ios_rewarded_interstitial_ad_id'] ?? json['iosRewardedInterstitialAdId'] ?? json['rewarded_interstitial_ad_id'] ?? json['rewardedInterstitialAdId'] ?? '').toString()
          : (dotenv.env['REWARDED_INTERSTITIAL_AD_ID'] ?? json['rewarded_interstitial_ad_id'] ?? json['rewardedInterstitialAdId'] ?? '').toString(),
      nativeAdvancedAdId: isIOS 
          ? (dotenv.env['IOS_NATIVE_ADVANCED_AD_ID'] ?? json['ios_native_advanced_ad_id'] ?? json['iosNativeAdvancedAdId'] ?? json['native_advanced_ad_id'] ?? json['nativeAdvancedAdId'] ?? '').toString()
          : (dotenv.env['NATIVE_ADVANCED_AD_ID'] ?? json['native_advanced_ad_id'] ?? json['nativeAdvancedAdId'] ?? '').toString(),
      
      analyticsEnabled: _toBool(json['analytics_enabled'] ?? json['analyticsEnabled'], false),
      googleAnalyticsId: (json['google_analytics_id'] ?? json['googleAnalyticsId'] ?? '').toString(),

      maintenanceMode: _toBool(json['maintenance_mode'] ?? json['maintenanceMode'], false),
      maintenanceMessage: (json['maintenance_message'] ?? json['maintenanceMessage'] ?? '').toString(),
      appMessageEnabled: _toBool(json['app_message_enabled'] ?? json['appMessageEnabled'], false),
      appMessage: (json['app_message'] ?? json['appMessage'] ?? '').toString(),
      appMessageType: (json['app_message_type'] ?? json['appMessageType'] ?? 'info').toString(),
      
      whatsappLink: (json['whatsapp_link'] ?? json['whatsappLink'] ?? '').toString(),
      telegramLink: (json['telegram_link'] ?? json['telegramLink'] ?? '').toString(),
      aboutUsLink: (dotenv.env['ABOUT_US_URL'] ?? json['about_us_link'] ?? json['aboutUsLink'] ?? 'https://yosintv.github.io/about-us.html').toString(),
      privacyPolicyLink: (dotenv.env['PRIVACY_POLICY_URL'] ?? json['privacy_policy_link'] ?? json['privacyPolicyLink'] ?? 'https://yosintv.github.io/privacy-policy.html').toString(),

      popupEnabled: _toBool(json['popup_enabled'] ?? json['popupEnabled'], false),
      popupTitle: (json['popup_title'] ?? json['popupTitle'] ?? '').toString(),
      popupText: (json['popup_text'] ?? json['popupText'] ?? '').toString(),
      rewardedAdTime: (json['rewarded_ad_id_time'] ?? json['rewardedAdTime'] ?? 1) is int
          ? (json['rewarded_ad_id_time'] ?? json['rewardedAdTime'] ?? 1) as int
          : int.tryParse((json['rewarded_ad_id_time'] ?? json['rewardedAdTime'] ?? '1').toString()) ?? 1,

      footballApiUrl: (json['football_api_url'] ?? json['footballApiUrl'] ?? '').toString(),
      cricketApiUrl: (json['cricket_api_url'] ?? json['cricketApiUrl'] ?? '').toString(),
      articlesApiUrl: (json['articles_api_url'] ?? json['articlesApiUrl'] ?? '').toString(),
      altConfigUrl: (json['alt_config_url'] ?? json['altConfigUrl'] ?? '').toString(),
      
      appUpdate: update,
    );
  }

  Map<String, dynamic> toJson() => {
    'review_mode': reviewMode,
    'streaming_enabled': streamingEnabled,
    'streaming_url': streamingUrl,
    'ads_enabled': adsEnabled,
    'banner_enabled': bannerEnabled,
    'rewarded_enabled': rewardedEnabled,
    'app_open_enabled': appOpenEnabled,
    'interstitial_enabled': interstitialEnabled,
    'banner_ad_id': bannerAdId,
    'ios_banner_ad_id': bannerAdId,
    'rewarded_ad_id': rewardedAdId,
    'ios_rewarded_ad_id': rewardedAdId,
    'app_open_ad_id': appOpenAdId,
    'ios_app_open_ad_id': appOpenAdId,
    'interstitial_ad_id': interstitialAdId,
    'ios_interstitial_ad_id': interstitialAdId,
    'rewarded_interstitial_ad_id': rewardedInterstitialAdId,
    'ios_rewarded_interstitial_ad_id': rewardedInterstitialAdId,
    'native_advanced_ad_id': nativeAdvancedAdId,
    'ios_native_advanced_ad_id': nativeAdvancedAdId,
    'analytics_enabled': analyticsEnabled,
    'google_analytics_id': googleAnalyticsId,
    'maintenance_mode': maintenanceMode,
    'maintenance_message': maintenanceMessage,
    'app_message_enabled': appMessageEnabled,
    'app_message': appMessage,
    'app_message_type': appMessageType,
    'whatsapp_link': whatsappLink,
    'telegram_link': telegramLink,
    'about_us_link': aboutUsLink,
    'privacy_policy_link': privacyPolicyLink,
    'popup_enabled': popupEnabled,
    'popup_title': popupTitle,
    'popup_text': popupText,
    'rewarded_ad_id_time': rewardedAdTime,
    'football_api_url': footballApiUrl,
    'cricket_api_url': cricketApiUrl,
    'articles_api_url': articlesApiUrl,
    'alt_config_url': altConfigUrl,
    'app_update': appUpdate?.toJson(),
  };

  AppConfig merge(Map<String, dynamic> remote) {
    final Map<String, dynamic> current = toJson();
    remote.forEach((key, value) {
      if (value != null) {
        if ((key == 'app_update' || key == 'appUpdate') && value is Map) {
          final existing = current['app_update'] ?? {};
          current['app_update'] = {...(existing is Map ? existing : {}), ...value};
        } else {
          current[key] = value;
        }
      }
    });
    return AppConfig.fromJson(current);
  }
}
