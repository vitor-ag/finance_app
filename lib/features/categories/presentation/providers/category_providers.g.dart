// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRepositoryHash() =>
    r'120279993c2e656613dad324f53485fe8d1f3312';

/// See also [categoryRepository].
@ProviderFor(categoryRepository)
final categoryRepositoryProvider = Provider<CategoryRepository>.internal(
  categoryRepository,
  name: r'categoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CategoryRepositoryRef = ProviderRef<CategoryRepository>;
String _$allCategoriesHash() => r'ca7703ad9f1cae53c435349f81f3ad61c7d783bb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [allCategories].
@ProviderFor(allCategories)
const allCategoriesProvider = AllCategoriesFamily();

/// See also [allCategories].
class AllCategoriesFamily extends Family<AsyncValue<List<Category>>> {
  /// See also [allCategories].
  const AllCategoriesFamily();

  /// See also [allCategories].
  AllCategoriesProvider call({
    String? type,
  }) {
    return AllCategoriesProvider(
      type: type,
    );
  }

  @override
  AllCategoriesProvider getProviderOverride(
    covariant AllCategoriesProvider provider,
  ) {
    return call(
      type: provider.type,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'allCategoriesProvider';
}

/// See also [allCategories].
class AllCategoriesProvider extends AutoDisposeStreamProvider<List<Category>> {
  /// See also [allCategories].
  AllCategoriesProvider({
    String? type,
  }) : this._internal(
          (ref) => allCategories(
            ref as AllCategoriesRef,
            type: type,
          ),
          from: allCategoriesProvider,
          name: r'allCategoriesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$allCategoriesHash,
          dependencies: AllCategoriesFamily._dependencies,
          allTransitiveDependencies:
              AllCategoriesFamily._allTransitiveDependencies,
          type: type,
        );

  AllCategoriesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final String? type;

  @override
  Override overrideWith(
    Stream<List<Category>> Function(AllCategoriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllCategoriesProvider._internal(
        (ref) => create(ref as AllCategoriesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Category>> createElement() {
    return _AllCategoriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllCategoriesProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AllCategoriesRef on AutoDisposeStreamProviderRef<List<Category>> {
  /// The parameter `type` of this provider.
  String? get type;
}

class _AllCategoriesProviderElement
    extends AutoDisposeStreamProviderElement<List<Category>>
    with AllCategoriesRef {
  _AllCategoriesProviderElement(super.provider);

  @override
  String? get type => (origin as AllCategoriesProvider).type;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
