import '../../../core/calendar.dart';
import '../../accounts/domain/entities/account.dart';
import '../../bills/domain/entities/bill.dart';
import '../../transactions/domain/entities/transaction.dart';

class DashboardOverview {
  DashboardOverview._({
    required this.activeBalanceCents,
    required this.incomeCents,
    required this.expenseCents,
    required this.overdueCents,
    required this.upcomingCents,
    required this.overdueCount,
    required this.pendingBills,
  });

  factory DashboardOverview.calculate({
    required Iterable<Account> accounts,
    required Iterable<Transaction> transactions,
    required Iterable<Bill> bills,
    required DateTime today,
    Iterable<int> cardPurchaseAmounts = const [],
  }) {
    final activeBalance = accounts
        .where((account) => account.isActive)
        .fold(
          BigInt.zero,
          (sum, account) => sum + BigInt.from(account.currentBalanceCents),
        );
    var income = BigInt.zero;
    var expense = cardPurchaseAmounts.fold(
      BigInt.zero,
      (total, cents) => total + BigInt.from(cents),
    );
    for (final entry in transactions) {
      if (entry.status != 'paid' || entry.deletedAt != null) continue;
      switch (entry.type) {
        case 'income':
          income += BigInt.from(entry.amountCents);
        case 'expense':
          expense += BigInt.from(entry.amountCents);
      }
    }

    final pending = bills.where((bill) => bill.status == 'pending').toList()
      ..sort((first, second) => first.dueDate.compareTo(second.dueDate));
    var overdue = BigInt.zero;
    var upcoming = BigInt.zero;
    var overdueCount = 0;
    final day = calendarDate(today);
    for (final bill in pending) {
      if (calendarDate(bill.dueDate).isBefore(day)) {
        overdue += BigInt.from(bill.amountCents);
        overdueCount++;
      } else {
        upcoming += BigInt.from(bill.amountCents);
      }
    }
    return DashboardOverview._(
      activeBalanceCents: activeBalance,
      incomeCents: income,
      expenseCents: expense,
      overdueCents: overdue,
      upcomingCents: upcoming,
      overdueCount: overdueCount,
      pendingBills: List.unmodifiable(pending),
    );
  }

  final BigInt activeBalanceCents;
  final BigInt incomeCents;
  final BigInt expenseCents;
  final BigInt overdueCents;
  final BigInt upcomingCents;
  final int overdueCount;
  final List<Bill> pendingBills;

  BigInt get resultCents => incomeCents - expenseCents;
  int get upcomingCount => pendingBills.length - overdueCount;
}
