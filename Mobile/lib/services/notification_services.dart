import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> init() async {
    // 1. Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    // 2. Android Configuration
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await notificationPlugin.initialize(settings: initSettings);
    // 3. Request permission and create a channel
    final androidPlatform = notificationPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.requestNotificationsPermission();
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminder Notifications',
      description: 'Channel for notification reminders',
      importance: Importance.high,
    );
    await androidPlatform?.createNotificationChannel(channel);
  }

  // Immediate notification: appears immediately when called
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );
    await notificationPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notifDetails,
    );
  }

  // Scheduled notification: appears at a specified time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );
    await notificationPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // Create a TZDateTime directly from the time componentso there is no
      // timezone conversion error
      scheduledDate: tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      ),
      notificationDetails: notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
