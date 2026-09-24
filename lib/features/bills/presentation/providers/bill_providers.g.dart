// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$billRepositoryHash() => r'aa4ff0590b1a60639affc8a6f895927dcefd43cd';

/// See also [billRepository].
@ProviderFor(billRepository)
final billRepositoryProvider = Provider<BillRepository>.internal(
  billRepository,
  name: r'billRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BillRepositoryRef = ProviderRef<BillRepository>;
String _$allBillsHash() => r'a33915ee45a024644e6db6532b432e081d70241a';

/// See also [allBills].
@ProviderFor(allBills)
final allBillsProvider = AutoDisposeStreamProvider<List<Bill>>.internal(
  allBills,
  name: r'allBillsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allBillsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllBillsRef = AutoDisposeStreamProviderRef<List<Bill>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
