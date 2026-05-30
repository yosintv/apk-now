import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider = Provider<FirebaseAnalytics?>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAnalytics.instance;
    }
  } catch (_) {}
  return null;
});

final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver?>((ref) {
  final analytics = ref.watch(analyticsProvider);
  if (analytics != null) {
    return FirebaseAnalyticsObserver(analytics: analytics);
  }
  return null;
});
