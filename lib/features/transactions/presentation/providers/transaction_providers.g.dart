// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionRepositoryHash() =>
    r'6725eaf86fba5efbdbcb7fde8787a7fdd248c37d';

/// See also [transactionRepository].
@ProviderFor(transactionRepository)
final transactionRepositoryProvider = Provider<TransactionRepository>.internal(
  transactionRepository,
  name: r'transactionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TransactionRepositoryRef = ProviderRef<TransactionRepository>;
String _$allTransactionsHash() => r'f9a675106b5ff21701295bde7338095b25970ccd';

/// See also [allTransactions].
@ProviderFor(allTransactions)
final allTransactionsProvider =
    AutoDisposeStreamProvider<List<Transaction>>.internal(
  allTransactions,
  name: r'allTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllTransactionsRef = AutoDisposeStreamProviderRef<List<Transaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
