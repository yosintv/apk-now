// lib/config/defaults.dart
// Local fallback configuration used when both remote endpoints are unreachable.
// This is the last-resort safety net, always kept in sync with the production JSON shape.

const Map<String, dynamic> kDefaultConfig = {
  // --- Ad Control Flags ---
  'reviewMode': false,
  'streamingEnabled': true,
  'adsEnabled': true,
  'bannerEnabled': true,
  'rewardedEnabled': true,
  'appOpenEnabled': true,
  'interstitialEnabled': true,

  // --- AdMob Ad Unit IDs (Production IDs) ---
  'bannerAdId': 'ca-app-pub-5525538810839147/3825132304',
  'rewardedAdId': 'ca-app-pub-5525538810839147/6942250234',
  'appOpenAdId': 'ca-app-pub-5525538810839147/1223019695',
  'interstitialAdId': 'ca-app-pub-5525538810839147/4446428920',

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
