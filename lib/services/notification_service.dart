import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool androidGranted = true;
    bool iosGranted = true;

    if (android != null) {
      androidGranted =
          await android.requestNotificationsPermission() ?? true;
    }

    if (ios != null) {
      iosGranted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
          true;
    }

    return androidGranted && iosGranted;
  }

  static tz.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Günlük Görev Hatırlatmaları',
      channelDescription: 'Yazım Kuralları günlük görev bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      1001,
      'Günlük görevlerini unutma 🚀',
      'Bugün birkaç soru çözerek serini koruyabilirsin.',
      _nextInstanceOfTime(hour: hour, minute: minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Bildirimi',
      channelDescription: 'Bildirim test kanalı',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      999,
      'Bildirimler aktif 🎉',
      'Her gün 20:00’de görev hatırlatması alacaksın.',
      details,
    );
  }

  static Future<void> showCompletedNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'completed_channel',
      'Görev Tamamlandı',
      channelDescription: 'Görev tamamlandı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      2002,
      'Görevler Tamamlandı 🎉',
      'Bugünkü tüm görevleri tamamladın!',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}