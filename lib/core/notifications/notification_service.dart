import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_reminder_stub.dart' if (dart.library.html) 'web_reminder_web.dart' as web;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification click
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if platform notifications are unsupported (e.g., test/web/desktop)
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'detailed_to_do_channel',
        'DetailedToDo Recordatorios',
        channelDescription: 'Canal de notificaciones y recordatorios de DetailedToDo',
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> showAICompletedNotification({
    required String taskTitle,
  }) async {
    await showNotification(
      id: 9999,
      title: '¡Generación de IA completada!',
      body: 'Se han generado las subtareas para: "$taskTitle".',
    );
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  Future<bool> requestWebPermission() => web.requestPermission();

  void scheduleTaskReminders({
    required String taskId,
    required String title,
    DateTime? reminderDate,
    DateTime? dueDate,
    int? lastMinuteReminderMinutes,
  }) {
    web.cancel('$taskId-reminder');
    web.cancel('$taskId-last-minute');
    if (reminderDate != null) {
      web.schedule('$taskId-reminder', 'Recordatorio: $title', 'Tienes un recordatorio pendiente.', reminderDate);
    }
    if (dueDate != null && lastMinuteReminderMinutes != null) {
      final alertAt = dueDate.subtract(Duration(minutes: lastMinuteReminderMinutes));
      web.schedule('$taskId-last-minute', 'Último aviso: $title', 'La fecha límite se acerca.', alertAt);
    }
  }
}
