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
        amount: 120,
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
    expect(expense.amount, 120);
    final transactions = TransactionRepositoryImpl(db);
    final payment = await transactions.getTransactionById(expense.id);
    await expectLater(
      transactions.updateTransaction(payment!.copyWith(amount: 100)),
      throwsStateError,
    );
    await expectLater(
      transactions.deleteTransaction(expense.id),
      throwsStateError,
    );
    expect((await db.select(db.accounts).getSingle()).currentBalance, -120);
  });

  test('generation catches up once for each due occurrence', () async {
    final recurrences = RecurrenceRepositoryImpl(db);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 8));
    final recurrenceId = await recurrences.createRecurrence(
      Recurrence(
        name: 'Receita semanal',
        type: 'income',
        amount: 50,
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
    expect((await db.select(db.accounts).getSingle()).currentBalance, 100);
  });
}
