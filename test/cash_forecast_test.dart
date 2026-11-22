import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:finance_app/features/credit_cards/data/credit_card_repository.dart';
import 'package:finance_app/features/forecast/data/cash_forecast_repository.dart';
import 'package:finance_app/features/forecast/domain/cash_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects unpaid statements once and reacts to settlements', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final bank = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Banco',
            type: 'checking',
            currentBalanceCents: const Value(180000),
          ),
        );
    final wallet = await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Arquivada',
            type: 'checking',
            isActive: const Value(false),
            currentBalanceCents: const Value(90000),
          ),
        );
    final cards = CreditCardRepository(db);
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Investimento legado',
            type: 'investment',
            currentBalanceCents: const Value(50000),
          ),
        );
    final card = await cards.createCard(
      name: 'Cartão',
      limitCents: 200000,
      closingDay: 20,
      dueDay: 4,
    );
    for (final cents in [80000, 40000]) {
      await cards.createPurchase(
        cardId: card,
        description: 'Compra',
        amountCents: cents,
        count: 1,
        date: DateTime(2026, 2, 10),
      );
    }
    await cards.archiveCard(card);
    final rent = await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            name: 'Aluguel',
            amountCents: 90000,
            dueDate: DateTime(2026, 3, 6),
            billType: 'fixed',
          ),
        );
    for (final (type, cents, date, status, deleted, destination) in [
      ('transfer', 5000, DateTime(2026, 3, 3), 'pending', false, wallet),
      ('income', 400000, DateTime(2026, 3, 10), 'pending', false, null),
      ('expense', 70000, DateTime(2026, 3, 5), 'paid', false, null),
      ('expense', 50000, DateTime(2026, 3, 5), 'cancelled', false, null),
      ('expense', 90000, DateTime(2026, 3, 5), 'pending', true, null),
      ('expense', 10000, DateTime(2026, 3, 29), 'pending', false, null),
    ]) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: type,
              amountCents: cents,
              date: date,
              status: Value(status),
              accountId: bank,
              deletedAt: Value(deleted ? date : null),
              destinationAccountId: Value(destination),
            ),
          );
    }

    final forecast = StreamIterator(
      CashForecastRepository(db).watch(DateTime(2026, 2, 27)),
    );
    addTearDown(forecast.cancel);
    expect(await forecast.moveNext(), isTrue);
    final before = forecast.current;
    expect(before.accounts.keys, unorderedEquals([bank, wallet]));
    final total = before.forAccount();
    expect(total.opening, BigInt.from(180000));
    expect(total.income, BigInt.from(400000));
    expect(total.expense, BigInt.from(210000));
    expect(total.lowestDay.date, DateTime(2026, 3, 6));
    expect(total.lowestDay.closing, BigInt.from(-30000));
    expect(total.firstNegativeDay?.date, total.lowestDay.date);
    expect(total.days.last.date, DateTime(2026, 3, 28));
    expect(total.days.last.closing, BigInt.from(370000));
    expect(before.forAccount(bank).days.last.closing, BigInt.from(575000));
    expect(before.forAccount(wallet).days.last.closing, BigInt.from(5000));
    final statement = before.events
        .where((event) => event.source == CashEventSource.statement)
        .single;
    expect(statement.date, DateTime(2026, 3, 4));
    expect(statement.delta, BigInt.from(-120000));

    await cards.payStatement(
      cardId: card,
      closingDate: DateTime(2026, 2, 20),
      accountId: bank,
    );
    expect(await forecast.moveNext(), isTrue);
    final afterCard = forecast.current.forAccount();
    expect(afterCard.opening, BigInt.from(60000));
    expect(afterCard.expense, BigInt.from(90000));
    expect(afterCard.days.last.closing, total.days.last.closing);

    await BillRepositoryImpl(db).markAsPaid(rent, paymentAccountId: bank);
    expect(await forecast.moveNext(), isTrue);
    final afterRent = forecast.current.forAccount();
    expect(afterRent.opening, BigInt.from(-30000));
    expect(afterRent.expense, BigInt.zero);
    expect(afterRent.days.last.closing, total.days.last.closing);
  });

  test(
    'previews recurrences without writing or duplicating saved occurrences',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final account = await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'Conta', type: 'checking'));
      final recurrenceId = await db
          .into(db.recurrences)
          .insert(
            RecurrencesCompanion.insert(
              name: 'Freela',
              type: 'income',
              amountCents: 10000,
              accountId: account,
              frequency: 'weekly',
              startDate: DateTime(2026, 1, 29),
              nextOccurrenceDate: DateTime(2026, 2, 5),
              generatedCount: const Value(1),
              maxOccurrences: const Value(3),
              endDate: Value(DateTime(2026, 2, 12)),
            ),
          );
      await db
          .into(db.recurrences)
          .insert(
            RecurrencesCompanion.insert(
              name: 'Pausada',
              type: 'expense',
              amountCents: 1000,
              accountId: account,
              frequency: 'monthly',
              startDate: DateTime(2026, 2, 2),
              nextOccurrenceDate: DateTime(2026, 2, 2),
              status: const Value('paused'),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'income',
              amountCents: 10000,
              date: DateTime(2026, 1, 29),
              description: const Value('Freela já gerado'),
              status: const Value('pending'),
              accountId: account,
              recurrenceId: Value(recurrenceId),
            ),
          );
      final billId = await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              name: 'Mensalidade',
              amountCents: 1000,
              dueDate: DateTime(2025, 12, 31),
              billType: 'recurring',
            ),
          );
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              name: 'Mensalidade',
              amountCents: 1000,
              dueDate: DateTime(2026, 1, 31),
              billType: 'recurring',
              previousBillId: Value(billId),
              repeatDay: const Value(31),
            ),
          );

      final result = await CashForecastRepository(db)
          .watch(DateTime(2026, 1, 31))
          .first;
      final total = result.forAccount();
      expect(
        total.days.first.movements.map((movement) => movement.event.date),
        [DateTime(2025, 12, 31), DateTime(2026, 1, 29), DateTime(2026, 1, 31)],
      );
      expect(total.days.first.closing, BigInt.from(8000));
      expect(total.income, BigInt.from(30000));
      expect(total.expense, BigInt.from(3000));
      expect(
        result.events
            .where((event) => event.source == CashEventSource.recurrence)
            .map((event) => event.date),
        [DateTime(2026, 2, 5), DateTime(2026, 2, 12)],
      );
      expect(
        result.events
            .singleWhere(
              (event) => event.source == CashEventSource.repeatingBill,
            )
            .date,
        DateTime(2026, 2, 28),
      );
      expect(await db.select(db.bills).get(), hasLength(2));
      expect(await db.select(db.transactions).get(), hasLength(1));
    },
  );
}
