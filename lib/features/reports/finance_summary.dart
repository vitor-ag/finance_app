import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../credit_cards/presentation/credit_card_providers.dart';
import '../transactions/presentation/providers/transaction_providers.dart';

typedef Period = ({DateTime start, DateTime end});

DateTime firstOfMonth(DateTime date) => DateTime(date.year, date.month);

Period monthPeriod(DateTime date) =>
    (start: firstOfMonth(date), end: DateTime(date.year, date.month + 1));

class FinanceSummary {
  BigInt income = BigInt.zero;
  BigInt expense = BigInt.zero;
  final byCategory = <int?, BigInt>{};
  final incomeByCategory = <int?, BigInt>{};
  final categoryCounts = <int?, int>{};
  int records = 0;

  BigInt get result => income - expense;

  void add(String type, int amount, int? category) {
    final cents = BigInt.from(amount);
    if (type == 'income') {
      income += cents;
      incomeByCategory.update(
        category,
        (value) => value + cents,
        ifAbsent: () => cents,
      );
    } else if (type == 'expense') {
      expense += cents;
      byCategory.update(
        category,
        (value) => value + cents,
        ifAbsent: () => cents,
      );
      categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
    } else {
      return;
    }
    records++;
  }
}

class FinanceHistory {
  final months = <DateTime, FinanceSummary>{};
  final daily = <DateTime, FinanceSummary>{};

  void add(DateTime date, String type, int cents, int? category) {
    if (type != 'income' && type != 'expense') return;
    months
        .putIfAbsent(firstOfMonth(date), FinanceSummary.new)
        .add(type, cents, category);
    daily
        .putIfAbsent(
          DateTime(date.year, date.month, date.day),
          FinanceSummary.new,
        )
        .add(type, cents, category);
  }

  FinanceSummary summarize(Period period) {
    final summary = FinanceSummary();
    for (final MapEntry(key: day, value: item) in daily.entries) {
      if (day.isBefore(period.start) || !day.isBefore(period.end)) continue;
      summary.income += item.income;
      summary.expense += item.expense;
      summary.records += item.records;
      for (final category in item.byCategory.entries) {
        summary.byCategory.update(
          category.key,
          (value) => value + category.value,
          ifAbsent: () => category.value,
        );
      }
      for (final category in item.incomeByCategory.entries) {
        summary.incomeByCategory.update(
          category.key,
          (value) => value + category.value,
          ifAbsent: () => category.value,
        );
      }
      for (final category in item.categoryCounts.entries) {
        summary.categoryCounts.update(
          category.key,
          (value) => value + category.value,
          ifAbsent: () => category.value,
        );
      }
    }
    return summary;
  }
}

final financeHistoryProvider = Provider.autoDispose<AsyncValue<FinanceHistory>>(
  (ref) {
    final entries = ref.watch(allTransactionsProvider);
    final purchases = ref.watch(cardPurchasesProvider);
    return entries
        .whenData((_) => null)
        .when(
          loading: () => const AsyncLoading(),
          error: AsyncError.new,
          data: (_) => purchases.whenData((cardPurchases) {
            final history = FinanceHistory();
            for (final entry in entries.requireValue) {
              if (entry.status == 'paid') {
                history.add(
                  entry.date,
                  entry.type,
                  entry.amountCents,
                  entry.categoryId,
                );
              }
            }
            for (final item in cardPurchases) {
              history.add(
                item.purchaseDate,
                'expense',
                item.amountCents,
                item.categoryId,
              );
            }
            return history;
          }),
        );
  },
);
