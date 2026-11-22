import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/forecast/domain/cash_forecast.dart';
import 'package:finance_app/features/goals/domain/entities/goal.dart';
import 'package:finance_app/features/goals/domain/goal_plan.dart';
import 'package:finance_app/features/recurrences/data/repositories/recurrence_repository_impl.dart';
import 'package:finance_app/features/recurrences/domain/entities/recurrence.dart';
import 'package:finance_app/features/salary/salary_payment.dart';
import 'package:finance_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'editing a recurring salary keeps the net amount consistent with payroll',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final account = await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'Banco', type: 'checking'));
      final start = DateTime(2026, 1, 15);
      const payment = SalaryPayment(
        gross: 150000,
        variable: 0,
        deductions: 20000,
      );
      final scheduler = RecurrenceRepositoryImpl(db);
      await scheduler.createRecurrence(
        Recurrence(
          name: 'Salário',
          type: 'income',
          amountCents: payment.net,
          accountId: account,
          frequency: 'monthly',
          startDate: start,
          nextOccurrenceDate: start,
          createdAt: start,
        ),
        first: Transaction(
          type: 'income',
          amountCents: payment.net,
          date: start,
          accountId: account,
          note: payment.note,
          incomeSource: salaryIncomeSource,
          status: 'pending',
          createdAt: start,
        ),
      );
      final recurrence = (await scheduler.watchAllRecurrences().first).single;
      await expectLater(
        scheduler.updateRecurrence(recurrence.copyWith(amountCents: 125000)),
        throwsStateError,
      );
      expect(
        (await db.select(db.recurrences).getSingle()).amountCents,
        payment.net,
      );
    },
  );

  test('pacing credits deposits and carries the next installment into the forecast', () {
    final today = DateTime(2026, 1, 31);
    final plan = GoalPlan(
      Goal(
        name: 'Viagem',
        targetCents: 120000,
        savedCents: 18000,
        accountId: 1,
        dueDate: DateTime(2026, 3, 1),
      ),
      today,
      savedThisMonth: BigInt.from(9000),
    );
    expect(plan.monthlyTarget, BigInt.from(37000));
    expect(plan.leftThisMonth, BigInt.from(28000));
    expect(plan.plannedBy(DateTime(2026, 2, 28)), BigInt.from(65000));
    expect(plan.plannedBy(DateTime(2026, 3, 1)), BigInt.from(102000));
    final forecast = CashForecast(
      today: today,
      accounts: {1: (name: 'Banco', balance: 180000)},
      events: [
        CashEvent(
          title: 'Aluguel',
          date: DateTime(2026, 2, 1),
          delta: BigInt.from(-50000),
          source: CashEventSource.bill,
        ),
      ],
    );
    final limit = goalSpendingLimit(forecast, [plan]);
    expect(limit.reserved, BigInt.from(18000));
    expect(limit.freeNow, BigInt.from(162000));
    expect(limit.safeToSpend, BigInt.from(10000));
  });

  test('salary breakdown round trips and forecasts the net amount', () {
    const payment = SalaryPayment(
      gross: 160000,
      variable: 20000,
      deductions: 35000,
    );
    payment.validate();
    expect(payment.net, 145000);
    final decoded = SalaryPayment.fromNote(payment.note)!;
    expect(decoded.gross, payment.gross);
    expect(decoded.variable, payment.variable);
    expect(decoded.deductions, payment.deductions);
    expect(
      const SalaryPayment(gross: 100, variable: 0, deductions: 101).validate,
      throwsStateError,
    );
  });
}
