import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/backup/data/backup_snapshot.dart';
import 'package:finance_app/features/investments/data/investment_repository.dart';
import 'package:finance_app/features/investments/domain/investment_portfolio.dart';
import 'package:finance_app/features/reports/finance_summary.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late InvestmentRepository investments;
  late int account, position;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    investments = InvestmentRepository(db);
    account = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Banco',
            type: 'checking',
            initialBalanceCents: const Value(200000),
            currentBalanceCents: const Value(200000),
          ),
        );
    position = await investments.create(
      name: 'Tesouro',
      institution: 'Corretora',
      kind: 'Renda fixa',
      date: DateTime(2025, 3, 27),
      cents: 100000,
      redeemable: 80000,
    );
  });
  tearDown(() => db.close());

  test(
    'keeps cash, redeemable value and investment performance separate',
    () async {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Conta de investimento antiga',
              type: 'investment',
              currentBalanceCents: const Value(30000),
            ),
          );
      expect(
        (await investments.watchPortfolio().first).cash,
        BigInt.from(200000),
      );
      await investments.moveCash(
        position,
        kind: InvestmentMovementKind.contribution,
        accountId: account,
        date: DateTime(2025, 4, 2),
        gross: 30000,
        cash: 30000,
        redeemable: 85000,
      );
      await investments.recordValuation(
        position,
        date: DateTime(2025, 4, 5),
        value: 140000,
        redeemable: 100000,
      );
      await investments.moveCash(
        position,
        kind: InvestmentMovementKind.redemption,
        accountId: account,
        date: DateTime(2025, 4, 6),
        gross: 20000,
        cash: 18000,
        redeemable: 82000,
      );
      final portfolio = await investments.watchPortfolio().first;
      expect(portfolio.cash, BigInt.from(188000));
      expect(portfolio.value, BigInt.from(120000));
      expect(portfolio.redeemable, BigInt.from(82000));
      expect(portfolio.legacyValue, BigInt.from(30000));
      expect(portfolio.positions.single.needsReview(DateTime(2025, 5)), isTrue);
      expect(
        portfolio.positions.single.needsReview(DateTime(2025, 4, 30)),
        isFalse,
      );

      final march = portfolio.summarize(DateTime(2025, 3));
      expect(march.imported, BigInt.from(100000));
      expect(march.variation, BigInt.zero);
      final april = portfolio.summarize(DateTime(2025, 4));
      expect(april.opening, BigInt.from(100000));
      expect(april.closing, BigInt.from(120000));
      expect(april.contributed, BigInt.from(30000));
      expect(april.redeemed, BigInt.from(20000));
      expect(april.credited, BigInt.from(18000));
      expect(april.netResult, BigInt.from(8000));

      final ledger = TransactionRepositoryImpl(db);
      final entries = await ledger.watchAllTransactions().first;
      expect(entries.map((item) => item.type), [
        'investment_redemption',
        'investment_contribution',
      ]);
      final summary = FinanceSummary();
      for (final item in entries) {
        summary.add(item.type, item.amountCents, item.categoryId);
        await expectLater(ledger.deleteTransaction(item.id!), throwsStateError);
        await expectLater(
          ledger.updateTransaction(item.copyWith(type: 'income')),
          throwsStateError,
        );
      }
      expect(summary.records, 0);
    },
  );

  test(
    'rejects stale and invalid movements without partially changing cash',
    () async {
      final opening =
          (await investments.watchPortfolio().first).positions.single.latest;
      await investments.recordValuation(
        position,
        date: DateTime(2025, 4, 1),
        value: 96000,
        redeemable: 70000,
        expectedMovementId: opening.id,
      );
      await expectLater(
        investments.moveCash(
          position,
          kind: InvestmentMovementKind.contribution,
          accountId: account,
          date: DateTime(2025, 4, 1),
          gross: 10000,
          cash: 10000,
          redeemable: 70000,
          expectedMovementId: opening.id,
        ),
        throwsStateError,
      );
      await expectLater(
        investments.moveCash(
          position,
          kind: InvestmentMovementKind.redemption,
          accountId: account,
          date: DateTime(2025, 4, 2),
          gross: 97000,
          cash: 80000,
          redeemable: 0,
        ),
        throwsStateError,
      );
      await expectLater(investments.archive(position), throwsStateError);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(
        (await investments.watchPortfolio().first).cash,
        BigInt.from(200000),
      );
      expect(
        (await investments.watchPortfolio().first)
            .summarize(DateTime(2025, 4))
            .variation,
        BigInt.from(-4000),
      );
      await investments.moveCash(
        position,
        kind: InvestmentMovementKind.redemption,
        accountId: account,
        date: DateTime(2025, 4, 3),
        gross: 96000,
        cash: 95000,
        redeemable: 0,
      );
      await investments.archive(position);
      final portfolio = await investments.watchPortfolio().first;
      expect(portfolio.positions.single.investment.isActive, isFalse);
      expect(portfolio.cash, BigInt.from(295000));
    },
  );

  test(
    'round-trips investment movements and still restores version 8 backups',
    () async {
      await investments.moveCash(
        position,
        kind: InvestmentMovementKind.contribution,
        accountId: account,
        date: DateTime(2025, 4, 2),
        gross: 10000,
        cash: 10000,
        redeemable: 90000,
      );
      final backup = BackupDatabase(db);
      final snapshot = await backup.capture();
      final other = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(other.close);
      final restore = BackupDatabase(other);
      expect(
        await restore.restore(
          snapshot: restore.decode(snapshot.encode(), backup.schemaVersion),
          expectedDigest: await (await restore.capture()).digest(),
        ),
        isTrue,
      );
      final restored = await InvestmentRepository(other).watchPortfolio().first;
      expect(restored.cash, BigInt.from(190000));
      expect(restored.value, BigInt.from(110000));
      expect(restored.positions.single.latest.transactionId, isNotNull);

      final old = jsonDecode(utf8.decode(snapshot.encode())) as List;
      final oldRows = old.first as Map;
      oldRows.remove('investments');
      oldRows.remove('investment_movements');
      // The v8 ledger had no investment entries.
      oldRows['transactions'] = [];
      (old.last as Map).remove('investments');
      (old.last as Map).remove('investment_movements');
      final oldBytes = utf8.encode(jsonEncode(old));
      final oldDigest = base64UrlEncode((await Sha256().hash(oldBytes)).bytes);
      final oldSnapshot = restore.decode(oldBytes, 8);
      expect(await oldSnapshot.matchesBeforeInvestments(oldDigest), isTrue);
      expect(await snapshot.matchesBeforeInvestments(oldDigest), isFalse);
      expect(
        await restore.restore(
          snapshot: oldSnapshot,
          expectedDigest: await (await restore.capture()).digest(),
        ),
        isTrue,
      );
      expect(
        (await InvestmentRepository(other).watchPortfolio().first).positions,
        isEmpty,
      );
    },
  );
}
