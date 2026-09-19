import 'package:drift/drift.dart';
import '../../../../data/local/database.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase db;

  AccountRepositoryImpl(this.db);

  Account _mapRow(AccountRow row) {
    return Account(
      id: row.id,
      name: row.name,
      type: row.type,
      initialBalance: row.initialBalance,
      currentBalance: row.currentBalance,
      color: row.color,
      icon: row.icon,
      isActive: row.isActive,
      createdAt: row.createdAt,
      notes: row.notes,
    );
  }

  @override
  Stream<List<Account>> watchAllAccounts() {
    return db.select(db.accounts).watch().map(
          (rows) => rows.map(_mapRow).toList(),
        );
  }

  @override
  Future<Account?> getAccountById(int id) async {
    final row = await (db.select(db.accounts)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> createAccount(Account account) {
    return db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: account.name,
            type: account.type,
            initialBalance: Value(account.initialBalance),
            currentBalance: Value(account.currentBalance),
            color: Value(account.color),
            icon: Value(account.icon),
            notes: Value(account.notes),
          ),
        );
  }

  @override
  Future<void> updateAccount(Account account) {
    return (db.update(db.accounts)
            ..where((tbl) => tbl.id.equals(account.id!)))
        .write(
        AccountsCompanion(
        name: Value(account.name),
        type: Value(account.type),
        currentBalance: Value(account.currentBalance),
        color: Value(account.color),
        icon: Value(account.icon),
        notes: Value(account.notes),
        ),
    );
    }

  @override
  Future<void> archiveAccount(int id) {
    return (db.update(db.accounts)..where((tbl) => tbl.id.equals(id)))
        .write(const AccountsCompanion(isActive: Value(false)));
  }
}