import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_notifications.dart';

class AndroidReminderNotifications implements ReminderNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  static const _channelId = 'bill_due_reminders';
  static const _investmentChannelId = 'investment_review';
  static const _dailyId = 2;
  static const _budgetId = 3;
  static const _investmentId = 4;
  static const _goalsId = 5;
  static const _goalsChannel = 'goal_savings';
  Future<void> _goalUpdates = Future.value();

  Future<bool> allowGoalReview() async {
    await _ensureInitialized();
    if (await _android.areNotificationsEnabled() != true) {
      await _android.requestNotificationsPermission();
    }
    if (await _android.areNotificationsEnabled() != true) return false;
    final channels = await _android.getNotificationChannels() ?? [];
    return !channels.any(
      (channel) =>
          channel.id == _goalsChannel && channel.importance == Importance.none,
    );
  }

  Future<void> syncGoalReview(DateTime? when) {
    final next = _goalUpdates.then((_) async {
      await _ensureInitialized();
      if (when == null) {
        await _plugin.cancel(_goalsId);
        return;
      }
      final payload = when.millisecondsSinceEpoch.toString();
      if ((await pending()).any(
        (item) => item.id == _goalsId && item.key == payload,
      ))
        return;
      await _plugin.zonedSchedule(
        _goalsId,
        'Confira suas metas',
        'Há valores pendentes no planejamento de economia. Veja o progresso no Finance App.',
        tz.TZDateTime.from(when, tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _goalsChannel,
            'Economia para metas',
            visibility: NotificationVisibility.private,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    });
    _goalUpdates = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  static const _planning = NotificationDetails(
    android: AndroidNotificationDetails(
      'finance_planning',
      'Planejamento',
      channelDescription: 'Lembretes diários e alertas de orçamento',
      visibility: NotificationVisibility.private,
    ),
  );
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
  static const _investment = NotificationDetails(
    android: AndroidNotificationDetails(
      _investmentChannelId,
      'Revisão de investimentos',
      channelDescription: 'Lembrete mensal para atualizar valores informados',
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

  Future<void> setDailyReminder(bool enabled, int minuteOfDay) async {
    await _ensureInitialized();
    await _plugin.cancel(_dailyId);
    if (!enabled || await _android.areNotificationsEnabled() != true) return;
    final location = await _deviceLocation();
    final now = tz.TZDateTime.now(location);
    var next = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day + 1,
        minuteOfDay ~/ 60,
        minuteOfDay % 60,
      );
    }
    await _plugin.zonedSchedule(
      _dailyId,
      'Lembrete diário',
      'Reserve um momento para registrar seus lançamentos.',
      next,
      _planning,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> hasInvestmentReminder() async {
    return (await pending()).any((item) => item.id == _investmentId);
  }

  Future<bool> setInvestmentReminder(bool enabled) async {
    await _ensureInitialized();
    if (!enabled) {
      await _plugin.cancel(_investmentId);
      return true;
    }
    if (await _android.areNotificationsEnabled() != true) {
      await _android.requestNotificationsPermission();
      if (await _android.areNotificationsEnabled() != true) return false;
    }
    final channels = await _android.getNotificationChannels() ?? [];
    if (channels.any(
      (channel) =>
          channel.id == _investmentChannelId &&
          channel.importance == Importance.none,
    )) {
      return false;
    }
    final location = await _deviceLocation();
    final now = tz.TZDateTime.now(location);
    var next = tz.TZDateTime(location, now.year, now.month, 1, 9);
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(location, now.year, now.month + 1, 1, 9);
    }
    await _plugin.zonedSchedule(
      _investmentId,
      'Revisão mensal de investimentos',
      'Confira seus extratos e atualize os valores no Finance App.',
      next,
      _investment,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    return true;
  }

  Future<tz.Location> _deviceLocation() async {
    tzdata.initializeTimeZones();
    final zone = await const MethodChannel('finance_app/local_backup')
        .invokeMethod<String>('timeZone');
    return tz.getLocation(zone ?? 'UTC');
  }

  Future<void> showBudgetAlert(bool exceeded) async {
    await _ensureInitialized();
    await _plugin.show(
      _budgetId,
      'Alerta de orçamento',
      exceeded
          ? 'Você atingiu o limite de um orçamento mensal.'
          : 'Um orçamento mensal chegou a 80% do limite.',
      _planning,
    );
  }
}
