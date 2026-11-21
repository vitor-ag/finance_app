import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/credit_cards/data/credit_card_repository.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('purchase splits cents and payment debits account only once', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CreditCardRepository(db);
    final accountId = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Conta', type: 'cash'));
    final cardId = await repo.createCard(
      name: 'Cartão',
      limitCents: 20000,
      closingDay: 20,
      dueDay: 10,
    );
    await repo.createPurchase(
      cardId: cardId,
      description: 'Compra',
      amountCents: 10000,
      count: 3,
      date: DateTime(2026, 1, 10),
    );
    final installments = await db.select(db.cardInstallments).get();
    expect(installments.map((i) => i.amountCents), [3334, 3333, 3333]);
    final card = await db.select(db.creditCards).getSingle();
    await expectLater(
      repo.updateCard(card.copyWith(dueDay: 15)),
      throwsStateError,
    );
    expect((await db.select(db.creditCards).getSingle()).dueDay, 10);
    await repo.payStatement(
      cardId: cardId,
      closingDate: DateTime(2026, 1, 20),
      accountId: accountId,
    );
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -3334,
    );
    final transaction = await db.select(db.transactions).getSingle();
    expect(transaction.type, 'card_payment');
    await expectLater(
      repo.payStatement(
        cardId: cardId,
        closingDate: DateTime(2026, 1, 20),
        accountId: accountId,
      ),
      throwsStateError,
    );
    await expectLater(
      TransactionRepositoryImpl(db).deleteTransaction(transaction.id),
      throwsStateError,
    );
    await expectLater(
      repo.createPurchase(
        cardId: cardId,
        description: 'Compra retroativa',
        amountCents: 100,
        count: 1,
        date: DateTime(2026, 1, 12),
      ),
      throwsStateError,
    );
    expect(await db.select(db.cardPurchases).get(), hasLength(1));
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -3334,
    );
  });
}
