import '../entities/account.dart';

/// Abstract contract for account persistence.
/// The domain layer only knows this interface, never the Drift implementation.
abstract class AccountRepository {
  Stream<List<Account>> watchAllAccounts();
  Future<Account?> getAccountById(int id);
  Future<int> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> archiveAccount(int id);
}