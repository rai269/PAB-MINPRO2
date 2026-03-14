import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'todo_reminders',
    'Pengingat Tugas',
    channelDescription: 'Notifikasi pengingat deadline tugas',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  // Schedule H-3, H-2, H-1 reminders for a task
  static Future<void> scheduleTaskReminders(Task task) async {
    if (task.completed || task.archived) return;

    final deadline = DateTime(
      task.deadline.year,
      task.deadline.month,
      task.deadline.day,
      9,
      0,
    );

    final reminders = [
      (days: 3, suffix: '3 hari lagi'),
      (days: 2, suffix: '2 hari lagi'),
      (days: 1, suffix: 'besok'),
    ];

    for (final r in reminders) {
      final notifTime = deadline.subtract(Duration(days: r.days));
      final now = DateTime.now();

      if (notifTime.isAfter(now)) {
        final id = _notifId(task.id, r.days);
        await _plugin.zonedSchedule(
          id,
          '⏰ Deadline ${r.suffix}!',
          '"${task.title}" jatuh tempo pada ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
          tz.TZDateTime.from(notifTime, tz.local),
          _notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> cancelTaskReminders(String taskId) async {
    for (final days in [1, 2, 3]) {
      await _plugin.cancel(_notifId(taskId, days));
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Reschedule all active tasks (call after login or task changes)
  static Future<void> rescheduleAll(List<Task> tasks) async {
    await _plugin.cancelAll();
    for (final task in tasks) {
      await scheduleTaskReminders(task);
    }
  }

  // Stable int ID from task UUID + day offset
  static int _notifId(String taskId, int dayOffset) {
    final hash = taskId.hashCode.abs();
    return (hash % 100000) * 10 + dayOffset;
  }
}
