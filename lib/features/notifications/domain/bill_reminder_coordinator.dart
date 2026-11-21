import '../../../core/calendar.dart';
import '../../bills/domain/entities/bill.dart';
import 'reminder_notifications.dart';
import 'reminder_settings.dart';

class BillReminderCoordinator {
  BillReminderCoordinator(this._notifications, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ReminderNotifications _notifications;
  final DateTime Function() _now;
  Future<void> _queue = Future.value();
  bool _restoreFutureAlarms = true;

  // Reserve this ID range for bill reminders. Android only accepts signed
  // 32-bit notification IDs.
  static const _billOffset = 0x40000000;
  static const _maxBillId = 0x3fffffff;

  Future<void> synchronize(ReminderSettings settings, List<Bill> bills) {
    final next = _queue.then((_) => _reconcile(settings, bills));
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _reconcile(ReminderSettings settings, List<Bill> bills) async {
    if (!_notifications.isSupported) return;
    final canSchedule = settings.enabled && await _notifications.isAllowed();
    final unpaid = <int, Bill>{
      if (canSchedule)
        for (final bill in bills)
          if (bill.id != null &&
              bill.id! > 0 &&
              bill.id! <= _maxBillId &&
              bill.status == 'pending')
            _billOffset + bill.id!: bill,
    };
    final now = _now();
    final today = calendarDate(now);
    final plans = {
      for (final entry in unpaid.entries)
        if (!calendarDate(entry.value.dueDate).isBefore(today))
          entry.key: _plan(entry.value, settings),
    };
    final pending = await _notifications.pending();
    final active = await _notifications.activeIds();
    final unchanged = <int>{};
    final cancel = {
      for (final id in active)
        if (_isBillId(id) && !unpaid.containsKey(id)) id,
    };

    for (final reminder in pending.where((entry) => _isBillId(entry.id))) {
      final plan = plans[reminder.id];
      if (plan != null &&
          reminder.body == plan.body &&
          reminder.key == plan.when.millisecondsSinceEpoch.toString()) {
        // Android can defer inexact reminders beyond the requested time.
        unchanged.add(reminder.id);
      } else {
        cancel.add(reminder.id);
      }
    }
    for (final id in cancel) {
      await _notifications.cancel(id);
    }
    for (final entry in plans.entries) {
      final plan = entry.value;
      // Android may drop alarms after a force stop while the plugin still
      // has them cached. Register future alarms again once per app launch.
      if ((_restoreFutureAlarms || !unchanged.contains(entry.key)) &&
          plan.when.isAfter(_now())) {
        await _notifications.schedule(entry.key, plan.body, plan.when);
      }
    }
    _restoreFutureAlarms = false;
  }

  bool _isBillId(int id) => id > _billOffset && id <= _billOffset + _maxBillId;

  ({String body, DateTime when}) _plan(Bill bill, ReminderSettings settings) {
    final due = bill.dueDate;
    final hour = settings.minuteOfDay ~/ 60;
    final minute = settings.minuteOfDay % 60;
    final preferred = DateTime(
      due.year,
      due.month,
      due.day - settings.daysBefore,
      hour,
      minute,
    );
    final configuredAt = settings.configuredAt;
    final startsAt =
        configuredAt != null && configuredAt.isAfter(bill.createdAt)
        ? configuredAt
        : bill.createdAt;
    // Keep the chosen time stable across app launches, including after delivery.
    final when = preferred.isBefore(startsAt)
        ? DateTime(due.year, due.month, due.day, hour, minute)
        : preferred;
    return (
      body: '${bill.name} vence em ${due.day}/${due.month}/${due.year}.',
      when: when,
    );
  }
}
