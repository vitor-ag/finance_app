class PendingReminder {
  const PendingReminder(this.id, this.body, this.key);

  final int id;
  final String? body;
  final String? key;
}

abstract class ReminderNotifications {
  bool get isSupported;
  Future<bool> isAllowed();
  Future<bool> requestPermission();
  Future<List<PendingReminder>> pending();
  Future<List<int>> activeIds();
  Future<void> schedule(int id, String body, DateTime when);
  Future<void> cancel(int id);
  Future<void> showTest();
}
