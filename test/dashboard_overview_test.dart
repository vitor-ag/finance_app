import 'package:finance_app/features/accounts/domain/entities/account.dart';
import 'package:finance_app/features/bills/domain/entities/bill.dart';
import 'package:finance_app/features/dashboard/domain/dashboard_overview.dart';
import 'package:finance_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sums posted cash flow and splits open bills by calendar day', () {
    final today = DateTime(2026, 11, 21, 18);
    const openingCents = 12000;
    final account = Account(
      name: 'Carteira',
      type: 'cash',
      initialBalanceCents: openingCents,
      currentBalanceCents: openingCents,
      createdAt: today,
    );

    Transaction entry(
      String type,
      int amountCents, {
      String status = 'paid',
      DateTime? deletedAt,
    }) => Transaction(
      type: type,
      amountCents: amountCents,
      date: today,
      accountId: 1,
      status: status,
      createdAt: today,
      deletedAt: deletedAt,
    );

    Bill bill(
      String name,
      int day,
      int amountCents, {
      String status = 'pending',
    }) => Bill(
      name: name,
      amountCents: amountCents,
      dueDate: DateTime(2026, 11, day),
      billType: 'fixed',
      status: status,
      createdAt: today,
    );

    final overview = DashboardOverview.calculate(
      accounts: [
        account,
        account.copyWith(isActive: false, currentBalanceCents: 25000),
      ],
      transactions: [
        entry('income', 2005),
        entry('expense', 751),
        entry('card_payment', 500),
        entry('transfer', 30000),
        entry('income', 999, status: 'pending'),
        entry('expense', 888, status: 'cancelled'),
        entry('expense', 777, deletedAt: today),
      ],
      bills: [
        bill('Internet', 22, 3300),
        bill('Telefone', 20, 1199),
        bill('Energia', 21, 345),
        bill('Paga', 19, 5000, status: 'paid'),
        bill('Cancelada', 20, 6000, status: 'cancelled'),
      ],
      today: today,
      cardPurchaseAmounts: [500],
    );

    expect(overview.activeBalanceCents, BigInt.from(openingCents));
    expect(overview.incomeCents, BigInt.from(2005));
    expect(overview.expenseCents, BigInt.from(1251));
    expect(overview.resultCents, BigInt.from(754));
    expect(overview.pendingBills.map((bill) => bill.name), [
      'Telefone',
      'Energia',
      'Internet',
    ]);
    expect(overview.overdueCents, BigInt.from(1199));
    expect(overview.overdueCount, 1);
    expect(overview.upcomingCents, BigInt.from(3645));
    expect(overview.upcomingCount, 2);
  });
}
