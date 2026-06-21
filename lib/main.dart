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
import 'services/notification_service.dart';
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

  // Init notifications concurrently — completes before matches are fetched
  unawaited(NotificationService.init());

  runApp(const ProviderScope(child: YoSinTVApp()));
}

class YoSinTVApp extends ConsumerStatefulWidget {
  const YoSinTVApp({super.key});
  @override
  ConsumerState<YoSinTVApp> createState() => _YoSinTVAppState();
}

class _YoSinTVAppState extends ConsumerState<YoSinTVApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _splashVisible = true; // stays true until fade-out finishes
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

    // Load asset config + enforce minimum splash time in parallel.
    // Both run concurrently — total wait = max(asset load ~50ms, 1200ms) = 1200ms.
    await Future.wait([
      ref.read(configProvider.notifier).loadAsset(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (mounted) setState(() => _isLoading = false);

    // Fetch remote config + run analytics + check popups in background
    unawaited(ref.read(configProvider.notifier).fetchConfig().then((_) {
      if (!mounted) return;
      unawaited(_initAnalytics(ref.read(configProvider)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPopups(ref.read(configProvider));
      });
    }));
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
      // Gather EU/UK consent via Google UMP before initialising AdMob.
      // Non-EEA/UK users pass through instantly; EEA/UK users see the
      // consent form on first launch and on every consent-reset.
      await _gatherConsent();

      await MobileAds.instance.initialize();

      final testDeviceId = dotenv.env['ADMOB_TEST_DEVICE_ID'];
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: (testDeviceId != null && testDeviceId.isNotEmpty)
              ? [testDeviceId]
              : null,
          maxAdContentRating: MaxAdContentRating.ma,
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        ),
      );

      ref.read(adSdkInitializedProvider.notifier).state = true;
    } catch (e) {
      debugPrint("AdMob Init Failed: $e");
    }
  }

  /// Requests consent info update via Google UMP SDK and, if required,
  /// loads and shows the GDPR/IDFA consent form to the user.
  /// Always completes — errors are non-fatal (ads fall back to
  /// non-personalised serving).
  Future<void> _gatherConsent() async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // Success: check if form needs to be shown
        try {
          final available =
              await ConsentInformation.instance.isConsentFormAvailable();
          if (available) {
            ConsentForm.loadAndShowConsentFormIfRequired((_) {
              // Form dismissed (error arg is null on success)
              if (!completer.isCompleted) completer.complete();
            });
          } else {
            completer.complete();
          }
        } catch (e) {
          debugPrint('Consent form check error: $e');
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        // Network/API error — continue without consent; AdMob serves
        // non-personalised ads for EEA users in this case.
        debugPrint('Consent info update error: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Safety timeout so a network failure never blocks app startup.
    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
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
    if (_popupsHandled) return;
    _popupsHandled = true;

    // Safety delay — ensures navigation stack is ready
    await Future.delayed(const Duration(milliseconds: 600));

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    // 1. App update check (highest priority)
    if (config.appUpdate != null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final updateInfo = config.appUpdate!;
        String current = packageInfo.version.split('+').first;
        if (current.isEmpty) current = "1.0.0";
        String latest = updateInfo.latestVersion.split('+').first;
        if (latest.isEmpty) latest = "1.0.0";
        debugPrint("Update Check: Current $current, Latest $latest");
        if (_isVersionGreater(latest, current)) {
          if (mounted) _showUpdateDialog(updateInfo);
          return;
        }
      } catch (e) {
        debugPrint("Version parsing error: $e");
      }
    }

    // 2. Welcome / announcement popup
    if (config.popupEnabled && config.popupTitle.isNotEmpty) {
      if (mounted) _showWelcomePopup(config);
    }
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
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

  void _showWelcomePopup(AppConfig config) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Welcome',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (dialogCtx, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 48,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Gradient header ──────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF002147), Color(0xFF1652A8)],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Sport icons + logo cluster
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('⚽', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryLight.withValues(alpha: 0.55),
                                        blurRadius: 24,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.live_tv_rounded,
                                      color: AppColors.primary,
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🏏', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              config.popupTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Body ─────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                        child: Column(
                          children: [
                            Text(
                              config.popupText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // WhatsApp button
                            if (config.whatsappLink.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    launchUrl(
                                      Uri.parse(config.whatsappLink),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.whatsapp,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_rounded, color: Colors.white, size: 19),
                                      SizedBox(width: 9),
                                      Text(
                                        'Join WhatsApp Group',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (config.whatsappLink.isNotEmpty &&
                                config.telegramLink.isNotEmpty)
                              const SizedBox(height: 10),

                            // Telegram button
                            if (config.telegramLink.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    launchUrl(
                                      Uri.parse(config.telegramLink),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.telegram,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, color: Colors.white, size: 19),
                                      SizedBox(width: 9),
                                      Text(
                                        'Join Telegram Channel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 18),

                            // Dismiss
                            GestureDetector(
                              onTap: () => Navigator.pop(dialogCtx),
                              child: const Text(
                                'Maybe later',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              );
            }
            return const TextStyle(
              color: AppColors.inactiveTab,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 22);
            }
            return const IconThemeData(color: AppColors.inactiveTab, size: 22);
          }),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: AppColors.border),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerColor: AppColors.divider,
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
      ),
      routerConfig: router,
      // Splash overlay on top — avoids MaterialApp type-switch that caused
      // the brief null-context red screen during loading → main transition.
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (_splashVisible)
              AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                onEnd: () {
                  if (!_isLoading && mounted) {
                    setState(() => _splashVisible = false);
                  }
                },
                child: const LoadingScreen(),
              ),
          ],
        );
      },
    );
  }
}
