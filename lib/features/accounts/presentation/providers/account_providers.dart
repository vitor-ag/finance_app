import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
AccountRepository accountRepository(AccountRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepositoryImpl(db);
}

@riverpod
Stream<List<Account>> allAccounts(AllAccountsRef ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAllAccounts();
}