import 'package:drift/drift.dart';

import '../../../core/calendar.dart';
import '../../../core/money.dart';
import '../../../data/local/database.dart';
import '../../accounts/domain/entities/account.dart';
import '../../transactions/data/repositories/transaction_repository_impl.dart';
import '../domain/investment_portfolio.dart';

class InvestmentRepository {
  InvestmentRepository(this.db) : _ledger = TransactionRepositoryImpl(db);

  final AppDatabase db;
  final TransactionRepositoryImpl _ledger;

  Stream<InvestmentPortfolio> watchPortfolio() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.investments, db.investmentMovements, db.accounts},
      )
      .watch()
      .asyncMap(
        (_) => db.transaction(() async {
          final accounts =
              await (db.select(db.accounts)
                    ..where((row) => row.isActive.equals(true))
                    ..orderBy([(row) => OrderingTerm.asc(row.name)]))
                  .get();
          final investments =
              await (db.select(db.investments)..orderBy([
                    (row) => OrderingTerm.desc(row.isActive),
                    (row) => OrderingTerm.asc(row.name),
                  ]))
                  .get();
          final movements = await (db.select(
            db.investmentMovements,
          )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
          final byInvestment = <int, List<InvestmentMovementRow>>{};
          for (final movement in movements) {
            byInvestment
                .putIfAbsent(movement.investmentId, () => [])
                .add(movement);
          }
          return InvestmentPortfolio(
            [
              for (final position in investments)
                if (byInvestment[position.id] case final history?)
                  InvestmentPosition(position, history),
            ],
            accounts.where((row) => row.type != investmentAccountType).toList(),
            accounts.where((row) => row.type == investmentAccountType).toList(),
          );
        }),
      );

  Future<int> create({
    required String name,
    required String institution,
    required String kind,
    required DateTime date,
    required int cents,
    required int redeemable,
  }) {
    _validateDetails(name, institution, kind);
    _validatePosition(cents, redeemable);
    final day = _validateDate(date);
    return db.transaction(() async {
      final id = await db
          .into(db.investments)
          .insert(
            InvestmentsCompanion.insert(
              name: name.trim(),
              institution: institution.trim(),
              kind: kind.trim(),
            ),
          );
      await _record(
        id,
        InvestmentMovementKind.opening,
        day,
        amount: cents,
        value: cents,
        redeemable: redeemable,
      );
      return id;
    });
  }

  Future<void> updateDetails(
    int id, {
    required String name,
    required String institution,
    required String kind,
  }) async {
    _validateDetails(name, institution, kind);
    await (db.update(db.investments)..where((row) => row.id.equals(id))).write(
      InvestmentsCompanion(
        name: Value(name.trim()),
        institution: Value(institution.trim()),
        kind: Value(kind.trim()),
      ),
    );
  }

  Future<void> archive(int id) => db.transaction(() async {
    await _requireActive(id);
    final latest = await _latest(id);
    if (latest.valueCents != 0) {
      throw StateError('Registre o resgate ou atualize a posição para zero.');
    }
    await (db.update(db.investments)..where((row) => row.id.equals(id))).write(
      const InvestmentsCompanion(isActive: Value(false)),
    );
  });

  Future<void> reactivate(int id) async {
    await (db.update(db.investments)..where((row) => row.id.equals(id))).write(
      const InvestmentsCompanion(isActive: Value(true)),
    );
  }

  Future<void> recordValuation(
    int id, {
    required DateTime date,
    required int value,
    required int redeemable,
    int? expectedMovementId,
  }) => db.transaction(() async {
    await _requireActive(id);
    final latest = await _latest(id);
    _checkLatest(latest, expectedMovementId);
    final day = _validateDate(date, previous: latest);
    _validatePosition(value, redeemable);
    await _record(
      id,
      InvestmentMovementKind.valuation,
      day,
      amount: value - latest.valueCents,
      value: value,
      redeemable: redeemable,
    );
  });

  Future<void> moveCash(
    int id, {
    required InvestmentMovementKind kind,
    required int accountId,
    required DateTime date,
    required int gross,
    required int cash,
    required int redeemable,
    int? expectedMovementId,
  }) => db.transaction(() async {
    final investment = await _requireActive(id);
    final latest = await _latest(id);
    _checkLatest(latest, expectedMovementId);
    final day = _validateDate(date, previous: latest);
    validatePositiveCents(gross);
    final contribution = kind == InvestmentMovementKind.contribution;
    final redemption = kind == InvestmentMovementKind.redemption;
    if ((!contribution && !redemption) ||
        cash < 0 ||
        cash > gross ||
        (contribution && cash != gross)) {
      throw StateError(
        'Confira o valor líquido informado para a movimentação.',
      );
    }
    final value = latest.valueCents + (contribution ? gross : -gross);
    _validatePosition(value, redeemable);
    final ledgerId = cash == 0
        ? null
        : await _ledger.recordInvestmentMovement(
            accountId: accountId,
            cents: cash,
            contribution: contribution,
            date: day,
            description:
                '${contribution ? 'Aporte' : 'Resgate'} em ${investment.name}',
          );
    await _record(
      id,
      kind,
      day,
      amount: gross,
      cash: cash,
      value: value,
      redeemable: redeemable,
      transactionId: ledgerId,
    );
  });

  Future<void> _record(
    int id,
    InvestmentMovementKind kind,
    DateTime date, {
    required int amount,
    required int value,
    required int redeemable,
    int cash = 0,
    int? transactionId,
  }) async {
    await db
        .into(db.investmentMovements)
        .insert(
          InvestmentMovementsCompanion.insert(
            investmentId: id,
            kind: kind.name,
            date: date,
            amountCents: amount,
            cashCents: Value(cash),
            valueCents: value,
            redeemableCents: redeemable,
            transactionId: Value(transactionId),
          ),
        );
  }

  Future<InvestmentRow> _requireActive(int id) async {
    final item =
        await (db.select(db.investments)
              ..where((row) => row.id.equals(id) & row.isActive.equals(true)))
            .getSingleOrNull();
    if (item == null) throw StateError('Selecione um investimento ativo.');
    return item;
  }

  Future<InvestmentMovementRow> _latest(int id) =>
      (db.select(db.investmentMovements)
            ..where((row) => row.investmentId.equals(id))
            ..orderBy([(row) => OrderingTerm.desc(row.id)])
            ..limit(1))
          .getSingle();

  void _checkLatest(InvestmentMovementRow latest, int? expectedId) {
    if (expectedId != null && expectedId != latest.id) {
      throw StateError(
        'A posição mudou. Reabra o formulário com os valores atuais.',
      );
    }
  }

  DateTime _validateDate(DateTime date, {InvestmentMovementRow? previous}) {
    final day = calendarDate(date);
    if (day.isAfter(calendarDate(DateTime.now())) ||
        (previous != null && day.isBefore(calendarDate(previous.date)))) {
      throw StateError('Informe uma data entre o último registro e hoje.');
    }
    return day;
  }

  void _validatePosition(int value, int redeemable) {
    validateBalanceCents(value);
    if (value < 0 || redeemable < 0 || redeemable > value) {
      throw StateError(
        'O valor resgatável deve ficar entre zero e o valor da posição.',
      );
    }
  }

  void _validateDetails(String name, String institution, String kind) {
    if (name.trim().isEmpty ||
        name.trim().length > 80 ||
        institution.trim().length > 80 ||
        kind.trim().isEmpty ||
        kind.trim().length > 50) {
      throw StateError('Informe um nome, instituição e tipo válidos.');
    }
  }
}
