import 'package:drift/drift.dart';

import '../../../core/calendar.dart';
import '../../../core/money.dart';
import '../../../data/local/database.dart';
import '../domain/installment_schedule.dart';

class CreditCardRepository {
  CreditCardRepository(this.db);
  final AppDatabase db;

  Stream<List<CreditCardRow>> watchCards() => db.select(db.creditCards).watch();

  Stream<List<CardPurchaseRow>> watchPurchases() =>
      db.select(db.cardPurchases).watch();
  Stream<List<CardInstallmentRow>> watchInstallments() =>
      db.select(db.cardInstallments).watch();

  Future<void> updateCard(CreditCardRow card) async {
    final name = card.name.trim();
    if (name.isEmpty ||
        name.length > 80 ||
        card.closingDay < 1 ||
        card.closingDay > 31 ||
        card.dueDay < 1 ||
        card.dueDay > 31) {
      throw StateError('Informe os dados do cartão.');
    }
    validatePositiveCents(card.limitCents);
    await db.transaction(() async {
      final previous = await (db.select(
        db.creditCards,
      )..where((row) => row.id.equals(card.id))).getSingle();
      if (previous.closingDay != card.closingDay ||
          previous.dueDay != card.dueDay) {
        final installments = db.cardInstallments;
        final purchases = db.cardPurchases;
        final pending =
            await (db.select(installments).join([
                    innerJoin(
                      purchases,
                      purchases.id.equalsExp(installments.purchaseId),
                    ),
                  ])
                  ..where(
                    purchases.cardId.equals(card.id) &
                        installments.paymentId.isNull(),
                  )
                  ..limit(1))
                .get();
        if (pending.isNotEmpty) {
          throw StateError(
            'Quite as faturas pendentes antes de alterar os dias.',
          );
        }
      }
      await (db.update(
        db.creditCards,
      )..where((row) => row.id.equals(card.id))).write(
        CreditCardsCompanion(
          name: Value(name),
          limitCents: Value(card.limitCents),
          closingDay: Value(card.closingDay),
          dueDay: Value(card.dueDay),
        ),
      );
    });
  }

  Future<void> archiveCard(int id) async {
    await (db.update(db.creditCards)..where((row) => row.id.equals(id))).write(
      const CreditCardsCompanion(isActive: Value(false)),
    );
  }

  Future<void> reactivateCard(int id) async {
    await (db.update(db.creditCards)..where((row) => row.id.equals(id))).write(
      const CreditCardsCompanion(isActive: Value(true)),
    );
  }

  Future<int> createCard({
    required String name,
    required int limitCents,
    required int closingDay,
    required int dueDay,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 80 ||
        closingDay < 1 ||
        closingDay > 31 ||
        dueDay < 1 ||
        dueDay > 31) {
      throw StateError('Informe os dados do cartão.');
    }
    validatePositiveCents(limitCents);
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            name: trimmed,
            limitCents: limitCents,
            closingDay: closingDay,
            dueDay: dueDay,
          ),
        );
  }

  Future<int> createPurchase({
    required int cardId,
    required String description,
    required int amountCents,
    required int count,
    required DateTime date,
    int? categoryId,
  }) => db.transaction(() async {
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null || !card.isActive) {
      throw StateError('Selecione um cartão ativo.');
    }
    final name = description.trim();
    if (name.isEmpty || name.length > 100) {
      throw StateError('Informe a descrição da compra.');
    }
    if (categoryId != null) {
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null ||
          !category.isActive ||
          category.type != 'expense') {
        throw StateError('Selecione uma categoria de despesa ativa.');
      }
    }
    final schedule = scheduleInstallments(
      totalCents: amountCents,
      count: count,
      purchaseDate: date,
      closingDay: card.closingDay,
      dueDay: card.dueDay,
    );
    final paidStatements =
        await (db.select(db.cardPayments)
              ..where(
                (payment) =>
                    payment.cardId.equals(cardId) &
                    payment.closingDate.isIn(
                      schedule.map((item) => item.closingDate),
                    ),
              )
              ..limit(1))
            .getSingleOrNull();
    if (paidStatements != null) {
      throw StateError('A compra pertence a uma fatura já paga.');
    }
    final installments = db.cardInstallments;
    final purchases = db.cardPurchases;
    final used = installments.amountCents.sum();
    final query =
        db.selectOnly(installments).join([
            innerJoin(
              purchases,
              purchases.id.equalsExp(installments.purchaseId),
            ),
          ])
          ..addColumns([used])
          ..where(
            purchases.cardId.equals(cardId) & installments.paymentId.isNull(),
          );
    final usedCents = (await query.getSingle()).read(used) ?? 0;
    if (BigInt.from(usedCents) + BigInt.from(amountCents) >
        BigInt.from(card.limitCents)) {
      throw StateError('A compra ultrapassa o limite disponível.');
    }
    final id = await db
        .into(purchases)
        .insert(
          CardPurchasesCompanion.insert(
            cardId: cardId,
            description: name,
            amountCents: amountCents,
            purchaseDate: calendarDate(date),
            categoryId: Value(categoryId),
            installmentCount: count,
          ),
        );
    for (final item in schedule) {
      await db
          .into(installments)
          .insert(
            CardInstallmentsCompanion.insert(
              purchaseId: id,
              number: item.number,
              amountCents: item.amountCents,
              closingDate: item.closingDate,
              dueDate: item.dueDate,
            ),
          );
    }
    return id;
  });

  Future<void> payStatement({
    required int cardId,
    required DateTime closingDate,
    required int accountId,
  }) => db.transaction(() async {
    final account = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null || !account.isActive) {
      throw StateError('Selecione uma conta ativa.');
    }
    final installments = db.cardInstallments;
    final purchases = db.cardPurchases;
    final query =
        db.select(installments).join([
          innerJoin(purchases, purchases.id.equalsExp(installments.purchaseId)),
        ])..where(
          purchases.cardId.equals(cardId) &
              installments.closingDate.equals(calendarDate(closingDate)) &
              installments.paymentId.isNull(),
        );
    final rows = (await query.get())
        .map((row) => row.readTable(installments))
        .toList();
    if (rows.isEmpty) {
      throw StateError('Esta fatura não possui parcelas pendentes.');
    }
    final amount = rows.fold<int>(0, (sum, row) => sum + row.amountCents);
    validatePositiveCents(amount);
    final balance = account.currentBalanceCents - amount;
    validateBalanceCents(balance);
    final now = DateTime.now();
    final transactionId = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'card_payment',
            amountCents: amount,
            date: now,
            accountId: accountId,
            description: const Value('Pagamento de fatura'),
          ),
        );
    final paymentId = await db
        .into(db.cardPayments)
        .insert(
          CardPaymentsCompanion.insert(
            cardId: cardId,
            closingDate: calendarDate(closingDate),
            accountId: accountId,
            transactionId: transactionId,
            amountCents: amount,
            paidAt: now,
          ),
        );
    await (db.update(installments)
          ..where((row) => row.id.isIn(rows.map((row) => row.id))))
        .write(CardInstallmentsCompanion(paymentId: Value(paymentId)));
    await (db.update(db.accounts)..where((row) => row.id.equals(accountId)))
        .write(AccountsCompanion(currentBalanceCents: Value(balance)));
  });
}
