import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int _morningReminderId = 1001;
  static const int _eveningReminderId = 1002;
  static const int _streakReminderId = 1003;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Show an instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'divine_path_channel',
      'Spiritual Reminders',
      channelDescription: 'Daily spiritual reminders and notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    try {
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      final tzScheduledDate = tz.TZDateTime.from(
        scheduledDate.isBefore(now) ? scheduledDate.add(const Duration(days: 1)) : scheduledDate,
        tz.local,
      );

      const androidDetails = AndroidNotificationDetails(
        'divine_path_channel',
        'Spiritual Reminders',
        channelDescription: 'Daily spiritual reminders and notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('Scheduled daily notification at $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Schedule morning reminder (6:00 AM)
  Future<void> scheduleMorningReminder() async {
    try {
      await scheduleDailyNotification(
        id: _morningReminderId,
        title: '☀️ Good Morning!',
        body: 'Time for your daily chanting. Start your day with divine energy!',
        hour: 6,
        minute: 0,
      );
    } catch (e) {
      debugPrint('Error scheduling morning reminder: $e');
    }
  }

  /// Schedule evening reminder (7:00 PM)
  Future<void> scheduleEveningReminder() async {
    try {
      await scheduleDailyNotification(
        id: _eveningReminderId,
        title: '🌅 Evening Reminder',
        body: 'Continue your spiritual journey today. A few minutes of meditation awaits.',
        hour: 19,
        minute: 0,
      );
    } catch (e) {
      debugPrint('Error scheduling evening reminder: $e');
    }
  }

  /// Schedule streak reminder (if user hasn't chanted)
  Future<void> scheduleStreakReminder() async {
    await scheduleDailyNotification(
      id: _streakReminderId,
      title: '🔥 Don\'t Break Your Streak!',
      body: 'You haven\'t completed your spiritual practice today. Take a few minutes now.',
      hour: 20,
      minute: 0,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    try {
      if (enabled) {
        await scheduleMorningReminder();
        await scheduleEveningReminder();
      } else {
        await cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
    }
  }

  /// Get notification status
  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Check if device supports notifications
  Future<bool> areNotificationsSupported() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }
}
