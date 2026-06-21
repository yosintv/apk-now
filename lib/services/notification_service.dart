import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/match.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'match_alerts';
  static const _channelName = 'Match Alerts';
  static const _channelDesc = 'Pre-match notifications 15 minutes before kick-off';

  // Separate ID ranges so football and cricket never cancel each other
  static const _footballOffset = 0;
  static const _cricketOffset = 500;
  static const _rangeSize = 500;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Explicitly create the high-importance channel (required on Android 8.0+)
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Request Android 13+ runtime notification permission
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService: initialized');
  }

  /// Schedule 15-minute pre-match notifications for [matches].
  /// Uses UTC scheduling — fires at the correct absolute moment on all devices.
  static Future<void> scheduleMatchNotifications(
    List<Match> matches, {
    required String sport,
  }) async {
    if (!_initialized) return;

    final idOffset = sport == 'football' ? _footballOffset : _cricketOffset;

    // Cancel existing notifications in this sport's ID range
    for (int i = idOffset; i < idOffset + _rangeSize; i++) {
      await _plugin.cancel(i);
    }

    final now = DateTime.now();
    final emoji = sport == 'cricket' ? '🏏' : '⚽';
    int count = 0;

    for (final match in matches) {
      if (match.status != MatchStatus.upcoming) continue;
      if (match.time == null || match.time!.isEmpty) continue;
      if (count >= _rangeSize) break;

      try {
        final matchTime = DateTime.parse(match.time!).toLocal();
        final notifyAt = matchTime.subtract(const Duration(minutes: 15));
        if (notifyAt.isBefore(now)) continue;

        // Schedule at the absolute UTC moment — correct on every timezone
        final utc = notifyAt.toUtc();
        final scheduledDate = tz.TZDateTime.utc(
          utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second,
        );

        await _plugin.zonedSchedule(
          idOffset + count,
          '$emoji Match Starting Soon!',
          '${match.teamA} vs ${match.teamB} — kicks off in 15 minutes',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableLights: true,
              enableVibration: true,
              playSound: true,
              channelShowBadge: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        count++;
        debugPrint('NotificationService: [$sport] ${match.teamA} vs ${match.teamB} → $notifyAt');
      } catch (e) {
        debugPrint('NotificationService: schedule error — $e');
      }
    }

    debugPrint('NotificationService: $count $sport alerts scheduled');
  }
}
