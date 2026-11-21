import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:finance_app/features/bills/domain/entities/bill.dart';
import 'package:finance_app/features/recurrences/data/repositories/recurrence_repository_impl.dart';
import 'package:finance_app/features/recurrences/domain/entities/recurrence.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int accountId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    accountId = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
  });

  test('paying an overdue bill creates one linked expense', () async {
    final bills = BillRepositoryImpl(db);
    final now = DateTime.now();
    final billId = await bills.createBill(
      Bill(
        name: 'Aluguel',
        amountCents: 12000,
        dueDate: now.subtract(const Duration(days: 1)),
        billType: 'fixed',
        createdAt: now,
      ),
    );
    expect((await bills.getBillById(billId))!.effectiveStatus, 'overdue');

    await Future.wait([
      bills.markAsPaid(billId, paymentAccountId: accountId),
      bills.markAsPaid(billId, paymentAccountId: accountId),
    ]);
    await bills.cancelBill(billId);

    final bill = (await bills.getBillById(billId))!;
    final expense = await db.select(db.transactions).getSingle();
    expect(bill.status, 'paid');
    expect(bill.paidTransactionId, expense.id);
    expect(expense.type, 'expense');
    expect(expense.amountCents, 12000);
    final transactions = TransactionRepositoryImpl(db);
    final payment = await transactions.getTransactionById(expense.id);
    await expectLater(
      transactions.updateTransaction(payment!.copyWith(amountCents: 10000)),
      throwsStateError,
    );
    await expectLater(
      transactions.deleteTransaction(expense.id),
      throwsStateError,
    );
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -12000,
    );
  });

  test('generation catches up once for each due occurrence', () async {
    final recurrences = RecurrenceRepositoryImpl(db);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 8));
    final recurrenceId = await recurrences.createRecurrence(
      Recurrence(
        name: 'Receita semanal',
        type: 'income',
        amountCents: 5000,
        accountId: accountId,
        frequency: 'weekly',
        startDate: start,
        nextOccurrenceDate: start,
        createdAt: now,
      ),
    );

    await Future.wait([
      recurrences.generateDueOccurrences(),
      recurrences.generateDueOccurrences(),
    ]);
    await recurrences.generateDueOccurrences();

    final entries = await db.select(db.transactions).get();
    expect(entries, hasLength(2));
    expect(
      entries.map((entry) => entry.recurrenceId),
      everyElement(recurrenceId),
    );
    expect((await db.select(db.recurrences).getSingle()).generatedCount, 2);
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      10000,
    );
  });

  test(
    'monthly bills keep their day and stopping the series preserves its bills',
    () async {
      final repo = BillRepositoryImpl(db);
      final now = DateTime.now();
      final id = await repo.createBill(
        Bill(
          name: 'Internet',
          amountCents: 7999,
          dueDate: DateTime(2024, 1, 31),
          billType: 'recurring',
          createdAt: now,
        ),
      );
      await Future.wait([repo.generateDueBills(), repo.generateDueBills()]);
      final entries = await db.select(db.bills).get();
      expect(entries.take(3).map((bill) => bill.dueDate), [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29),
        DateTime(2024, 3, 31),
      ]);
      expect(
        entries.map((bill) => bill.dueDate).toSet(),
        hasLength(entries.length),
      );
      expect(entries[1].previousBillId, id);
      final latest = entries.singleWhere((bill) => bill.repeatDay != null);
      await repo.updateBill(
        (await repo.getBillById(latest.id))!.copyWith(amountCents: 8999),
      );
      expect((await repo.getBillById(latest.id))!.amountCents, 8999);
      expect((await repo.getBillById(id))!.amountCents, 7999);
      await repo.cancelBill(id);
      expect((await repo.getBillById(id))!.status, 'cancelled');
      await repo.stopRepeating(latest.id);
      await repo.generateDueBills();
      final stopped = await db.select(db.bills).get();
      expect(stopped, hasLength(entries.length));
      expect(stopped.map((bill) => bill.repeatDay), everyElement(isNull));
      expect(await db.select(db.transactions).get(), isEmpty);
    },
  );

  test(
    'recurrences end on the inclusive end date or their occurrence limit',
    () async {
      final repo = RecurrenceRepositoryImpl(db);
      final start = DateTime(2024, 2, 29);
      final original = Recurrence(
        name: 'Rendimento',
        type: 'income',
        amountCents: 101,
        accountId: accountId,
        frequency: 'yearly',
        startDate: start,
        nextOccurrenceDate: start,
        endDate: DateTime(2025, 2, 28),
        createdAt: DateTime.now(),
      );
      final endingByDate = await repo.createRecurrence(original);
      final endingByLimit = await repo.createRecurrence(
        original.copyWith(maxOccurrences: 1),
      );
      await repo.generateDueOccurrences();
      final entries = await db.select(db.transactions).get();
      expect(
        entries
            .where((entry) => entry.recurrenceId == endingByDate)
            .map((entry) => entry.date),
        [start, DateTime(2025, 2, 28)],
      );
      expect(
        entries.where((entry) => entry.recurrenceId == endingByLimit),
        hasLength(1),
      );
      expect(
        (await db.select(db.recurrences).get()).map((row) => row.status),
        everyElement('finished'),
      );
      expect(
        (await db.select(db.accounts).getSingle()).currentBalanceCents,
        303,
      );
    },
  );
}
