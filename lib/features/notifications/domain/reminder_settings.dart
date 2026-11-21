class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.daysBefore = 1,
    this.minuteOfDay = 9 * 60,
    this.configuredAt,
  });

  final bool enabled;
  final int daysBefore;
  final int minuteOfDay;
  final DateTime? configuredAt;
}
