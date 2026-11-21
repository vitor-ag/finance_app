// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recurrenceRepositoryHash() =>
    r'67cab7e0ebfc8d891c723c835005dd56d2b0bf0f';

/// See also [recurrenceRepository].
@ProviderFor(recurrenceRepository)
final recurrenceRepositoryProvider = Provider<RecurrenceRepository>.internal(
  recurrenceRepository,
  name: r'recurrenceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recurrenceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecurrenceRepositoryRef = ProviderRef<RecurrenceRepository>;
String _$allRecurrencesHash() => r'a89eff18466cacfac4efb8a067cc460d3d499309';

/// See also [allRecurrences].
@ProviderFor(allRecurrences)
final allRecurrencesProvider =
    AutoDisposeStreamProvider<List<Recurrence>>.internal(
  allRecurrences,
  name: r'allRecurrencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allRecurrencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllRecurrencesRef = AutoDisposeStreamProviderRef<List<Recurrence>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
