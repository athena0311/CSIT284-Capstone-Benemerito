import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_item.dart';

/// Schedules a weekly repeating notification before each class (default 10 min).
///
/// Written for flutter_local_notifications 21+ (named parameters).
/// Scheduled reminders only work on Android / iOS, so every method is a
/// no-op when running in Chrome.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation('Asia/Manila'),
    ); // change for your region

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Returns true if notifications are allowed.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final androidOk = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final iosOk = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return androidOk ?? iosOk ?? true;
  }

  Future<void> scheduleWeekly(List<ScheduleItem> items) async {
    if (kIsWeb) return;

    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'class_reminders',
        'Class reminders',
        channelDescription: 'Reminds you 10 minutes before a class starts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (final item in items) {
      await _plugin.zonedSchedule(
        id: item.notificationId,
        title: '${item.subject} starts in ${item.reminderMinutesBefore} min',
        body: '${item.timeRange} · ${item.room}',
        scheduledDate: _nextOccurrence(item),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Next date this class's reminder should fire (start time minus 10 min).
  tz.TZDateTime _nextOccurrence(ScheduleItem item) {
    final now = tz.TZDateTime.now(tz.local);
    final fireMinutes = item.startMinutes - item.reminderMinutesBefore;
    var t = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: fireMinutes));
    while (t.weekday != item.dayOfWeek || t.isBefore(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }
}
