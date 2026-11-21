import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_notifications.dart';

class AndroidReminderNotifications implements ReminderNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  static const _channelId = 'bill_due_reminders';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Vencimentos de contas',
      channelDescription: 'Lembretes de contas a pagar cadastradas no app',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
    ),
  );

  @override
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  Future<void> _ensureInitialized() async {
    try {
      await (_initialization ??= _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification_bell'),
        ),
      ));
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<bool> isAllowed() async {
    await _ensureInitialized();
    if (await _android.areNotificationsEnabled() != true) return false;
    final channels = await _android.getNotificationChannels() ?? [];
    return !channels.any(
      (channel) =>
          channel.id == _channelId && channel.importance == Importance.none,
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (await _android.areNotificationsEnabled() != true) {
      await _android.requestNotificationsPermission();
    }
    return isAllowed();
  }

  @override
  Future<List<PendingReminder>> pending() async {
    await _ensureInitialized();
    return (await _plugin.pendingNotificationRequests())
        .map((entry) => PendingReminder(entry.id, entry.body, entry.payload))
        .toList();
  }

  @override
  Future<List<int>> activeIds() async {
    await _ensureInitialized();
    return (await _plugin.getActiveNotifications())
        .map((entry) => entry.id)
        .nonNulls
        .toList();
  }

  @override
  Future<void> schedule(int id, String body, DateTime when) async {
    await _ensureInitialized();
    // DateTime already resolves the device offset for this future local date.
    await _plugin.zonedSchedule(
      id,
      'Vencimento de conta',
      body,
      tz.TZDateTime.from(when, tz.UTC),
      _details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: when.millisecondsSinceEpoch.toString(),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id);
  }

  @override
  Future<void> showTest() async {
    await _ensureInitialized();
    await _plugin.show(
      1,
      'Notificação de teste',
      'Este é um teste dos lembretes de vencimento.',
      _details,
    );
  }
}
