// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accountRepositoryHash() => r'cc19d7cb8ba9bdfa57efe4d9e7407b72a847f6dc';

/// See also [accountRepository].
@ProviderFor(accountRepository)
final accountRepositoryProvider = Provider<AccountRepository>.internal(
  accountRepository,
  name: r'accountRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AccountRepositoryRef = ProviderRef<AccountRepository>;
String _$allAccountsHash() => r'f84d3110e90f0f140174f4d5852f0971cdbe9377';

/// See also [allAccounts].
@ProviderFor(allAccounts)
final allAccountsProvider = AutoDisposeStreamProvider<List<Account>>.internal(
  allAccounts,
  name: r'allAccountsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allAccountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllAccountsRef = AutoDisposeStreamProviderRef<List<Account>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
