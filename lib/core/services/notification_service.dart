import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../features/tasks/models/task.dart' as task_model;
import 'package:flutter_local_notifications/src/platform_specifics/android/enums.dart' as android_enums;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/src/platform_specifics/ios/enums.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _initializationInProgress = false;
  tz.Location? _local;

  // Date formatters for notifications
  final DateFormat _timeFormatter = DateFormat('h:mm a');
  final DateFormat _dateFormatter = DateFormat('MMM d, y');
  final DateFormat _fullFormatter = DateFormat('MMM d, y • h:mm a');

  bool get isInitialized => _initialized && _local != null;

  tz.TZDateTime _convertToTZ(DateTime dateTime) {
    if (_local == null) {
      throw Exception('Timezone not initialized. Please ensure initialize() is called first.');
    }
    
    // Create TZDateTime while preserving the local time components
    final tz.TZDateTime result = tz.TZDateTime(
      _local!,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    // If the result is in the past, add a small buffer to ensure it's in the future
    final tz.TZDateTime now = tz.TZDateTime.now(_local!);
    if (result.isBefore(now)) {
      print('Warning: Converted time was in the past, adding buffer');
      return now.add(const Duration(seconds: 5));
    }

    return result;
  }

  Future<void> initialize() async {
    if (_initialized && _local != null) {
      print('Notifications already initialized');
      return;
    }

    if (_initializationInProgress) {
      print('Initialization already in progress');
      return;
    }

    _initializationInProgress = true;

    try {
      // Initialize timezone data
      print('Initializing timezones...');
      tz.initializeTimeZones();
      _local = tz.local;
      print('Timezone initialized: ${_local?.name}');

      if (_local == null) {
        throw Exception('Failed to initialize timezone');
      }

      // Configure notification channels for Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configure notification settings for iOS
      final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          print('Received iOS notification: id=$id, title=$title, body=$body, payload=$payload');
        },
        notificationCategories: [
          DarwinNotificationCategory(
            'taskDue',
            actions: [
              DarwinNotificationAction.plain(
                'MARK_COMPLETE',
                'Mark as Complete',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain(
                'SNOOZE',
                'Snooze',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
            options: {
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          )
        ],
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
          _handleNotificationTap(response);
        },
      );
      print('Notifications initialized: $initialized');

      // Request iOS permissions
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        print('Requesting iOS permissions...');
        final bool? permissionGranted = await _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
        print('iOS permissions granted: $permissionGranted');
      }

      _initialized = true;
      _initializationInProgress = false;
      
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        print('Note: Notifications are not supported in iOS simulator');
      } else {
        // Send test notification after a short delay to ensure permissions are processed
        await Future.delayed(const Duration(seconds: 2));
        await showTestNotification();
      }
    } catch (e, stackTrace) {
      print('Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
      _initialized = false;
      _initializationInProgress = false;
      rethrow;
    }
  }

  Future<void> ensureInitialized() async {
    if (!isInitialized) {
      print('NotificationService not initialized, initializing now...');
      await initialize();
      
      if (!isInitialized) {
        throw Exception('Failed to initialize NotificationService');
      }
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification payload: ${response.payload}');
      // Handle different notification actions
      switch (response.actionId) {
        case 'MARK_COMPLETE':
          print('User tapped Mark as Complete');
          break;
        case 'SNOOZE':
          print('User tapped Snooze');
          break;
        default:
          print('Notification tapped without specific action');
      }
    }
  }

  Future<void> showTestNotification() async {
    try {
      print('Attempting to show test notification...');
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'taskDue',
        threadIdentifier: 'task_notifications',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: Importance.max,
        priority: android_enums.Priority.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications.show(
        0,
        'Test Notification',
        'This is a test notification to verify the system is working.',
        NotificationDetails(
          iOS: iosDetails,
          android: androidDetails,
        ),
        payload: 'test_notification',
      );
      print('Test notification sent successfully');
    } catch (e, stackTrace) {
      print('Error showing test notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime dateTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(_local!);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      _local!,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    if (scheduledDate.isBefore(now)) {
      print('Warning: Scheduled time was in the past, using next available time');
      scheduledDate = now.add(const Duration(seconds: 5));
    }

    return scheduledDate;
  }

  Future<void> scheduleTaskNotification(task_model.Task task) async {
    try {
      await ensureInitialized();

      if (task.dueDate == null) {
        print('No due date set for task: ${task.id}');
        return;
      }

      // Cancel any existing notification for this task
      await cancelNotification(task.id);

      // Don't schedule if the task is already completed
      if (task.isCompleted) {
        print('Task ${task.id} is completed, not scheduling notification');
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime taskDueDate = task.dueDate!.toLocal();
      
      print('Current time: ${_fullFormatter.format(now)}');
      print('Target due time: ${_fullFormatter.format(taskDueDate)}');

      // Don't schedule if the due date is in the past
      if (taskDueDate.isBefore(now)) {
        print('Task ${task.id} due time is in the past: ${_fullFormatter.format(taskDueDate)}');
        return;
      }

      final String priorityText = task.priority == task_model.Priority.high 
          ? '🔴 High Priority'
          : task.priority == task_model.Priority.medium
              ? '🟡 Medium Priority'
              : '🟢 Low Priority';

      // Calculate early notification time (30 minutes before)
      final DateTime earlyTime = taskDueDate.subtract(const Duration(minutes: 30));
      
      // Only schedule early notification if it's in the future
      if (earlyTime.isAfter(now)) {
        final tz.TZDateTime earlyNotificationTime = _nextInstanceOfTime(earlyTime);
        
        final String earlyNotificationBody = 
            'Task due at ${_timeFormatter.format(taskDueDate)}\n'
            '${task.description ?? 'No description'}\n'
            '$priorityText';

        await _scheduleNotification(
          task,
          earlyNotificationTime,
          'Upcoming Task: ${task.title}',
          earlyNotificationBody,
          task.id.hashCode + 1,
          earlyTime,
        );
      } else {
        print('Skipping early notification as it would be in the past');
      }

      // Schedule main notification
      final tz.TZDateTime dueTime = _nextInstanceOfTime(taskDueDate);
      
      final String mainNotificationBody = 
          'Due: ${_fullFormatter.format(taskDueDate)}\n'
          '${task.description ?? 'No description'}\n'
          '$priorityText';

      await _scheduleNotification(
        task,
        dueTime,
        'Task Due: ${task.title}',
        mainNotificationBody,
        task.id.hashCode,
        taskDueDate,
      );

    } catch (e, stackTrace) {
      print('Error scheduling notification for task ${task.id}: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _scheduleNotification(
    task_model.Task task,
    tz.TZDateTime scheduledDate,
    String title,
    String body,
    int notificationId,
    DateTime originalTime,
  ) async {
    try {
      print('Scheduling notification:');
      print('  Original time: ${_fullFormatter.format(originalTime)}');
      print('  Scheduled time: ${_fullFormatter.format(scheduledDate.toLocal())}');
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'taskDue',
        threadIdentifier: 'task_notifications',
        attachments: null,
        subtitle: _fullFormatter.format(originalTime),
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          iOS: iosDetails,
          android: AndroidNotificationDetails(
            'task_due_channel',
            'Task Due Notifications',
            channelDescription: 'Notifications for task due dates',
            importance: Importance.high,
            priority: task.priority == task_model.Priority.high 
                ? android_enums.Priority.high
                : android_enums.Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    } catch (e, stackTrace) {
      print('Error in _scheduleNotification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> cancelNotification(String taskId) async {
    try {
      await _notifications.cancel(taskId.hashCode);
      await _notifications.cancel(taskId.hashCode + 1); // Cancel early reminder too
      print('Notifications cancelled for task $taskId');
    } catch (e) {
      print('Error cancelling notification for task $taskId: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }
} 