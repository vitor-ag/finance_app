import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers/database_provider.dart';
import '../../data/local/database.dart';
import '../reports/finance_summary.dart';

final budgetRepositoryProvider = Provider(
  (ref) => BudgetRepository(ref.watch(databaseProvider)),
);
final budgetsProvider = StreamProvider.autoDispose<List<BudgetRow>>(
  (ref) => ref.watch(budgetRepositoryProvider).watch(),
);

class BudgetRepository {
  BudgetRepository(this.db);
  final AppDatabase db;

  Stream<List<BudgetRow>> watch() => (db.select(
    db.budgets,
  )..orderBy([(table) => OrderingTerm.asc(table.month)])).watch();

  Future<void> save({
    required int category,
    required DateTime month,
    required int limit,
    required bool carryOver,
  }) {
    validatePositiveCents(limit);
    return db.transaction(() async {
      final item = await (db.select(
        db.categories,
      )..where((row) => row.id.equals(category))).getSingleOrNull();
      if (item == null || item.type != 'expense' || !item.isActive) {
        throw StateError('Selecione uma categoria de despesa ativa.');
      }
      await db
          .into(db.budgets)
          .insertOnConflictUpdate(
            BudgetsCompanion.insert(
              categoryId: category,
              month: firstOfMonth(month),
              limitCents: limit,
              carryOver: Value(carryOver),
            ),
          );
    });
  }

  Future<void> remove(BudgetRow row) =>
      (db.delete(db.budgets)..where(
            (table) =>
                table.categoryId.equals(row.categoryId) &
                table.month.equals(row.month),
          ))
          .go();
}

class BudgetProgress {
  BudgetProgress({required this.row, required this.limit, required this.spent});
  final BudgetRow row;
  final BigInt limit, spent;
  BigInt get remaining => limit - spent;
  double get ratio => spent / limit;

  static List<BudgetProgress> forMonth(
    List<BudgetRow> rows,
    DateTime date,
    FinanceHistory history,
  ) {
    final target = firstOfMonth(date);
    final previous = <int, BudgetProgress>{};
    final results = <BudgetProgress>[];
    for (final row in rows) {
      if (row.month.isAfter(target)) break;
      final prior = previous[row.categoryId];
      final carry =
          prior != null &&
              prior.row.carryOver &&
              prior.remaining > BigInt.zero &&
              DateTime(prior.row.month.year, prior.row.month.month + 1) ==
                  row.month
          ? prior.remaining
          : BigInt.zero;
      final progress = BudgetProgress(
        row: row,
        limit: BigInt.from(row.limitCents) + carry,
        spent:
            history.months[row.month]?.byCategory[row.categoryId] ??
            BigInt.zero,
      );
      previous[row.categoryId] = progress;
      if (row.month == target) results.add(progress);
    }
    return results;
  }
}
