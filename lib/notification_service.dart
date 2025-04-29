import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
  id,
  title,
  body,
  tz.TZDateTime.from(scheduledTime, tz.local),
  const NotificationDetails(
    android: AndroidNotificationDetails(
      'your_channel_id',
      'Task Reminders',
      channelDescription: 'Task due reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    ),
  ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
  matchDateTimeComponents: DateTimeComponents.time, 
);

  }
}
