import '../../../core/calendar.dart';

const cashForecastDays = 30;

DateTime forecastDateAt(DateTime start, int index) =>
    DateTime(start.year, start.month, start.day + index);

enum CashEventSource { bill, repeatingBill, statement, scheduled, recurrence }

class CashEvent {
  const CashEvent({
    required this.title,
    required this.date,
    required this.delta,
    required this.source,
    this.accountId,
    this.destinationAccountId,
    this.cardId,
  });

  final String title;
  final DateTime date;
  final BigInt delta;
  final CashEventSource source;
  final int? accountId, destinationAccountId, cardId;

  bool get isTransfer => destinationAccountId != null;

  BigInt _deltaFor(int? account, Map<int, ForecastAccount> activeAccounts) {
    if (account != null) {
      if (account == accountId) return delta;
      if (account == destinationAccountId) return -delta;
      return BigInt.zero;
    }
    if (!isTransfer) {
      return accountId == null || activeAccounts.containsKey(accountId)
          ? delta
          : BigInt.zero;
    }
    final fromActive = activeAccounts.containsKey(accountId);
    final toActive = activeAccounts.containsKey(destinationAccountId);
    if (fromActive == toActive) return BigInt.zero;
    return fromActive ? delta : -delta;
  }
}

typedef ForecastAccount = ({String name, int balance});
typedef ProjectedMovement = ({CashEvent event, BigInt delta});
typedef ForecastDay = ({
  DateTime date,
  List<ProjectedMovement> movements,
  BigInt closing,
});

class CashForecast {
  CashForecast({
    required DateTime today,
    required Map<int, ForecastAccount> accounts,
    required Iterable<CashEvent> events,
  }) : today = calendarDate(today),
       accounts = Map.unmodifiable(accounts),
       events = List.unmodifiable(events.toList()..sort(_compareEvents));

  final DateTime today;
  final Map<int, ForecastAccount> accounts;
  final List<CashEvent> events;
  late final CashProjection total = forAccount();

  static int _compareEvents(CashEvent a, CashEvent b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final bySource = a.source.index.compareTo(b.source.index);
    return bySource == 0 ? a.title.compareTo(b.title) : bySource;
  }

  CashProjection forAccount([int? accountId]) {
    final opening = accountId == null
        ? accounts.values.fold(
            BigInt.zero,
            (sum, account) => sum + BigInt.from(account.balance),
          )
        : BigInt.from(accounts[accountId]?.balance ?? 0);
    final movementsByDate = <DateTime, List<ProjectedMovement>>{};
    var income = BigInt.zero;
    var expense = BigInt.zero;
    final lastDay = forecastDateAt(today, cashForecastDays - 1);
    for (final event in events) {
      final date = calendarDate(event.date);
      if (date.isAfter(lastDay)) break;
      final delta = event._deltaFor(accountId, accounts);
      if (delta == BigInt.zero) continue;
      if (delta.isNegative) {
        expense -= delta;
      } else {
        income += delta;
      }
      final effectiveDate = date.isBefore(today) ? today : date;
      movementsByDate.putIfAbsent(effectiveDate, () => []).add((
        event: event,
        delta: delta,
      ));
    }

    var balance = opening;
    final days = <ForecastDay>[];
    for (var index = 0; index < cashForecastDays; index++) {
      final date = forecastDateAt(today, index);
      final movements = movementsByDate[date] ?? const <ProjectedMovement>[];
      for (final movement in movements) {
        balance += movement.delta;
      }
      days.add((date: date, movements: movements, closing: balance));
    }
    return CashProjection(
      opening: opening,
      income: income,
      expense: expense,
      days: List.unmodifiable(days),
    );
  }
}

class CashProjection {
  const CashProjection({
    required this.opening,
    required this.income,
    required this.expense,
    required this.days,
  });

  final BigInt opening, income, expense;
  final List<ForecastDay> days;

  ForecastDay get lowestDay =>
      days.reduce((lowest, day) => day.closing < lowest.closing ? day : lowest);
  ForecastDay? get firstNegativeDay =>
      days.where((day) => day.closing.isNegative).firstOrNull;
}
