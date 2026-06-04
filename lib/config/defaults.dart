// lib/config/defaults.dart
// Local fallback configuration used when both remote endpoints are unreachable.
// This is the last-resort safety net, always kept in sync with the production JSON shape.
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> get kDefaultConfig => {
  // --- Ad Control Flags ---
  'reviewMode': false,
  'streamingEnabled': true,
  'adsEnabled': true,
  'bannerEnabled': true,
  'rewardedEnabled': true,
  'appOpenEnabled': true,
  'interstitialEnabled': true,

  // --- AdMob Ad Unit IDs (Android) ---
  'bannerAdId': dotenv.env['ADMOB_ANDROID_BANNER_ID'] ?? '',
  'rewardedAdId': dotenv.env['ADMOB_ANDROID_REWARDED_ID'] ?? '',
  'appOpenAdId': dotenv.env['ADMOB_ANDROID_APP_OPEN_ID'] ?? '',
  'interstitialAdId': dotenv.env['ADMOB_ANDROID_INTERSTITIAL_ID'] ?? '',

  // --- AdMob Ad Unit IDs (iOS) ---
  'iosBannerAdId': dotenv.env['ADMOB_IOS_BANNER_ID'] ?? '',
  'iosInterstitialAdId': dotenv.env['ADMOB_IOS_INTERSTITIAL_ID'] ?? '',
  'iosRewardedAdId': dotenv.env['ADMOB_IOS_REWARDED_ID'] ?? '',
  'iosAppOpenAdId': dotenv.env['ADMOB_IOS_APP_OPEN_ID'] ?? '',
  'iosRewardedInterstitialAdId': dotenv.env['ADMOB_IOS_REWARDED_INTERSTITIAL_ID'] ?? '',
  'iosNativeAdvancedAdId': dotenv.env['ADMOB_IOS_NATIVE_ADVANCED_ID'] ?? '',

  // --- Maintenance & Messaging ---
  'maintenanceMode': false,
  'maintenanceMessage': 'App is under maintenance. Please try again later.',
  'appMessage': 'Welcome to YoSinTV v1.1.0!',
  'appMessageType': 'info',

  // --- Social Links ---
  'whatsappLink': 'https://wa.me/1234567890',
  'telegramLink': 'https://t.me/yosintv',

  // --- Popup ---
  'popupEnabled': false,
  'popupTitle': 'Welcome to YoSinTV',
  'popupText': 'Your daily sports companion!',

  // --- API Endpoints ---
  'footballApiUrl': 'https://api.singhs.com.np/api/match-football.json',
  'cricketApiUrl': 'https://api.singhs.com.np/api/match-cricket.json',
  'articlesApiUrl': 'https://api.singhs.com.np/api/articles.json',
  'altConfigUrl': 'https://api.singhs.com.np/api/alt-config.json',
};

/// Primary and fallback remote configuration URLs.
const String kMainConfigUrl =
    'https://api.singhs.com.np/api/main-config.json';
const String kAltConfigUrl =
    'https://api.singhs.com.np/api/alt-config.json';
