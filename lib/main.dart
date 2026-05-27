import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'services/ad_service.dart';
import 'widgets/loading_screen.dart';

void main() async {
  // Ensure the binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: YoSinTVApp(),
    ),
  );
}

class YoSinTVApp extends ConsumerStatefulWidget {
  const YoSinTVApp({super.key});

  @override
  ConsumerState<YoSinTVApp> createState() => _YoSinTVAppState();
}

class _YoSinTVAppState extends ConsumerState<YoSinTVApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
    _setupConnectivity();
  }

  Future<void> _initApp() async {
    // 1. Initialize AdMob in parallel
    unawaited(_initAdMob());

    // 2. Reduced delay to 1.5s for a faster, professional handoff 
    // from the native launch icon to the app UI.
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initAdMob() async {
    try {
      final requestConfig = RequestConfiguration(
        testDeviceIds: ["9BF33D942FE0E9E6393482062A26F769"],
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfig);
      await MobileAds.instance.initialize();
      ref.read(adSdkInitializedProvider.notifier).state = true;
    } catch (e) {
      debugPrint("AdMob Init Failed: $e");
    }
  }

  void _setupConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        _showNoInternetDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('No Internet', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Please check your connection and try again to access live match data.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: TextButton(
              onPressed: () async {
                final result = await Connectivity().checkConnectivity();
                if (!result.contains(ConnectivityResult.none)) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                }
              },
              child: const Text('RETRY', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(adServiceProvider).showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const LoadingScreen(),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'YoSinTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.accent,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          bodyLarge: const TextStyle(color: AppColors.textPrimary),
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      routerConfig: router,
    );
  }
}
