import '../../../../core/calendar.dart';

class Goal {
  const Goal({
    this.id,
    required this.name,
    required this.targetCents,
    this.dueDate,
    this.savedCents = 0,
    this.accountId,
    this.icon,
  });

  final int? id;
  final String name;
  final int targetCents;
  final int savedCents;
  final DateTime? dueDate;
  final int? accountId;
  final String? icon;

  bool get isReached => savedCents >= targetCents;
  int get remainingCents => isReached ? 0 : targetCents - savedCents;
  int get progressPercent => savedCents * 100 ~/ targetCents;

  bool isOverdue(DateTime today) =>
      !isReached &&
      dueDate != null &&
      calendarDate(dueDate!).isBefore(calendarDate(today));
}
