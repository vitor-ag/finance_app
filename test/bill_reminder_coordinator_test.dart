import 'package:finance_app/features/bills/domain/entities/bill.dart';
import 'package:finance_app/features/notifications/domain/bill_reminder_coordinator.dart';
import 'package:finance_app/features/notifications/domain/reminder_notifications.dart';
import 'package:finance_app/features/notifications/domain/reminder_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_reminder_notifications.dart';

void main() {
  final today = DateTime(2026, 11, 21, 8);
  final bill = Bill(
    id: 1,
    name: 'Internet',
    amountCents: 10000,
    dueDate: DateTime(2026, 11, 23),
    billType: 'fixed',
    createdAt: today,
  );
  const enabled = ReminderSettings(enabled: true);

  test(
    'schedules once, reschedules edits, and cancels paid or cancelled bills',
    () async {
      final gateway = FakeReminderNotifications();
      final coordinator = BillReminderCoordinator(gateway, now: () => today);
      await Future.wait([
        coordinator.synchronize(enabled, [bill]),
        coordinator.synchronize(enabled, [bill]),
      ]);
      final id = gateway.scheduled.keys.single;
      expect(gateway.scheduledTimes[id], DateTime(2026, 11, 22, 9));
      expect(gateway.schedules, 1);

      final edited = bill.copyWith(
        name: 'Internet da casa',
        dueDate: DateTime(2026, 11, 24),
      );
      await coordinator.synchronize(enabled, [edited]);
      expect(gateway.cancelled, [id]);
      expect(gateway.scheduledTimes[id], DateTime(2026, 11, 23, 9));
      expect(gateway.scheduled[id]!.body, contains('Internet da casa'));

      final other = edited.copyWith(id: 2);
      await coordinator.synchronize(enabled, [edited, other]);
      gateway.active.add(id);
      await coordinator.synchronize(enabled, [
        edited.copyWith(status: 'paid'),
        other.copyWith(status: 'cancelled'),
      ]);
      expect(gateway.scheduled, isEmpty);
      expect(gateway.active, isEmpty);
    },
  );

  test('falls back to the due day for newly enabled reminders and keeps an inexact alarm pending', () async {
    final gateway = FakeReminderNotifications();
    var now = today;
    final coordinator = BillReminderCoordinator(gateway, now: () => now);
    final dueToday = bill.copyWith(dueDate: today);
    final overdue = bill.copyWith(id: 2, dueDate: DateTime(2026, 11, 20));
    await coordinator.synchronize(
      ReminderSettings(enabled: true, daysBefore: 7, configuredAt: today),
      [dueToday, overdue],
    );
    expect(gateway.scheduledTimes.values.single, DateTime(2026, 11, 21, 9));
    now = DateTime(2026, 11, 21, 9, 5);
    await coordinator.synchronize(
      ReminderSettings(enabled: true, daysBefore: 7, configuredAt: today),
      [dueToday, overdue],
    );
    expect(gateway.scheduled, hasLength(1));
    expect(gateway.schedules, 1);
  });

  test(
    'disabling reminders or revoking permission clears only bill notifications',
    () async {
      final gateway = FakeReminderNotifications();
      final coordinator = BillReminderCoordinator(gateway, now: () => today);
      gateway.scheduled[3] = const PendingReminder(3, 'Outro aviso', null);
      await coordinator.synchronize(enabled, [bill]);
      expect(gateway.scheduled, hasLength(2));

      gateway.allowed = false;
      await coordinator.synchronize(enabled, [bill]);
      expect(gateway.scheduled.keys, [3]);
      gateway.allowed = true;
      await coordinator.synchronize(enabled, [bill]);
      await coordinator.synchronize(const ReminderSettings(), []);
      expect(gateway.scheduled.keys, [3]);
    },
  );

  test(
    're-registers a cached future alarm on restart with the same ID',
    () async {
      final gateway = FakeReminderNotifications();
      await BillReminderCoordinator(
        gateway,
        now: () => today,
      ).synchronize(enabled, [bill]);
      final id = gateway.scheduled.keys.single;
      await BillReminderCoordinator(
        gateway,
        now: () => today,
      ).synchronize(enabled, [bill]);
      expect(gateway.scheduled.keys, [id]);
      expect(gateway.schedules, 2);
    },
  );
}
