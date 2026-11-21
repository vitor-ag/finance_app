import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

final dashboardTransactionsProvider = StreamProvider.autoDispose
    .family<List<Transaction>, DateTime>((ref, month) {
      final transactions = ref.watch(transactionRepositoryProvider);
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      return transactions.watchTransactionsInPeriod(start, end);
    });
