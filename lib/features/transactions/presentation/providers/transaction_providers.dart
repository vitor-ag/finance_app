import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'transaction_providers.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
}

@riverpod
Stream<List<Transaction>> allTransactions(AllTransactionsRef ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAllTransactions();
}