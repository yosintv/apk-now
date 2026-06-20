// lib/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/config_provider.dart';
import 'providers/analytics_provider.dart';
import 'models/app_config.dart';
import 'models/match.dart';
import 'models/article.dart';
import 'screens/main_shell.dart';
import 'screens/home/home_screen.dart';
import 'screens/football_screen.dart';
import 'screens/cricket_screen.dart';
import 'screens/news_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/match_detail/match_detail_screen.dart';
import 'screens/news/article_detail_screen.dart';

// Global key to allow showing dialogs from anywhere (like update checks)
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late AppConfig _config;

  RouterNotifier(this._ref) {
    _ref.listen<AppConfig>(configProvider, (previous, next) {
      _config = next;
      notifyListeners();
    });
    _config = _ref.read(configProvider);
  }

  AppConfig get config => _config;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final analyticsObserver = ref.watch(analyticsObserverProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    observers: [
      if (analyticsObserver != null) analyticsObserver,
    ],
    redirect: (context, state) {
      final inMaintenance = state.matchedLocation == '/maintenance';
      final maintenanceActive = notifier.config.maintenanceMode;

      if (maintenanceActive && !inMaintenance) {
        return '/maintenance';
      }
      if (!maintenanceActive && inMaintenance) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/match-detail',
        pageBuilder: (context, state) {
          final match = state.extra as Match;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MatchDetailScreen(match: match),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/article-detail',
        pageBuilder: (context, state) {
          final article = state.extra as Article;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ArticleDetailScreen(article: article),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/football',
                builder: (context, state) => const FootballScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cricket',
                builder: (context, state) => const CricketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const NewsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
