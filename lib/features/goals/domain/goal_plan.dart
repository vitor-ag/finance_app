import '../../../core/calendar.dart';
import '../../forecast/domain/cash_forecast.dart';
import 'entities/goal.dart';

class GoalPlan {
  GoalPlan(this.goal, this.today, {required this.savedThisMonth});

  final Goal goal;
  final DateTime today;
  final BigInt savedThisMonth;

  int get monthsLeft {
    final due = goal.dueDate;
    if (due == null) return 0;
    final months = (due.year - today.year) * 12 + due.month - today.month + 1;
    return months < 1 ? 1 : months;
  }

  BigInt get monthlyTarget {
    if (monthsLeft == 0 || goal.isReached) return BigInt.zero;
    final atStart = BigInt.from(goal.savedCents) - savedThisMonth;
    return _share(BigInt.from(goal.targetCents) - atStart, monthsLeft);
  }

  BigInt get leftThisMonth {
    if (monthsLeft == 0 || goal.isReached) return BigInt.zero;
    final remaining = monthlyTarget - savedThisMonth;
    return remaining < BigInt.zero ? BigInt.zero : remaining;
  }

  DateTime get checkpoint {
    final end = DateTime(today.year, today.month + 1, 0);
    final due = goal.dueDate;
    return due != null && calendarDate(due).isBefore(end)
        ? calendarDate(due)
        : end;
  }

  BigInt plannedBy(DateTime date) {
    if (leftThisMonth == BigInt.zero && (goal.isReached || monthsLeft == 0)) {
      return BigInt.zero;
    }
    if (date.isBefore(checkpoint)) return BigInt.zero;
    final due = calendarDate(goal.dueDate!);
    var planned = leftThisMonth;
    for (var offset = 1; offset < monthsLeft; offset++) {
      final end = DateTime(today.year, today.month + offset + 1, 0);
      final deadline = due.isBefore(end) ? due : end;
      if (date.isBefore(deadline)) break;
      final remaining = BigInt.from(goal.remainingCents) - planned;
      planned += _share(remaining, monthsLeft - offset);
    }
    return planned;
  }
}

BigInt _share(BigInt amount, int months) {
  if (amount <= BigInt.zero) return BigInt.zero;
  final count = BigInt.from(months);
  return (amount + count - BigInt.one) ~/ count;
}

({BigInt reserved, BigInt freeNow, BigInt safeToSpend}) goalSpendingLimit(
  CashForecast forecast,
  Iterable<GoalPlan> plans, {
  int? accountId,
}) {
  final scoped = plans.where((plan) {
    final id = plan.goal.accountId;
    return forecast.accounts.containsKey(id) &&
        (accountId == null || id == accountId);
  }).toList();
  final projection = accountId == null
      ? forecast.total
      : forecast.forAccount(accountId);
  final reserved = scoped.fold(
    BigInt.zero,
    (sum, plan) => sum + BigInt.from(plan.goal.savedCents),
  );
  final free = projection.opening - reserved;
  var safe = free;
  for (final day in projection.days) {
    final planned = scoped.fold(
      BigInt.zero,
      (sum, plan) => sum + plan.plannedBy(day.date),
    );
    final available = day.closing - reserved - planned;
    if (available < safe) safe = available;
  }
  return (reserved: reserved, freeNow: free, safeToSpend: safe);
}
