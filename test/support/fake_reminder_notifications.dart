import 'package:finance_app/features/notifications/domain/reminder_notifications.dart';

class FakeReminderNotifications implements ReminderNotifications {
  bool allowed = true;
  int permissionRequests = 0;
  int testNotifications = 0;
  final scheduledTimes = <int, DateTime>{};
  final scheduled = <int, PendingReminder>{};
  final active = <int>[];
  final cancelled = <int>[];
  int schedules = 0;

  @override
  bool get isSupported => true;

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    allowed = true;
    return allowed;
  }

  @override
  Future<List<PendingReminder>> pending() async => scheduled.values.toList();

  @override
  Future<List<int>> activeIds() async => active.toList();

  @override
  Future<void> schedule(int id, String body, DateTime when) async {
    schedules++;
    scheduled[id] = PendingReminder(
      id,
      body,
      when.millisecondsSinceEpoch.toString(),
    );
    scheduledTimes[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    active.remove(id);
    scheduled.remove(id);
    scheduledTimes.remove(id);
  }

  @override
  Future<void> showTest() async {
    testNotifications++;
  }
}
