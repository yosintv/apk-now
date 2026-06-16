import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'services/ad_service.dart';
import 'widgets/loading_screen.dart';
import 'providers/config_provider.dart';
import 'providers/connectivity_provider.dart';
import 'models/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    // Initializing Firebase without explicit options to use google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase/Dotenv Init Failed: $e");
  }

  runApp(const ProviderScope(child: YoSinTVApp()));
}

class YoSinTVApp extends ConsumerStatefulWidget {
  const YoSinTVApp({super.key});
  @override
  ConsumerState<YoSinTVApp> createState() => _YoSinTVAppState();
}

class _YoSinTVAppState extends ConsumerState<YoSinTVApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _popupsHandled = false;
  bool _isNoInternetDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  Future<void> _initApp() async {
    unawaited(_initAdMob());
    
    bool hasConnection = false;
    while (!hasConnection) {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        _showNoInternetDialog();
        await Future.delayed(const Duration(seconds: 2));
      } else {
        hasConnection = true;
      }
    }

    // Ensure config is fully fetched before proceeding
    await ref.read(configProvider.notifier).fetchConfig();
    
    final config = ref.read(configProvider);
    await _initAnalytics(config);
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPopups(ref.read(configProvider));
      });
    }
  }

  Future<void> _initAnalytics(AppConfig config) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(config.analyticsEnabled);
      if (config.analyticsEnabled) await analytics.logAppOpen();
    } catch (e) {
      debugPrint("Analytics Init Failed: $e");
    }
  }

  Future<void> _initAdMob() async {
    try {
      await MobileAds.instance.initialize();
      
      final testDeviceId = dotenv.env['ADMOB_TEST_DEVICE_ID'];
      if (testDeviceId != null && testDeviceId.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: [testDeviceId]),
        );
      }
      
      ref.read(adSdkInitializedProvider.notifier).state = true;
    } catch (e) {
      debugPrint("AdMob Init Failed: $e");
    }
  }

  void _showNoInternetDialog() {
    if (_isNoInternetDialogShowing) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 300), _showNoInternetDialog);
      return;
    }

    _isNoInternetDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.primary), 
              SizedBox(width: 12), 
              Text('No Internet', style: TextStyle(fontWeight: FontWeight.bold))
            ]
          ),
          content: const Text('Internet connection is required to fetch the latest matches.'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final results = await Connectivity().checkConnectivity();
                if (!results.contains(ConnectivityResult.none)) {
                  _isNoInternetDialogShowing = false;
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('RETRY', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _checkPopups(AppConfig config) async {
    // 1. Guard Clauses: Ensure config has update info and popups haven't been handled
    if (config.appUpdate == null) {
      debugPrint("Update Check: No appUpdate found in config. Ensure server response is correct.");
      return;
    }
    
    if (_popupsHandled) return;

    // Ensure UI is ready (safety delay)
    await Future.delayed(const Duration(seconds: 1));
    
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () => _checkPopups(config));
      }
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final updateInfo = config.appUpdate!;
      
      // Compare latest_version (from config) against package_info version
      String current = packageInfo.version.split('+').first;
      if (current.isEmpty) current = "1.1.0";

      String latest = updateInfo.latestVersion.split('+').first;
      if (latest.isEmpty) latest = "2.0.0";

      debugPrint("Update Check: Current version $current, Latest version $latest");

      if (_isVersionGreater(latest, current)) {
        _popupsHandled = true;
        if (mounted) _showUpdateDialog(updateInfo);
        return;
      }
    } catch (e) {
      debugPrint("Version parsing error: $e");
    }

    _popupsHandled = true;
  }

  bool _isVersionGreater(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      int length = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
      for (int i = 0; i < length; i++) {
        int l = i < latestParts.length ? latestParts[i] : 0;
        int c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) { return false; }
    return false;
  }

  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return PopScope(
          canPop: !updateInfo.forceUpdate, 
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(updateInfo.popupTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
              content: Text(updateInfo.popupMessage),
              actions: [
                if (!updateInfo.forceUpdate)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('NOT NOW'),
                  ),
                ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse(updateInfo.updateUrl), mode: LaunchMode.externalApplication),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('UPDATE NOW', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(adServiceProvider).showAppOpenAdIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      next.whenData((results) {
        if (results.contains(ConnectivityResult.none)) _showNoInternetDialog();
      });
    });

    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const LoadingScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'YoSinTV',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary, 
          secondary: AppColors.accent, 
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),
      routerConfig: router,
    );
  }
}
