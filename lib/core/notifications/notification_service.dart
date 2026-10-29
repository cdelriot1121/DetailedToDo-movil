import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import '../network/dio_client.dart';
import 'web_reminder_stub.dart'
    if (dart.library.html) 'web_reminder_web.dart'
    as web;
import 'web_push_stub.dart' if (dart.library.html) 'web_push_web.dart' as push;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioClientProvider));
});

class NotificationService {
  NotificationService(this._dio);

  final Dio _dio;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    timezone_data.initializeTimeZones();
    if (kIsWeb) await push.prepareWebPush();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
        onDidReceiveNotificationResponse: (response) {},
      );
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'detailed_to_do_channel',
          'DetailedToDo Recordatorios',
          channelDescription:
              'Canal de notificaciones y recordatorios de DetailedToDo',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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

  Future<void> showAICompletedNotification({required String taskTitle}) async {
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

  Future<bool> requestWebPermission() async {
    if (!kIsWeb || !await web.requestPermission()) return false;
    return push.enableWebPush(_dio);
  }

  Future<bool> requestReminderPermission() async {
    if (kIsWeb) return requestWebPermission();
    return requestMobileReminderPermission();
  }

  Future<bool> requestMobileReminderPermission() async {
    if (kIsWeb) return false;
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> disableWebPush() => push.disableWebPush(_dio);

  void scheduleTaskReminders({
    required String taskId,
    required String title,
    DateTime? reminderDate,
    DateTime? dueDate,
    int? lastMinuteReminderMinutes,
  }) {
    web.cancel('$taskId-reminder');
    web.cancel('$taskId-last-minute');
    if (!kIsWeb) {
      unawaited(_cancelLocalReminder(_reminderId(taskId, 'reminder')));
      unawaited(_cancelLocalReminder(_reminderId(taskId, 'last-minute')));
    }

    if (reminderDate != null && reminderDate.isAfter(DateTime.now())) {
      if (kIsWeb) {
        if (!push.webPushEnabled) {
          web.schedule(
            '$taskId-reminder',
            'Recordatorio: $title',
            'Tienes un recordatorio pendiente.',
            reminderDate,
          );
        }
      } else {
        unawaited(
          _scheduleLocalReminder(
            _reminderId(taskId, 'reminder'),
            'Recordatorio: $title',
            'Tienes un recordatorio pendiente.',
            reminderDate,
          ),
        );
      }
    }

    if (dueDate != null && lastMinuteReminderMinutes != null) {
      final alertAt = dueDate.subtract(
        Duration(minutes: lastMinuteReminderMinutes),
      );
      if (!alertAt.isAfter(DateTime.now())) return;
      if (kIsWeb) {
        if (!push.webPushEnabled) {
          web.schedule(
            '$taskId-last-minute',
            'Último aviso: $title',
            'La fecha límite se acerca.',
            alertAt,
          );
        }
      } else {
        unawaited(
          _scheduleLocalReminder(
            _reminderId(taskId, 'last-minute'),
            'Último aviso: $title',
            'La fecha límite se acerca.',
            alertAt,
          ),
        );
      }
    }
  }

  void scheduleEventReminder({
    required String eventId,
    required String title,
    DateTime? reminderDate,
  }) {
    web.cancel('$eventId-event-reminder');
    if (!kIsWeb) {
      unawaited(_cancelLocalReminder(_reminderId(eventId, 'event-reminder')));
    }
    if (reminderDate == null || !reminderDate.isAfter(DateTime.now())) return;
    if (kIsWeb) {
      if (!push.webPushEnabled) {
        web.schedule(
          '$eventId-event-reminder',
          'Recordatorio: $title',
          'Tienes un evento próximo.',
          reminderDate,
        );
      }
    } else {
      unawaited(
        _scheduleLocalReminder(
          _reminderId(eventId, 'event-reminder'),
          'Recordatorio: $title',
          'Tienes un evento próximo.',
          reminderDate,
        ),
      );
    }
  }

  Future<void> _scheduleLocalReminder(
    int id,
    String title,
    String body,
    DateTime at,
  ) async {
    if (!at.isAfter(DateTime.now())) return;
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: timezone.TZDateTime.from(at, timezone.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'detailed_to_do_channel',
            'DetailedToDo Recordatorios',
            channelDescription:
                'Canal de notificaciones y recordatorios de DetailedToDo',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  Future<void> _cancelLocalReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  int _reminderId(String taskId, String kind) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode('$taskId:$kind')) {
      hash = ((hash ^ byte) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
