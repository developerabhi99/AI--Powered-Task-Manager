import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Callback to be set by the ViewModel/App to handle notification action clicks
  static void Function(String taskId, String actionId)? onNotificationAction;

  // ── Channels ──────────────────────────────────────────────────────────────
  static const String channelId = 'task_deadlines';
  static const String channelName = 'Task Deadline Reminders';
  static const String channelDesc = 'Notifications when tasks reach their due time';

  static const String briefingChannelId = 'daily_briefing';
  static const String briefingChannelName = 'Daily Morning Briefing';
  static const String briefingChannelDesc = 'Your daily task summary at 8:00 AM';

  static const String overdueChannelId = 'overdue_reminders';
  static const String overdueChannelName = 'Overdue Task Reminders';
  static const String overdueChannelDesc = 'Reminders for tasks past their due time';

  // Fixed notification ID for the daily morning briefing
  static const int _morningBriefingId = 999000;

  // ── Initialisation ────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final List<DarwinNotificationCategory> darwinNotificationCategories = [
      DarwinNotificationCategory(
        'task_category',
        actions: [
          DarwinNotificationAction.plain('action_complete', 'Mark Completed'),
          DarwinNotificationAction.plain('action_add_15m', 'Add 15 Mins'),
        ],
        options: {DarwinNotificationCategoryOption.customDismissAction},
      )
    ];

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );

    await _notificationsPlugin.initialize(
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        final String? actionId = response.actionId;
        if (payload != null && onNotificationAction != null) {
          onNotificationAction!(payload, actionId ?? 'tap');
        }
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Explicitly request POST_NOTIFICATIONS for Android 13+
    await Permission.notification.request();
  }

  // ── Task Due Notification ─────────────────────────────────────────────────
  /// Schedules a notification at the task's due time + a 30-min overdue reminder.
  static Future<void> scheduleTaskNotification(TaskModel task) async {
    if (kIsWeb) return;

    await cancelTaskNotification(task.id);

    if (task.isCompleted || task.dueDate.isBefore(DateTime.now())) return;

    final List<AndroidNotificationAction> androidActions = [
      const AndroidNotificationAction('action_complete', 'Mark Completed',
          showsUserInterface: true, cancelNotification: true),
      const AndroidNotificationAction('action_add_15m', 'Add 15 Mins',
          showsUserInterface: true, cancelNotification: true),
    ];

    String body;
    if (task.subtasks.isNotEmpty) {
      final active = task.subtasks.where((s) => !s.isCompleted).length;
      body = 'You have $active unfinished subtasks. Update your progress or complete the task!';
    } else {
      body = task.description.isNotEmpty
          ? task.description
          : 'Time is up! Mark this task complete or add more time.';
    }

    await _notificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Task Due: ${task.title}',
      body,
      tz.TZDateTime.from(task.dueDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            actions: androidActions),
        iOS: const DarwinNotificationDetails(categoryIdentifier: 'task_category'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    // Also schedule overdue reminder 30 min later
    await _scheduleOverdueReminder(task);

    // Also schedule reminder before it starts
    if (task.reminderMinutes >= 0) {
      await _scheduleReminder(task);
    }
  }

  // ── Reminder Before Start ─────────────────────────────────────────────────
  /// Fires X minutes before the task's start time.
  static Future<void> _scheduleReminder(TaskModel task) async {
    if (kIsWeb) return;

    // Calculate start time: dueDate - duration
    final startTime = task.dueDate.subtract(Duration(minutes: task.duration));
    // Calculate reminder time: startTime - reminderMinutes
    final reminderTime = startTime.subtract(Duration(minutes: task.reminderMinutes));

    if (reminderTime.isBefore(DateTime.now())) return;

    final int reminderId = task.id.hashCode + 200000;

    String body = task.reminderMinutes == 0
        ? 'Starts now!'
        : 'Starts in ${task.reminderMinutes} minutes!';
    if (task.duration > 0) {
      body += ' Duration: ${task.duration} mins.';
    }

    await _notificationsPlugin.zonedSchedule(
      reminderId,
      '🔔 Reminder: ${task.title}',
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  // ── Overdue Reminder ──────────────────────────────────────────────────────
  /// Fires 30 minutes after the task's due time if the user hasn't completed it.
  static Future<void> _scheduleOverdueReminder(TaskModel task) async {
    if (kIsWeb) return;

    final overdueTime = task.dueDate.add(const Duration(minutes: 30));
    if (overdueTime.isBefore(DateTime.now())) return;

    final int overdueId = task.id.hashCode + 500000;

    final List<AndroidNotificationAction> androidActions = [
      const AndroidNotificationAction('action_complete', 'Mark Completed',
          showsUserInterface: true, cancelNotification: true),
      const AndroidNotificationAction('action_add_15m', 'Add 15 Mins',
          showsUserInterface: true, cancelNotification: true),
    ];

    await _notificationsPlugin.zonedSchedule(
      overdueId,
      '⚠️ Overdue: ${task.title}',
      'This task is 30 minutes overdue! Mark it complete or extend the time.',
      tz.TZDateTime.from(overdueTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(overdueChannelId, overdueChannelName,
            channelDescription: overdueChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF6B6B),
            actions: androidActions),
        iOS: const DarwinNotificationDetails(categoryIdentifier: 'task_category'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  // ── Daily Morning Briefing ────────────────────────────────────────────────
  /// Schedules (or reschedules) a daily 8:00 AM summary of today's tasks.
  static Future<void> scheduleMorningBriefing(List<TaskModel> todayTasks) async {
    if (kIsWeb) return;

    await _notificationsPlugin.cancel(_morningBriefingId);

    final active = todayTasks.where((t) => !t.isCompleted).toList();
    if (active.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final count = active.length;
    final taskWord = count == 1 ? 'task' : 'tasks';
    final first = active.first.title;
    final body = count == 1
        ? 'You have 1 task today: "$first"'
        : 'You have $count $taskWord due today. First up: "$first"';

    await _notificationsPlugin.zonedSchedule(
      _morningBriefingId,
      'Good morning! 📋 Your Daily Briefing',
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          briefingChannelId,
          briefingChannelName,
          channelDescription: briefingChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'morning_briefing',
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  /// Cancels a task's due notification, overdue reminder, and start reminder.
  static Future<void> cancelTaskNotification(String taskId) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(taskId.hashCode);
    await _notificationsPlugin.cancel(taskId.hashCode + 500000);
    await _notificationsPlugin.cancel(taskId.hashCode + 200000);
  }

  // ── Daily Workout Reminder ────────────────────────────────────────────────
  static const int _workoutReminderId = 888000;
  static const String workoutChannelId = 'workout_reminders';
  static const String workoutChannelName = 'Workout Reminders';
  static const String workoutChannelDesc = 'Daily reminder to do your workout';

  static Future<void> scheduleDailyWorkoutReminder({int hour = 8, int minute = 0}) async {
    if (kIsWeb) return;

    await _notificationsPlugin.cancel(_workoutReminderId);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      _workoutReminderId,
      '💪 Time to Work Out!',
      'Don\'t forget to close your rings and log your daily workout!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          workoutChannelId,
          workoutChannelName,
          channelDescription: workoutChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF4CAF50),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      payload: 'workout_reminder',
    );
  }
}
