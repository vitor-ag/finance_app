// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _initialBalanceCentsMeta =
      const VerificationMeta('initialBalanceCents');
  @override
  late final GeneratedColumn<int> initialBalanceCents = GeneratedColumn<int>(
      'initial_balance_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentBalanceCentsMeta =
      const VerificationMeta('currentBalanceCents');
  @override
  late final GeneratedColumn<int> currentBalanceCents = GeneratedColumn<int>(
      'current_balance_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        initialBalanceCents,
        currentBalanceCents,
        color,
        icon,
        isActive,
        createdAt,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('initial_balance_cents')) {
      context.handle(
          _initialBalanceCentsMeta,
          initialBalanceCents.isAcceptableOrUnknown(
              data['initial_balance_cents']!, _initialBalanceCentsMeta));
    }
    if (data.containsKey('current_balance_cents')) {
      context.handle(
          _currentBalanceCentsMeta,
          currentBalanceCents.isAcceptableOrUnknown(
              data['current_balance_cents']!, _currentBalanceCentsMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      initialBalanceCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}initial_balance_cents'])!,
      currentBalanceCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_balance_cents'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;
  final String name;
  final String type;
  final int initialBalanceCents;
  final int currentBalanceCents;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;
  const AccountRow(
      {required this.id,
      required this.name,
      required this.type,
      required this.initialBalanceCents,
      required this.currentBalanceCents,
      this.color,
      this.icon,
      required this.isActive,
      required this.createdAt,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['initial_balance_cents'] = Variable<int>(initialBalanceCents);
    map['current_balance_cents'] = Variable<int>(currentBalanceCents);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      initialBalanceCents: Value(initialBalanceCents),
      currentBalanceCents: Value(currentBalanceCents),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory AccountRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      initialBalanceCents:
          serializer.fromJson<int>(json['initialBalanceCents']),
      currentBalanceCents:
          serializer.fromJson<int>(json['currentBalanceCents']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'initialBalanceCents': serializer.toJson<int>(initialBalanceCents),
      'currentBalanceCents': serializer.toJson<int>(currentBalanceCents),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AccountRow copyWith(
          {int? id,
          String? name,
          String? type,
          int? initialBalanceCents,
          int? currentBalanceCents,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          Value<String?> notes = const Value.absent()}) =>
      AccountRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalanceCents: initialBalanceCents ?? this.initialBalanceCents,
        currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        notes: notes.present ? notes.value : this.notes,
      );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      initialBalanceCents: data.initialBalanceCents.present
          ? data.initialBalanceCents.value
          : this.initialBalanceCents,
      currentBalanceCents: data.currentBalanceCents.present
          ? data.currentBalanceCents.value
          : this.currentBalanceCents,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalanceCents: $initialBalanceCents, ')
          ..write('currentBalanceCents: $currentBalanceCents, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, initialBalanceCents,
      currentBalanceCents, color, icon, isActive, createdAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.initialBalanceCents == this.initialBalanceCents &&
          other.currentBalanceCents == this.currentBalanceCents &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> initialBalanceCents;
  final Value<int> currentBalanceCents;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<String?> notes;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.initialBalanceCents = const Value.absent(),
    this.currentBalanceCents = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.initialBalanceCents = const Value.absent(),
    this.currentBalanceCents = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? initialBalanceCents,
    Expression<int>? currentBalanceCents,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (initialBalanceCents != null)
        'initial_balance_cents': initialBalanceCents,
      if (currentBalanceCents != null)
        'current_balance_cents': currentBalanceCents,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (notes != null) 'notes': notes,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? type,
      Value<int>? initialBalanceCents,
      Value<int>? currentBalanceCents,
      Value<String?>? color,
      Value<String?>? icon,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<String?>? notes}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalanceCents: initialBalanceCents ?? this.initialBalanceCents,
      currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (initialBalanceCents.present) {
      map['initial_balance_cents'] = Variable<int>(initialBalanceCents.value);
    }
    if (currentBalanceCents.present) {
      map['current_balance_cents'] = Variable<int>(currentBalanceCents.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalanceCents: $initialBalanceCents, ')
          ..write('currentBalanceCents: $currentBalanceCents, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, parentId, color, icon, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final String type;
  final int? parentId;
  final String? color;
  final String? icon;
  final bool isActive;
  const CategoryRow(
      {required this.id,
      required this.name,
      required this.type,
      this.parentId,
      this.color,
      this.icon,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isActive: Value(isActive),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'parentId': serializer.toJson<int?>(parentId),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CategoryRow copyWith(
          {int? id,
          String? name,
          String? type,
          Value<int?> parentId = const Value.absent(),
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          bool? isActive}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        parentId: parentId.present ? parentId.value : this.parentId,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        isActive: isActive ?? this.isActive,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, parentId, color, icon, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.parentId == this.parentId &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isActive == this.isActive);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int?> parentId;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<bool> isActive;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isActive = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? parentId,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (parentId != null) 'parent_id': parentId,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isActive != null) 'is_active': isActive,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? type,
      Value<int?>? parentId,
      Value<String?>? color,
      Value<String?>? icon,
      Value<bool>? isActive}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, RecurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 80),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<int> destinationAccountId = GeneratedColumn<int>(
      'destination_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weekdayMeta =
      const VerificationMeta('weekday');
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
      'weekday', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _maxOccurrencesMeta =
      const VerificationMeta('maxOccurrences');
  @override
  late final GeneratedColumn<int> maxOccurrences = GeneratedColumn<int>(
      'max_occurrences', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _generatedCountMeta =
      const VerificationMeta('generatedCount');
  @override
  late final GeneratedColumn<int> generatedCount = GeneratedColumn<int>(
      'generated_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextOccurrenceDateMeta =
      const VerificationMeta('nextOccurrenceDate');
  @override
  late final GeneratedColumn<DateTime> nextOccurrenceDate =
      GeneratedColumn<DateTime>('next_occurrence_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        amountCents,
        accountId,
        destinationAccountId,
        categoryId,
        description,
        frequency,
        dayOfMonth,
        weekday,
        startDate,
        endDate,
        maxOccurrences,
        generatedCount,
        nextOccurrenceDate,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(Insertable<RecurrenceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
          _destinationAccountIdMeta,
          destinationAccountId.isAcceptableOrUnknown(
              data['destination_account_id']!, _destinationAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    }
    if (data.containsKey('weekday')) {
      context.handle(_weekdayMeta,
          weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('max_occurrences')) {
      context.handle(
          _maxOccurrencesMeta,
          maxOccurrences.isAcceptableOrUnknown(
              data['max_occurrences']!, _maxOccurrencesMeta));
    }
    if (data.containsKey('generated_count')) {
      context.handle(
          _generatedCountMeta,
          generatedCount.isAcceptableOrUnknown(
              data['generated_count']!, _generatedCountMeta));
    }
    if (data.containsKey('next_occurrence_date')) {
      context.handle(
          _nextOccurrenceDateMeta,
          nextOccurrenceDate.isAcceptableOrUnknown(
              data['next_occurrence_date']!, _nextOccurrenceDateMeta));
    } else if (isInserting) {
      context.missing(_nextOccurrenceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      destinationAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}destination_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month']),
      weekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekday']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      maxOccurrences: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_occurrences']),
      generatedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generated_count'])!,
      nextOccurrenceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}next_occurrence_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }
}

class RecurrenceRow extends DataClass implements Insertable<RecurrenceRow> {
  final int id;
  final String name;
  final String type;
  final int amountCents;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String? description;
  final String frequency;
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int generatedCount;
  final DateTime nextOccurrenceDate;
  final String status;
  final DateTime createdAt;
  const RecurrenceRow(
      {required this.id,
      required this.name,
      required this.type,
      required this.amountCents,
      required this.accountId,
      this.destinationAccountId,
      this.categoryId,
      this.description,
      required this.frequency,
      this.dayOfMonth,
      this.weekday,
      required this.startDate,
      this.endDate,
      this.maxOccurrences,
      required this.generatedCount,
      required this.nextOccurrenceDate,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['amount_cents'] = Variable<int>(amountCents);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<int>(destinationAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || maxOccurrences != null) {
      map['max_occurrences'] = Variable<int>(maxOccurrences);
    }
    map['generated_count'] = Variable<int>(generatedCount);
    map['next_occurrence_date'] = Variable<DateTime>(nextOccurrenceDate);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      amountCents: Value(amountCents),
      accountId: Value(accountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      frequency: Value(frequency),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      maxOccurrences: maxOccurrences == null && nullToAbsent
          ? const Value.absent()
          : Value(maxOccurrences),
      generatedCount: Value(generatedCount),
      nextOccurrenceDate: Value(nextOccurrenceDate),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory RecurrenceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      accountId: serializer.fromJson<int>(json['accountId']),
      destinationAccountId:
          serializer.fromJson<int?>(json['destinationAccountId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      description: serializer.fromJson<String?>(json['description']),
      frequency: serializer.fromJson<String>(json['frequency']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      maxOccurrences: serializer.fromJson<int?>(json['maxOccurrences']),
      generatedCount: serializer.fromJson<int>(json['generatedCount']),
      nextOccurrenceDate:
          serializer.fromJson<DateTime>(json['nextOccurrenceDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'amountCents': serializer.toJson<int>(amountCents),
      'accountId': serializer.toJson<int>(accountId),
      'destinationAccountId': serializer.toJson<int?>(destinationAccountId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'description': serializer.toJson<String?>(description),
      'frequency': serializer.toJson<String>(frequency),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'weekday': serializer.toJson<int?>(weekday),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'maxOccurrences': serializer.toJson<int?>(maxOccurrences),
      'generatedCount': serializer.toJson<int>(generatedCount),
      'nextOccurrenceDate': serializer.toJson<DateTime>(nextOccurrenceDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurrenceRow copyWith(
          {int? id,
          String? name,
          String? type,
          int? amountCents,
          int? accountId,
          Value<int?> destinationAccountId = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<String?> description = const Value.absent(),
          String? frequency,
          Value<int?> dayOfMonth = const Value.absent(),
          Value<int?> weekday = const Value.absent(),
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          Value<int?> maxOccurrences = const Value.absent(),
          int? generatedCount,
          DateTime? nextOccurrenceDate,
          String? status,
          DateTime? createdAt}) =>
      RecurrenceRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        accountId: accountId ?? this.accountId,
        destinationAccountId: destinationAccountId.present
            ? destinationAccountId.value
            : this.destinationAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        description: description.present ? description.value : this.description,
        frequency: frequency ?? this.frequency,
        dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
        weekday: weekday.present ? weekday.value : this.weekday,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        maxOccurrences:
            maxOccurrences.present ? maxOccurrences.value : this.maxOccurrences,
        generatedCount: generatedCount ?? this.generatedCount,
        nextOccurrenceDate: nextOccurrenceDate ?? this.nextOccurrenceDate,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurrenceRow copyWithCompanion(RecurrencesCompanion data) {
    return RecurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      description:
          data.description.present ? data.description.value : this.description,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      maxOccurrences: data.maxOccurrences.present
          ? data.maxOccurrences.value
          : this.maxOccurrences,
      generatedCount: data.generatedCount.present
          ? data.generatedCount.value
          : this.generatedCount,
      nextOccurrenceDate: data.nextOccurrenceDate.present
          ? data.nextOccurrenceDate.value
          : this.nextOccurrenceDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('maxOccurrences: $maxOccurrences, ')
          ..write('generatedCount: $generatedCount, ')
          ..write('nextOccurrenceDate: $nextOccurrenceDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      type,
      amountCents,
      accountId,
      destinationAccountId,
      categoryId,
      description,
      frequency,
      dayOfMonth,
      weekday,
      startDate,
      endDate,
      maxOccurrences,
      generatedCount,
      nextOccurrenceDate,
      status,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.amountCents == this.amountCents &&
          other.accountId == this.accountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.frequency == this.frequency &&
          other.dayOfMonth == this.dayOfMonth &&
          other.weekday == this.weekday &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.maxOccurrences == this.maxOccurrences &&
          other.generatedCount == this.generatedCount &&
          other.nextOccurrenceDate == this.nextOccurrenceDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class RecurrencesCompanion extends UpdateCompanion<RecurrenceRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> amountCents;
  final Value<int> accountId;
  final Value<int?> destinationAccountId;
  final Value<int?> categoryId;
  final Value<String?> description;
  final Value<String> frequency;
  final Value<int?> dayOfMonth;
  final Value<int?> weekday;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> maxOccurrences;
  final Value<int> generatedCount;
  final Value<DateTime> nextOccurrenceDate;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.accountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.maxOccurrences = const Value.absent(),
    this.generatedCount = const Value.absent(),
    this.nextOccurrenceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required int amountCents,
    required int accountId,
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    required String frequency,
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.maxOccurrences = const Value.absent(),
    this.generatedCount = const Value.absent(),
    required DateTime nextOccurrenceDate,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        amountCents = Value(amountCents),
        accountId = Value(accountId),
        frequency = Value(frequency),
        startDate = Value(startDate),
        nextOccurrenceDate = Value(nextOccurrenceDate);
  static Insertable<RecurrenceRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? amountCents,
    Expression<int>? accountId,
    Expression<int>? destinationAccountId,
    Expression<int>? categoryId,
    Expression<String>? description,
    Expression<String>? frequency,
    Expression<int>? dayOfMonth,
    Expression<int>? weekday,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? maxOccurrences,
    Expression<int>? generatedCount,
    Expression<DateTime>? nextOccurrenceDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (amountCents != null) 'amount_cents': amountCents,
      if (accountId != null) 'account_id': accountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (weekday != null) 'weekday': weekday,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (maxOccurrences != null) 'max_occurrences': maxOccurrences,
      if (generatedCount != null) 'generated_count': generatedCount,
      if (nextOccurrenceDate != null)
        'next_occurrence_date': nextOccurrenceDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecurrencesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? type,
      Value<int>? amountCents,
      Value<int>? accountId,
      Value<int?>? destinationAccountId,
      Value<int?>? categoryId,
      Value<String?>? description,
      Value<String>? frequency,
      Value<int?>? dayOfMonth,
      Value<int?>? weekday,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<int?>? maxOccurrences,
      Value<int>? generatedCount,
      Value<DateTime>? nextOccurrenceDate,
      Value<String>? status,
      Value<DateTime>? createdAt}) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      generatedCount: generatedCount ?? this.generatedCount,
      nextOccurrenceDate: nextOccurrenceDate ?? this.nextOccurrenceDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<int>(destinationAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (maxOccurrences.present) {
      map['max_occurrences'] = Variable<int>(maxOccurrences.value);
    }
    if (generatedCount.present) {
      map['generated_count'] = Variable<int>(generatedCount.value);
    }
    if (nextOccurrenceDate.present) {
      map['next_occurrence_date'] =
          Variable<DateTime>(nextOccurrenceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('maxOccurrences: $maxOccurrences, ')
          ..write('generatedCount: $generatedCount, ')
          ..write('nextOccurrenceDate: $nextOccurrenceDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<int> destinationAccountId = GeneratedColumn<int>(
      'destination_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _incomeSourceMeta =
      const VerificationMeta('incomeSource');
  @override
  late final GeneratedColumn<String> incomeSource = GeneratedColumn<String>(
      'income_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('paid'));
  static const VerificationMeta _recurrenceIdMeta =
      const VerificationMeta('recurrenceId');
  @override
  late final GeneratedColumn<int> recurrenceId = GeneratedColumn<int>(
      'recurrence_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES recurrences (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        amountCents,
        date,
        accountId,
        destinationAccountId,
        categoryId,
        description,
        incomeSource,
        status,
        recurrenceId,
        createdAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
          _destinationAccountIdMeta,
          destinationAccountId.isAcceptableOrUnknown(
              data['destination_account_id']!, _destinationAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('income_source')) {
      context.handle(
          _incomeSourceMeta,
          incomeSource.isAcceptableOrUnknown(
              data['income_source']!, _incomeSourceMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('recurrence_id')) {
      context.handle(
          _recurrenceIdMeta,
          recurrenceId.isAcceptableOrUnknown(
              data['recurrence_id']!, _recurrenceIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      destinationAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}destination_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      incomeSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}income_source']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      recurrenceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recurrence_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final String type;
  final int amountCents;
  final DateTime date;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String? description;
  final String? incomeSource;
  final String status;
  final int? recurrenceId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const TransactionRow(
      {required this.id,
      required this.type,
      required this.amountCents,
      required this.date,
      required this.accountId,
      this.destinationAccountId,
      this.categoryId,
      this.description,
      this.incomeSource,
      required this.status,
      this.recurrenceId,
      required this.createdAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['amount_cents'] = Variable<int>(amountCents);
    map['date'] = Variable<DateTime>(date);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<int>(destinationAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || incomeSource != null) {
      map['income_source'] = Variable<String>(incomeSource);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || recurrenceId != null) {
      map['recurrence_id'] = Variable<int>(recurrenceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amountCents: Value(amountCents),
      date: Value(date),
      accountId: Value(accountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      incomeSource: incomeSource == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeSource),
      status: Value(status),
      recurrenceId: recurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceId),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      date: serializer.fromJson<DateTime>(json['date']),
      accountId: serializer.fromJson<int>(json['accountId']),
      destinationAccountId:
          serializer.fromJson<int?>(json['destinationAccountId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      description: serializer.fromJson<String?>(json['description']),
      incomeSource: serializer.fromJson<String?>(json['incomeSource']),
      status: serializer.fromJson<String>(json['status']),
      recurrenceId: serializer.fromJson<int?>(json['recurrenceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'amountCents': serializer.toJson<int>(amountCents),
      'date': serializer.toJson<DateTime>(date),
      'accountId': serializer.toJson<int>(accountId),
      'destinationAccountId': serializer.toJson<int?>(destinationAccountId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'description': serializer.toJson<String?>(description),
      'incomeSource': serializer.toJson<String?>(incomeSource),
      'status': serializer.toJson<String>(status),
      'recurrenceId': serializer.toJson<int?>(recurrenceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TransactionRow copyWith(
          {int? id,
          String? type,
          int? amountCents,
          DateTime? date,
          int? accountId,
          Value<int?> destinationAccountId = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> incomeSource = const Value.absent(),
          String? status,
          Value<int?> recurrenceId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      TransactionRow(
        id: id ?? this.id,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        date: date ?? this.date,
        accountId: accountId ?? this.accountId,
        destinationAccountId: destinationAccountId.present
            ? destinationAccountId.value
            : this.destinationAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        description: description.present ? description.value : this.description,
        incomeSource:
            incomeSource.present ? incomeSource.value : this.incomeSource,
        status: status ?? this.status,
        recurrenceId:
            recurrenceId.present ? recurrenceId.value : this.recurrenceId,
        createdAt: createdAt ?? this.createdAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      date: data.date.present ? data.date.value : this.date,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      description:
          data.description.present ? data.description.value : this.description,
      incomeSource: data.incomeSource.present
          ? data.incomeSource.value
          : this.incomeSource,
      status: data.status.present ? data.status.value : this.status,
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('status: $status, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      amountCents,
      date,
      accountId,
      destinationAccountId,
      categoryId,
      description,
      incomeSource,
      status,
      recurrenceId,
      createdAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountCents == this.amountCents &&
          other.date == this.date &&
          other.accountId == this.accountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.incomeSource == this.incomeSource &&
          other.status == this.status &&
          other.recurrenceId == this.recurrenceId &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> amountCents;
  final Value<DateTime> date;
  final Value<int> accountId;
  final Value<int?> destinationAccountId;
  final Value<int?> categoryId;
  final Value<String?> description;
  final Value<String?> incomeSource;
  final Value<String> status;
  final Value<int?> recurrenceId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.date = const Value.absent(),
    this.accountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.incomeSource = const Value.absent(),
    this.status = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int amountCents,
    required DateTime date,
    required int accountId,
    this.destinationAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.incomeSource = const Value.absent(),
    this.status = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : type = Value(type),
        amountCents = Value(amountCents),
        date = Value(date),
        accountId = Value(accountId);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amountCents,
    Expression<DateTime>? date,
    Expression<int>? accountId,
    Expression<int>? destinationAccountId,
    Expression<int>? categoryId,
    Expression<String>? description,
    Expression<String>? incomeSource,
    Expression<String>? status,
    Expression<int>? recurrenceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountCents != null) 'amount_cents': amountCents,
      if (date != null) 'date': date,
      if (accountId != null) 'account_id': accountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (incomeSource != null) 'income_source': incomeSource,
      if (status != null) 'status': status,
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<int>? amountCents,
      Value<DateTime>? date,
      Value<int>? accountId,
      Value<int?>? destinationAccountId,
      Value<int?>? categoryId,
      Value<String?>? description,
      Value<String?>? incomeSource,
      Value<String>? status,
      Value<int?>? recurrenceId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? deletedAt}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      incomeSource: incomeSource ?? this.incomeSource,
      status: status ?? this.status,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<int>(destinationAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (incomeSource.present) {
      map['income_source'] = Variable<String>(incomeSource.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<int>(recurrenceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('status: $status, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, BillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 80),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _billTypeMeta =
      const VerificationMeta('billType');
  @override
  late final GeneratedColumn<String> billType = GeneratedColumn<String>(
      'bill_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _paymentAccountIdMeta =
      const VerificationMeta('paymentAccountId');
  @override
  late final GeneratedColumn<int> paymentAccountId = GeneratedColumn<int>(
      'payment_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _paidTransactionIdMeta =
      const VerificationMeta('paidTransactionId');
  @override
  late final GeneratedColumn<int> paidTransactionId = GeneratedColumn<int>(
      'paid_transaction_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _repeatDayMeta =
      const VerificationMeta('repeatDay');
  @override
  late final GeneratedColumn<int> repeatDay = GeneratedColumn<int>(
      'repeat_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _previousBillIdMeta =
      const VerificationMeta('previousBillId');
  @override
  late final GeneratedColumn<int> previousBillId = GeneratedColumn<int>(
      'previous_bill_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES bills (id)'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        categoryId,
        amountCents,
        dueDate,
        billType,
        status,
        paymentAccountId,
        paidTransactionId,
        repeatDay,
        previousBillId,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(Insertable<BillRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('bill_type')) {
      context.handle(_billTypeMeta,
          billType.isAcceptableOrUnknown(data['bill_type']!, _billTypeMeta));
    } else if (isInserting) {
      context.missing(_billTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('payment_account_id')) {
      context.handle(
          _paymentAccountIdMeta,
          paymentAccountId.isAcceptableOrUnknown(
              data['payment_account_id']!, _paymentAccountIdMeta));
    }
    if (data.containsKey('paid_transaction_id')) {
      context.handle(
          _paidTransactionIdMeta,
          paidTransactionId.isAcceptableOrUnknown(
              data['paid_transaction_id']!, _paidTransactionIdMeta));
    }
    if (data.containsKey('repeat_day')) {
      context.handle(_repeatDayMeta,
          repeatDay.isAcceptableOrUnknown(data['repeat_day']!, _repeatDayMeta));
    }
    if (data.containsKey('previous_bill_id')) {
      context.handle(
          _previousBillIdMeta,
          previousBillId.isAcceptableOrUnknown(
              data['previous_bill_id']!, _previousBillIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      billType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paymentAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_account_id']),
      paidTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}paid_transaction_id']),
      repeatDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repeat_day']),
      previousBillId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}previous_bill_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class BillRow extends DataClass implements Insertable<BillRow> {
  final int id;
  final String name;
  final int? categoryId;
  final int amountCents;
  final DateTime dueDate;
  final String billType;
  final String status;
  final int? paymentAccountId;
  final int? paidTransactionId;
  final int? repeatDay;
  final int? previousBillId;
  final String? notes;
  final DateTime createdAt;
  const BillRow(
      {required this.id,
      required this.name,
      this.categoryId,
      required this.amountCents,
      required this.dueDate,
      required this.billType,
      required this.status,
      this.paymentAccountId,
      this.paidTransactionId,
      this.repeatDay,
      this.previousBillId,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['amount_cents'] = Variable<int>(amountCents);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['bill_type'] = Variable<String>(billType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || paymentAccountId != null) {
      map['payment_account_id'] = Variable<int>(paymentAccountId);
    }
    if (!nullToAbsent || paidTransactionId != null) {
      map['paid_transaction_id'] = Variable<int>(paidTransactionId);
    }
    if (!nullToAbsent || repeatDay != null) {
      map['repeat_day'] = Variable<int>(repeatDay);
    }
    if (!nullToAbsent || previousBillId != null) {
      map['previous_bill_id'] = Variable<int>(previousBillId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountCents: Value(amountCents),
      dueDate: Value(dueDate),
      billType: Value(billType),
      status: Value(status),
      paymentAccountId: paymentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentAccountId),
      paidTransactionId: paidTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidTransactionId),
      repeatDay: repeatDay == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatDay),
      previousBillId: previousBillId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousBillId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory BillRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      billType: serializer.fromJson<String>(json['billType']),
      status: serializer.fromJson<String>(json['status']),
      paymentAccountId: serializer.fromJson<int?>(json['paymentAccountId']),
      paidTransactionId: serializer.fromJson<int?>(json['paidTransactionId']),
      repeatDay: serializer.fromJson<int?>(json['repeatDay']),
      previousBillId: serializer.fromJson<int?>(json['previousBillId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int?>(categoryId),
      'amountCents': serializer.toJson<int>(amountCents),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'billType': serializer.toJson<String>(billType),
      'status': serializer.toJson<String>(status),
      'paymentAccountId': serializer.toJson<int?>(paymentAccountId),
      'paidTransactionId': serializer.toJson<int?>(paidTransactionId),
      'repeatDay': serializer.toJson<int?>(repeatDay),
      'previousBillId': serializer.toJson<int?>(previousBillId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BillRow copyWith(
          {int? id,
          String? name,
          Value<int?> categoryId = const Value.absent(),
          int? amountCents,
          DateTime? dueDate,
          String? billType,
          String? status,
          Value<int?> paymentAccountId = const Value.absent(),
          Value<int?> paidTransactionId = const Value.absent(),
          Value<int?> repeatDay = const Value.absent(),
          Value<int?> previousBillId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      BillRow(
        id: id ?? this.id,
        name: name ?? this.name,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amountCents: amountCents ?? this.amountCents,
        dueDate: dueDate ?? this.dueDate,
        billType: billType ?? this.billType,
        status: status ?? this.status,
        paymentAccountId: paymentAccountId.present
            ? paymentAccountId.value
            : this.paymentAccountId,
        paidTransactionId: paidTransactionId.present
            ? paidTransactionId.value
            : this.paidTransactionId,
        repeatDay: repeatDay.present ? repeatDay.value : this.repeatDay,
        previousBillId:
            previousBillId.present ? previousBillId.value : this.previousBillId,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  BillRow copyWithCompanion(BillsCompanion data) {
    return BillRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      billType: data.billType.present ? data.billType.value : this.billType,
      status: data.status.present ? data.status.value : this.status,
      paymentAccountId: data.paymentAccountId.present
          ? data.paymentAccountId.value
          : this.paymentAccountId,
      paidTransactionId: data.paidTransactionId.present
          ? data.paidTransactionId.value
          : this.paidTransactionId,
      repeatDay: data.repeatDay.present ? data.repeatDay.value : this.repeatDay,
      previousBillId: data.previousBillId.present
          ? data.previousBillId.value
          : this.previousBillId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('dueDate: $dueDate, ')
          ..write('billType: $billType, ')
          ..write('status: $status, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('paidTransactionId: $paidTransactionId, ')
          ..write('repeatDay: $repeatDay, ')
          ..write('previousBillId: $previousBillId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      categoryId,
      amountCents,
      dueDate,
      billType,
      status,
      paymentAccountId,
      paidTransactionId,
      repeatDay,
      previousBillId,
      notes,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.amountCents == this.amountCents &&
          other.dueDate == this.dueDate &&
          other.billType == this.billType &&
          other.status == this.status &&
          other.paymentAccountId == this.paymentAccountId &&
          other.paidTransactionId == this.paidTransactionId &&
          other.repeatDay == this.repeatDay &&
          other.previousBillId == this.previousBillId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class BillsCompanion extends UpdateCompanion<BillRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> categoryId;
  final Value<int> amountCents;
  final Value<DateTime> dueDate;
  final Value<String> billType;
  final Value<String> status;
  final Value<int?> paymentAccountId;
  final Value<int?> paidTransactionId;
  final Value<int?> repeatDay;
  final Value<int?> previousBillId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.billType = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.paidTransactionId = const Value.absent(),
    this.repeatDay = const Value.absent(),
    this.previousBillId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BillsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.categoryId = const Value.absent(),
    required int amountCents,
    required DateTime dueDate,
    required String billType,
    this.status = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.paidTransactionId = const Value.absent(),
    this.repeatDay = const Value.absent(),
    this.previousBillId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        amountCents = Value(amountCents),
        dueDate = Value(dueDate),
        billType = Value(billType);
  static Insertable<BillRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<int>? amountCents,
    Expression<DateTime>? dueDate,
    Expression<String>? billType,
    Expression<String>? status,
    Expression<int>? paymentAccountId,
    Expression<int>? paidTransactionId,
    Expression<int>? repeatDay,
    Expression<int>? previousBillId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (dueDate != null) 'due_date': dueDate,
      if (billType != null) 'bill_type': billType,
      if (status != null) 'status': status,
      if (paymentAccountId != null) 'payment_account_id': paymentAccountId,
      if (paidTransactionId != null) 'paid_transaction_id': paidTransactionId,
      if (repeatDay != null) 'repeat_day': repeatDay,
      if (previousBillId != null) 'previous_bill_id': previousBillId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BillsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int?>? categoryId,
      Value<int>? amountCents,
      Value<DateTime>? dueDate,
      Value<String>? billType,
      Value<String>? status,
      Value<int?>? paymentAccountId,
      Value<int?>? paidTransactionId,
      Value<int?>? repeatDay,
      Value<int?>? previousBillId,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return BillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      dueDate: dueDate ?? this.dueDate,
      billType: billType ?? this.billType,
      status: status ?? this.status,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      paidTransactionId: paidTransactionId ?? this.paidTransactionId,
      repeatDay: repeatDay ?? this.repeatDay,
      previousBillId: previousBillId ?? this.previousBillId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (billType.present) {
      map['bill_type'] = Variable<String>(billType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentAccountId.present) {
      map['payment_account_id'] = Variable<int>(paymentAccountId.value);
    }
    if (paidTransactionId.present) {
      map['paid_transaction_id'] = Variable<int>(paidTransactionId.value);
    }
    if (repeatDay.present) {
      map['repeat_day'] = Variable<int>(repeatDay.value);
    }
    if (previousBillId.present) {
      map['previous_bill_id'] = Variable<int>(previousBillId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('dueDate: $dueDate, ')
          ..write('billType: $billType, ')
          ..write('status: $status, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('paidTransactionId: $paidTransactionId, ')
          ..write('repeatDay: $repeatDay, ')
          ..write('previousBillId: $previousBillId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionRevisionsTable extends TransactionRevisions
    with TableInfo<$TransactionRevisionsTable, TransactionRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES transactions (id)'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _snapshotMeta =
      const VerificationMeta('snapshot');
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
      'snapshot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, transactionId, action, recordedAt, snapshot];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_revisions';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionRevisionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('snapshot')) {
      context.handle(_snapshotMeta,
          snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta));
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRevisionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      snapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot'])!,
    );
  }

  @override
  $TransactionRevisionsTable createAlias(String alias) {
    return $TransactionRevisionsTable(attachedDatabase, alias);
  }
}

class TransactionRevisionRow extends DataClass
    implements Insertable<TransactionRevisionRow> {
  final int id;
  final int transactionId;
  final String action;
  final DateTime recordedAt;
  final String snapshot;
  const TransactionRevisionRow(
      {required this.id,
      required this.transactionId,
      required this.action,
      required this.recordedAt,
      required this.snapshot});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['action'] = Variable<String>(action);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['snapshot'] = Variable<String>(snapshot);
    return map;
  }

  TransactionRevisionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionRevisionsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      action: Value(action),
      recordedAt: Value(recordedAt),
      snapshot: Value(snapshot),
    );
  }

  factory TransactionRevisionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRevisionRow(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      action: serializer.fromJson<String>(json['action']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'action': serializer.toJson<String>(action),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'snapshot': serializer.toJson<String>(snapshot),
    };
  }

  TransactionRevisionRow copyWith(
          {int? id,
          int? transactionId,
          String? action,
          DateTime? recordedAt,
          String? snapshot}) =>
      TransactionRevisionRow(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        action: action ?? this.action,
        recordedAt: recordedAt ?? this.recordedAt,
        snapshot: snapshot ?? this.snapshot,
      );
  TransactionRevisionRow copyWithCompanion(TransactionRevisionsCompanion data) {
    return TransactionRevisionRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      action: data.action.present ? data.action.value : this.action,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRevisionRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('action: $action, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('snapshot: $snapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, action, recordedAt, snapshot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRevisionRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.action == this.action &&
          other.recordedAt == this.recordedAt &&
          other.snapshot == this.snapshot);
}

class TransactionRevisionsCompanion
    extends UpdateCompanion<TransactionRevisionRow> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<String> action;
  final Value<DateTime> recordedAt;
  final Value<String> snapshot;
  const TransactionRevisionsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.action = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.snapshot = const Value.absent(),
  });
  TransactionRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required String action,
    this.recordedAt = const Value.absent(),
    required String snapshot,
  })  : transactionId = Value(transactionId),
        action = Value(action),
        snapshot = Value(snapshot);
  static Insertable<TransactionRevisionRow> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<String>? action,
    Expression<DateTime>? recordedAt,
    Expression<String>? snapshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (action != null) 'action': action,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (snapshot != null) 'snapshot': snapshot,
    });
  }

  TransactionRevisionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? transactionId,
      Value<String>? action,
      Value<DateTime>? recordedAt,
      Value<String>? snapshot}) {
    return TransactionRevisionsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      action: action ?? this.action,
      recordedAt: recordedAt ?? this.recordedAt,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('action: $action, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('snapshot: $snapshot')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 80),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _targetCentsMeta =
      const VerificationMeta('targetCents');
  @override
  late final GeneratedColumn<int> targetCents = GeneratedColumn<int>(
      'target_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _savedCentsMeta =
      const VerificationMeta('savedCents');
  @override
  late final GeneratedColumn<int> savedCents = GeneratedColumn<int>(
      'saved_cents', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, targetCents, savedCents, dueDate, accountId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<GoalRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_cents')) {
      context.handle(
          _targetCentsMeta,
          targetCents.isAcceptableOrUnknown(
              data['target_cents']!, _targetCentsMeta));
    } else if (isInserting) {
      context.missing(_targetCentsMeta);
    }
    if (data.containsKey('saved_cents')) {
      context.handle(
          _savedCentsMeta,
          savedCents.isAcceptableOrUnknown(
              data['saved_cents']!, _savedCentsMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      targetCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_cents'])!,
      savedCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saved_cents'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id']),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final int id;
  final String name;
  final int targetCents;
  final int savedCents;
  final DateTime dueDate;
  final int? accountId;
  const GoalRow(
      {required this.id,
      required this.name,
      required this.targetCents,
      required this.savedCents,
      required this.dueDate,
      this.accountId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_cents'] = Variable<int>(targetCents);
    map['saved_cents'] = Variable<int>(savedCents);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetCents: Value(targetCents),
      savedCents: Value(savedCents),
      dueDate: Value(dueDate),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
    );
  }

  factory GoalRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetCents: serializer.fromJson<int>(json['targetCents']),
      savedCents: serializer.fromJson<int>(json['savedCents']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      accountId: serializer.fromJson<int?>(json['accountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetCents': serializer.toJson<int>(targetCents),
      'savedCents': serializer.toJson<int>(savedCents),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'accountId': serializer.toJson<int?>(accountId),
    };
  }

  GoalRow copyWith(
          {int? id,
          String? name,
          int? targetCents,
          int? savedCents,
          DateTime? dueDate,
          Value<int?> accountId = const Value.absent()}) =>
      GoalRow(
        id: id ?? this.id,
        name: name ?? this.name,
        targetCents: targetCents ?? this.targetCents,
        savedCents: savedCents ?? this.savedCents,
        dueDate: dueDate ?? this.dueDate,
        accountId: accountId.present ? accountId.value : this.accountId,
      );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetCents:
          data.targetCents.present ? data.targetCents.value : this.targetCents,
      savedCents:
          data.savedCents.present ? data.savedCents.value : this.savedCents,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('dueDate: $dueDate, ')
          ..write('accountId: $accountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, targetCents, savedCents, dueDate, accountId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetCents == this.targetCents &&
          other.savedCents == this.savedCents &&
          other.dueDate == this.dueDate &&
          other.accountId == this.accountId);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> targetCents;
  final Value<int> savedCents;
  final Value<DateTime> dueDate;
  final Value<int?> accountId;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetCents = const Value.absent(),
    this.savedCents = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.accountId = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int targetCents,
    this.savedCents = const Value.absent(),
    required DateTime dueDate,
    this.accountId = const Value.absent(),
  })  : name = Value(name),
        targetCents = Value(targetCents),
        dueDate = Value(dueDate);
  static Insertable<GoalRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? targetCents,
    Expression<int>? savedCents,
    Expression<DateTime>? dueDate,
    Expression<int>? accountId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetCents != null) 'target_cents': targetCents,
      if (savedCents != null) 'saved_cents': savedCents,
      if (dueDate != null) 'due_date': dueDate,
      if (accountId != null) 'account_id': accountId,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? targetCents,
      Value<int>? savedCents,
      Value<DateTime>? dueDate,
      Value<int?>? accountId}) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetCents: targetCents ?? this.targetCents,
      savedCents: savedCents ?? this.savedCents,
      dueDate: dueDate ?? this.dueDate,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetCents.present) {
      map['target_cents'] = Variable<int>(targetCents.value);
    }
    if (savedCents.present) {
      map['saved_cents'] = Variable<int>(savedCents.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('dueDate: $dueDate, ')
          ..write('accountId: $accountId')
          ..write(')'))
        .toString();
  }
}

class $BillReminderSettingsTable extends BillReminderSettings
    with TableInfo<$BillReminderSettingsTable, BillReminderSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillReminderSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'));
  static const VerificationMeta _daysBeforeMeta =
      const VerificationMeta('daysBefore');
  @override
  late final GeneratedColumn<int> daysBefore = GeneratedColumn<int>(
      'days_before', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minuteOfDayMeta =
      const VerificationMeta('minuteOfDay');
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
      'minute_of_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _configuredAtMeta =
      const VerificationMeta('configuredAt');
  @override
  late final GeneratedColumn<DateTime> configuredAt = GeneratedColumn<DateTime>(
      'configured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, enabled, daysBefore, minuteOfDay, configuredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_reminder_settings';
  @override
  VerificationContext validateIntegrity(
      Insertable<BillReminderSettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('days_before')) {
      context.handle(
          _daysBeforeMeta,
          daysBefore.isAcceptableOrUnknown(
              data['days_before']!, _daysBeforeMeta));
    } else if (isInserting) {
      context.missing(_daysBeforeMeta);
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
          _minuteOfDayMeta,
          minuteOfDay.isAcceptableOrUnknown(
              data['minute_of_day']!, _minuteOfDayMeta));
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('configured_at')) {
      context.handle(
          _configuredAtMeta,
          configuredAt.isAcceptableOrUnknown(
              data['configured_at']!, _configuredAtMeta));
    } else if (isInserting) {
      context.missing(_configuredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillReminderSettingsRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillReminderSettingsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      daysBefore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}days_before'])!,
      minuteOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute_of_day'])!,
      configuredAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}configured_at'])!,
    );
  }

  @override
  $BillReminderSettingsTable createAlias(String alias) {
    return $BillReminderSettingsTable(attachedDatabase, alias);
  }
}

class BillReminderSettingsRow extends DataClass
    implements Insertable<BillReminderSettingsRow> {
  final int id;
  final bool enabled;
  final int daysBefore;
  final int minuteOfDay;
  final DateTime configuredAt;
  const BillReminderSettingsRow(
      {required this.id,
      required this.enabled,
      required this.daysBefore,
      required this.minuteOfDay,
      required this.configuredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['days_before'] = Variable<int>(daysBefore);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['configured_at'] = Variable<DateTime>(configuredAt);
    return map;
  }

  BillReminderSettingsCompanion toCompanion(bool nullToAbsent) {
    return BillReminderSettingsCompanion(
      id: Value(id),
      enabled: Value(enabled),
      daysBefore: Value(daysBefore),
      minuteOfDay: Value(minuteOfDay),
      configuredAt: Value(configuredAt),
    );
  }

  factory BillReminderSettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillReminderSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      daysBefore: serializer.fromJson<int>(json['daysBefore']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      configuredAt: serializer.fromJson<DateTime>(json['configuredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'daysBefore': serializer.toJson<int>(daysBefore),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'configuredAt': serializer.toJson<DateTime>(configuredAt),
    };
  }

  BillReminderSettingsRow copyWith(
          {int? id,
          bool? enabled,
          int? daysBefore,
          int? minuteOfDay,
          DateTime? configuredAt}) =>
      BillReminderSettingsRow(
        id: id ?? this.id,
        enabled: enabled ?? this.enabled,
        daysBefore: daysBefore ?? this.daysBefore,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        configuredAt: configuredAt ?? this.configuredAt,
      );
  BillReminderSettingsRow copyWithCompanion(
      BillReminderSettingsCompanion data) {
    return BillReminderSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      daysBefore:
          data.daysBefore.present ? data.daysBefore.value : this.daysBefore,
      minuteOfDay:
          data.minuteOfDay.present ? data.minuteOfDay.value : this.minuteOfDay,
      configuredAt: data.configuredAt.present
          ? data.configuredAt.value
          : this.configuredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillReminderSettingsRow(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('daysBefore: $daysBefore, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('configuredAt: $configuredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, enabled, daysBefore, minuteOfDay, configuredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillReminderSettingsRow &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.daysBefore == this.daysBefore &&
          other.minuteOfDay == this.minuteOfDay &&
          other.configuredAt == this.configuredAt);
}

class BillReminderSettingsCompanion
    extends UpdateCompanion<BillReminderSettingsRow> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<int> daysBefore;
  final Value<int> minuteOfDay;
  final Value<DateTime> configuredAt;
  const BillReminderSettingsCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.daysBefore = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.configuredAt = const Value.absent(),
  });
  BillReminderSettingsCompanion.insert({
    this.id = const Value.absent(),
    required bool enabled,
    required int daysBefore,
    required int minuteOfDay,
    required DateTime configuredAt,
  })  : enabled = Value(enabled),
        daysBefore = Value(daysBefore),
        minuteOfDay = Value(minuteOfDay),
        configuredAt = Value(configuredAt);
  static Insertable<BillReminderSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<int>? daysBefore,
    Expression<int>? minuteOfDay,
    Expression<DateTime>? configuredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (daysBefore != null) 'days_before': daysBefore,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (configuredAt != null) 'configured_at': configuredAt,
    });
  }

  BillReminderSettingsCompanion copyWith(
      {Value<int>? id,
      Value<bool>? enabled,
      Value<int>? daysBefore,
      Value<int>? minuteOfDay,
      Value<DateTime>? configuredAt}) {
    return BillReminderSettingsCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      daysBefore: daysBefore ?? this.daysBefore,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      configuredAt: configuredAt ?? this.configuredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (daysBefore.present) {
      map['days_before'] = Variable<int>(daysBefore.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (configuredAt.present) {
      map['configured_at'] = Variable<DateTime>(configuredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillReminderSettingsCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('daysBefore: $daysBefore, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('configuredAt: $configuredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $TransactionRevisionsTable transactionRevisions =
      $TransactionRevisionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $BillReminderSettingsTable billReminderSettings =
      $BillReminderSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accounts,
        categories,
        recurrences,
        transactions,
        bills,
        transactionRevisions,
        goals,
        billReminderSettings
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  required String type,
  Value<int> initialBalanceCents,
  Value<int> currentBalanceCents,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<String?> notes,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<int> initialBalanceCents,
  Value<int> currentBalanceCents,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<String?> notes,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BillsTable, List<BillRow>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.bills.paymentAccountId));

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.paymentAccountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalsTable, List<GoalRow>> _goalsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals,
          aliasName: $_aliasNameGenerator(db.accounts.id, db.goals.accountId));

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.accountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get initialBalanceCents => $composableBuilder(
      column: $table.initialBalanceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentBalanceCents => $composableBuilder(
      column: $table.currentBalanceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.paymentAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> goalsRefs(
      Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get initialBalanceCents => $composableBuilder(
      column: $table.initialBalanceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentBalanceCents => $composableBuilder(
      column: $table.currentBalanceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get initialBalanceCents => $composableBuilder(
      column: $table.initialBalanceCents, builder: (column) => column);

  GeneratedColumn<int> get currentBalanceCents => $composableBuilder(
      column: $table.currentBalanceCents, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.paymentAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
      Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    AccountRow,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountRow, $$AccountsTableReferences),
    AccountRow,
    PrefetchHooks Function({bool billsRefs, bool goalsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> initialBalanceCents = const Value.absent(),
            Value<int> currentBalanceCents = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            type: type,
            initialBalanceCents: initialBalanceCents,
            currentBalanceCents: currentBalanceCents,
            color: color,
            icon: icon,
            isActive: isActive,
            createdAt: createdAt,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String type,
            Value<int> initialBalanceCents = const Value.absent(),
            Value<int> currentBalanceCents = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            type: type,
            initialBalanceCents: initialBalanceCents,
            currentBalanceCents: currentBalanceCents,
            color: color,
            icon: icon,
            isActive: isActive,
            createdAt: createdAt,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({billsRefs = false, goalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (billsRefs) db.bills,
                if (goalsRefs) db.goals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (billsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0).billsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.paymentAccountId == item.id),
                        typedResults: items),
                  if (goalsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._goalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0).goalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    AccountRow,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountRow, $$AccountsTableReferences),
    AccountRow,
    PrefetchHooks Function({bool billsRefs, bool goalsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String type,
  Value<int?> parentId,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> isActive,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<int?> parentId,
  Value<String?> color,
  Value<String?> icon,
  Value<bool> isActive,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.categories.parentId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get parentId {
    if ($_item.parentId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.parentId!));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecurrencesTable, List<RecurrenceRow>>
      _recurrencesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recurrences,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.recurrences.categoryId));

  $$RecurrencesTableProcessedTableManager get recurrencesRefs {
    final manager = $$RecurrencesTableTableManager($_db, $_db.recurrences)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_recurrencesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactions.categoryId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BillsTable, List<BillRow>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.bills.categoryId));

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recurrencesRefs(
      Expression<bool> Function($$RecurrencesTableFilterComposer f) f) {
    final $$RecurrencesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableFilterComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recurrencesRefs<T extends Object>(
      Expression<T> Function($$RecurrencesTableAnnotationComposer a) f) {
    final $$RecurrencesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableAnnotationComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function(
        {bool parentId,
        bool recurrencesRefs,
        bool transactionsRefs,
        bool billsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            type: type,
            parentId: parentId,
            color: color,
            icon: icon,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String type,
            Value<int?> parentId = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            type: type,
            parentId: parentId,
            color: color,
            icon: icon,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {parentId = false,
              recurrencesRefs = false,
              transactionsRefs = false,
              billsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recurrencesRefs) db.recurrences,
                if (transactionsRefs) db.transactions,
                if (billsRefs) db.bills
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable:
                        $$CategoriesTableReferences._parentIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._parentIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recurrencesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._recurrencesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .recurrencesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (billsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .billsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function(
        {bool parentId,
        bool recurrencesRefs,
        bool transactionsRefs,
        bool billsRefs})>;
typedef $$RecurrencesTableCreateCompanionBuilder = RecurrencesCompanion
    Function({
  Value<int> id,
  required String name,
  required String type,
  required int amountCents,
  required int accountId,
  Value<int?> destinationAccountId,
  Value<int?> categoryId,
  Value<String?> description,
  required String frequency,
  Value<int?> dayOfMonth,
  Value<int?> weekday,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int?> maxOccurrences,
  Value<int> generatedCount,
  required DateTime nextOccurrenceDate,
  Value<String> status,
  Value<DateTime> createdAt,
});
typedef $$RecurrencesTableUpdateCompanionBuilder = RecurrencesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<int> amountCents,
  Value<int> accountId,
  Value<int?> destinationAccountId,
  Value<int?> categoryId,
  Value<String?> description,
  Value<String> frequency,
  Value<int?> dayOfMonth,
  Value<int?> weekday,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int?> maxOccurrences,
  Value<int> generatedCount,
  Value<DateTime> nextOccurrenceDate,
  Value<String> status,
  Value<DateTime> createdAt,
});

final class $$RecurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow> {
  $$RecurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.recurrences.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.recurrences.destinationAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get destinationAccountId {
    if ($_item.destinationAccountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.destinationAccountId!));
    final item =
        $_typedResult.readTableOrNull(_destinationAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.recurrences.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.recurrences.id, db.transactions.recurrenceId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.recurrenceId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxOccurrences => $composableBuilder(
      column: $table.maxOccurrences,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generatedCount => $composableBuilder(
      column: $table.generatedCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextOccurrenceDate => $composableBuilder(
      column: $table.nextOccurrenceDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.recurrenceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxOccurrences => $composableBuilder(
      column: $table.maxOccurrences,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generatedCount => $composableBuilder(
      column: $table.generatedCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextOccurrenceDate => $composableBuilder(
      column: $table.nextOccurrenceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get maxOccurrences => $composableBuilder(
      column: $table.maxOccurrences, builder: (column) => column);

  GeneratedColumn<int> get generatedCount => $composableBuilder(
      column: $table.generatedCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextOccurrenceDate => $composableBuilder(
      column: $table.nextOccurrenceDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.recurrenceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurrencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurrencesTable,
    RecurrenceRow,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (RecurrenceRow, $$RecurrencesTableReferences),
    RecurrenceRow,
    PrefetchHooks Function(
        {bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool transactionsRefs})> {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<int?> destinationAccountId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int?> dayOfMonth = const Value.absent(),
            Value<int?> weekday = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> maxOccurrences = const Value.absent(),
            Value<int> generatedCount = const Value.absent(),
            Value<DateTime> nextOccurrenceDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurrencesCompanion(
            id: id,
            name: name,
            type: type,
            amountCents: amountCents,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            description: description,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            weekday: weekday,
            startDate: startDate,
            endDate: endDate,
            maxOccurrences: maxOccurrences,
            generatedCount: generatedCount,
            nextOccurrenceDate: nextOccurrenceDate,
            status: status,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String type,
            required int amountCents,
            required int accountId,
            Value<int?> destinationAccountId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            required String frequency,
            Value<int?> dayOfMonth = const Value.absent(),
            Value<int?> weekday = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> maxOccurrences = const Value.absent(),
            Value<int> generatedCount = const Value.absent(),
            required DateTime nextOccurrenceDate,
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurrencesCompanion.insert(
            id: id,
            name: name,
            type: type,
            amountCents: amountCents,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            description: description,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            weekday: weekday,
            startDate: startDate,
            endDate: endDate,
            maxOccurrences: maxOccurrences,
            generatedCount: generatedCount,
            nextOccurrenceDate: nextOccurrenceDate,
            status: status,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurrencesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {accountId = false,
              destinationAccountId = false,
              categoryId = false,
              transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$RecurrencesTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$RecurrencesTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (destinationAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destinationAccountId,
                    referencedTable: $$RecurrencesTableReferences
                        ._destinationAccountIdTable(db),
                    referencedColumn: $$RecurrencesTableReferences
                        ._destinationAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$RecurrencesTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$RecurrencesTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RecurrencesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecurrencesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.recurrenceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecurrencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurrencesTable,
    RecurrenceRow,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (RecurrenceRow, $$RecurrencesTableReferences),
    RecurrenceRow,
    PrefetchHooks Function(
        {bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required String type,
  required int amountCents,
  required DateTime date,
  required int accountId,
  Value<int?> destinationAccountId,
  Value<int?> categoryId,
  Value<String?> description,
  Value<String?> incomeSource,
  Value<String> status,
  Value<int?> recurrenceId,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<int> amountCents,
  Value<DateTime> date,
  Value<int> accountId,
  Value<int?> destinationAccountId,
  Value<int?> categoryId,
  Value<String?> description,
  Value<String?> incomeSource,
  Value<String> status,
  Value<int?> recurrenceId,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.transactions.destinationAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get destinationAccountId {
    if ($_item.destinationAccountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.destinationAccountId!));
    final item =
        $_typedResult.readTableOrNull(_destinationAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.transactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RecurrencesTable _recurrenceIdTable(_$AppDatabase db) =>
      db.recurrences.createAlias($_aliasNameGenerator(
          db.transactions.recurrenceId, db.recurrences.id));

  $$RecurrencesTableProcessedTableManager? get recurrenceId {
    if ($_item.recurrenceId == null) return null;
    final manager = $$RecurrencesTableTableManager($_db, $_db.recurrences)
        .filter((f) => f.id($_item.recurrenceId!));
    final item = $_typedResult.readTableOrNull(_recurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionRevisionsTable,
      List<TransactionRevisionRow>> _transactionRevisionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactionRevisions,
          aliasName: $_aliasNameGenerator(
              db.transactions.id, db.transactionRevisions.transactionId));

  $$TransactionRevisionsTableProcessedTableManager
      get transactionRevisionsRefs {
    final manager =
        $$TransactionRevisionsTableTableManager($_db, $_db.transactionRevisions)
            .filter((f) => f.transactionId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_transactionRevisionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get incomeSource => $composableBuilder(
      column: $table.incomeSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurrencesTableFilterComposer get recurrenceId {
    final $$RecurrencesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurrenceId,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableFilterComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionRevisionsRefs(
      Expression<bool> Function($$TransactionRevisionsTableFilterComposer f)
          f) {
    final $$TransactionRevisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionRevisions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionRevisionsTableFilterComposer(
              $db: $db,
              $table: $db.transactionRevisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get incomeSource => $composableBuilder(
      column: $table.incomeSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurrencesTableOrderingComposer get recurrenceId {
    final $$RecurrencesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurrenceId,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableOrderingComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get incomeSource => $composableBuilder(
      column: $table.incomeSource, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destinationAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurrencesTableAnnotationComposer get recurrenceId {
    final $$RecurrencesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurrenceId,
        referencedTable: $db.recurrences,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurrencesTableAnnotationComposer(
              $db: $db,
              $table: $db.recurrences,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionRevisionsRefs<T extends Object>(
      Expression<T> Function($$TransactionRevisionsTableAnnotationComposer a)
          f) {
    final $$TransactionRevisionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transactionRevisions,
            getReferencedColumn: (t) => t.transactionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransactionRevisionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transactionRevisions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function(
        {bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool recurrenceId,
        bool transactionRevisionsRefs})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<int?> destinationAccountId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> incomeSource = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> recurrenceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            type: type,
            amountCents: amountCents,
            date: date,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            description: description,
            incomeSource: incomeSource,
            status: status,
            recurrenceId: recurrenceId,
            createdAt: createdAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required int amountCents,
            required DateTime date,
            required int accountId,
            Value<int?> destinationAccountId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> incomeSource = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> recurrenceId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            type: type,
            amountCents: amountCents,
            date: date,
            accountId: accountId,
            destinationAccountId: destinationAccountId,
            categoryId: categoryId,
            description: description,
            incomeSource: incomeSource,
            status: status,
            recurrenceId: recurrenceId,
            createdAt: createdAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {accountId = false,
              destinationAccountId = false,
              categoryId = false,
              recurrenceId = false,
              transactionRevisionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionRevisionsRefs) db.transactionRevisions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (destinationAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destinationAccountId,
                    referencedTable: $$TransactionsTableReferences
                        ._destinationAccountIdTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._destinationAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (recurrenceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recurrenceId,
                    referencedTable:
                        $$TransactionsTableReferences._recurrenceIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._recurrenceIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionRevisionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._transactionRevisionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .transactionRevisionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transactionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function(
        {bool accountId,
        bool destinationAccountId,
        bool categoryId,
        bool recurrenceId,
        bool transactionRevisionsRefs})>;
typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> categoryId,
  required int amountCents,
  required DateTime dueDate,
  required String billType,
  Value<String> status,
  Value<int?> paymentAccountId,
  Value<int?> paidTransactionId,
  Value<int?> repeatDay,
  Value<int?> previousBillId,
  Value<String?> notes,
  Value<DateTime> createdAt,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> categoryId,
  Value<int> amountCents,
  Value<DateTime> dueDate,
  Value<String> billType,
  Value<String> status,
  Value<int?> paymentAccountId,
  Value<int?> paidTransactionId,
  Value<int?> repeatDay,
  Value<int?> previousBillId,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, BillRow> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias($_aliasNameGenerator(db.bills.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _paymentAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.bills.paymentAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get paymentAccountId {
    if ($_item.paymentAccountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.paymentAccountId!));
    final item = $_typedResult.readTableOrNull(_paymentAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BillsTable _previousBillIdTable(_$AppDatabase db) => db.bills
      .createAlias($_aliasNameGenerator(db.bills.previousBillId, db.bills.id));

  $$BillsTableProcessedTableManager? get previousBillId {
    if ($_item.previousBillId == null) return null;
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.id($_item.previousBillId!));
    final item = $_typedResult.readTableOrNull(_previousBillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billType => $composableBuilder(
      column: $table.billType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paidTransactionId => $composableBuilder(
      column: $table.paidTransactionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repeatDay => $composableBuilder(
      column: $table.repeatDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get paymentAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableFilterComposer get previousBillId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.previousBillId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billType => $composableBuilder(
      column: $table.billType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paidTransactionId => $composableBuilder(
      column: $table.paidTransactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repeatDay => $composableBuilder(
      column: $table.repeatDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get paymentAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableOrderingComposer get previousBillId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.previousBillId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableOrderingComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get billType =>
      $composableBuilder(column: $table.billType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get paidTransactionId => $composableBuilder(
      column: $table.paidTransactionId, builder: (column) => column);

  GeneratedColumn<int> get repeatDay =>
      $composableBuilder(column: $table.repeatDay, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get paymentAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableAnnotationComposer get previousBillId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.previousBillId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillsTable,
    BillRow,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (BillRow, $$BillsTableReferences),
    BillRow,
    PrefetchHooks Function(
        {bool categoryId, bool paymentAccountId, bool previousBillId})> {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<String> billType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> paymentAccountId = const Value.absent(),
            Value<int?> paidTransactionId = const Value.absent(),
            Value<int?> repeatDay = const Value.absent(),
            Value<int?> previousBillId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BillsCompanion(
            id: id,
            name: name,
            categoryId: categoryId,
            amountCents: amountCents,
            dueDate: dueDate,
            billType: billType,
            status: status,
            paymentAccountId: paymentAccountId,
            paidTransactionId: paidTransactionId,
            repeatDay: repeatDay,
            previousBillId: previousBillId,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int?> categoryId = const Value.absent(),
            required int amountCents,
            required DateTime dueDate,
            required String billType,
            Value<String> status = const Value.absent(),
            Value<int?> paymentAccountId = const Value.absent(),
            Value<int?> paidTransactionId = const Value.absent(),
            Value<int?> repeatDay = const Value.absent(),
            Value<int?> previousBillId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BillsCompanion.insert(
            id: id,
            name: name,
            categoryId: categoryId,
            amountCents: amountCents,
            dueDate: dueDate,
            billType: billType,
            status: status,
            paymentAccountId: paymentAccountId,
            paidTransactionId: paidTransactionId,
            repeatDay: repeatDay,
            previousBillId: previousBillId,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BillsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              paymentAccountId = false,
              previousBillId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BillsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (paymentAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paymentAccountId,
                    referencedTable:
                        $$BillsTableReferences._paymentAccountIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._paymentAccountIdTable(db).id,
                  ) as T;
                }
                if (previousBillId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.previousBillId,
                    referencedTable:
                        $$BillsTableReferences._previousBillIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._previousBillIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BillsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BillsTable,
    BillRow,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (BillRow, $$BillsTableReferences),
    BillRow,
    PrefetchHooks Function(
        {bool categoryId, bool paymentAccountId, bool previousBillId})>;
typedef $$TransactionRevisionsTableCreateCompanionBuilder
    = TransactionRevisionsCompanion Function({
  Value<int> id,
  required int transactionId,
  required String action,
  Value<DateTime> recordedAt,
  required String snapshot,
});
typedef $$TransactionRevisionsTableUpdateCompanionBuilder
    = TransactionRevisionsCompanion Function({
  Value<int> id,
  Value<int> transactionId,
  Value<String> action,
  Value<DateTime> recordedAt,
  Value<String> snapshot,
});

final class $$TransactionRevisionsTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionRevisionsTable, TransactionRevisionRow> {
  $$TransactionRevisionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.transactionRevisions.transactionId, db.transactions.id));

  $$TransactionsTableProcessedTableManager? get transactionId {
    if ($_item.transactionId == null) return null;
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.id($_item.transactionId!));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshot => $composableBuilder(
      column: $table.snapshot, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshot => $composableBuilder(
      column: $table.snapshot, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionRevisionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionRevisionsTable,
    TransactionRevisionRow,
    $$TransactionRevisionsTableFilterComposer,
    $$TransactionRevisionsTableOrderingComposer,
    $$TransactionRevisionsTableAnnotationComposer,
    $$TransactionRevisionsTableCreateCompanionBuilder,
    $$TransactionRevisionsTableUpdateCompanionBuilder,
    (TransactionRevisionRow, $$TransactionRevisionsTableReferences),
    TransactionRevisionRow,
    PrefetchHooks Function({bool transactionId})> {
  $$TransactionRevisionsTableTableManager(
      _$AppDatabase db, $TransactionRevisionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionRevisionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionRevisionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> transactionId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> snapshot = const Value.absent(),
          }) =>
              TransactionRevisionsCompanion(
            id: id,
            transactionId: transactionId,
            action: action,
            recordedAt: recordedAt,
            snapshot: snapshot,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int transactionId,
            required String action,
            Value<DateTime> recordedAt = const Value.absent(),
            required String snapshot,
          }) =>
              TransactionRevisionsCompanion.insert(
            id: id,
            transactionId: transactionId,
            action: action,
            recordedAt: recordedAt,
            snapshot: snapshot,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionRevisionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable: $$TransactionRevisionsTableReferences
                        ._transactionIdTable(db),
                    referencedColumn: $$TransactionRevisionsTableReferences
                        ._transactionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionRevisionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TransactionRevisionsTable,
        TransactionRevisionRow,
        $$TransactionRevisionsTableFilterComposer,
        $$TransactionRevisionsTableOrderingComposer,
        $$TransactionRevisionsTableAnnotationComposer,
        $$TransactionRevisionsTableCreateCompanionBuilder,
        $$TransactionRevisionsTableUpdateCompanionBuilder,
        (TransactionRevisionRow, $$TransactionRevisionsTableReferences),
        TransactionRevisionRow,
        PrefetchHooks Function({bool transactionId})>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String name,
  required int targetCents,
  Value<int> savedCents,
  required DateTime dueDate,
  Value<int?> accountId,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> targetCents,
  Value<int> savedCents,
  Value<DateTime> dueDate,
  Value<int?> accountId,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalRow> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.goals.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetCents => $composableBuilder(
      column: $table.targetCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get savedCents => $composableBuilder(
      column: $table.savedCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetCents => $composableBuilder(
      column: $table.targetCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get savedCents => $composableBuilder(
      column: $table.savedCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetCents => $composableBuilder(
      column: $table.targetCents, builder: (column) => column);

  GeneratedColumn<int> get savedCents => $composableBuilder(
      column: $table.savedCents, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    GoalRow,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (GoalRow, $$GoalsTableReferences),
    GoalRow,
    PrefetchHooks Function({bool accountId})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> targetCents = const Value.absent(),
            Value<int> savedCents = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<int?> accountId = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            name: name,
            targetCents: targetCents,
            savedCents: savedCents,
            dueDate: dueDate,
            accountId: accountId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int targetCents,
            Value<int> savedCents = const Value.absent(),
            required DateTime dueDate,
            Value<int?> accountId = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            name: name,
            targetCents: targetCents,
            savedCents: savedCents,
            dueDate: dueDate,
            accountId: accountId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable: $$GoalsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    GoalRow,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (GoalRow, $$GoalsTableReferences),
    GoalRow,
    PrefetchHooks Function({bool accountId})>;
typedef $$BillReminderSettingsTableCreateCompanionBuilder
    = BillReminderSettingsCompanion Function({
  Value<int> id,
  required bool enabled,
  required int daysBefore,
  required int minuteOfDay,
  required DateTime configuredAt,
});
typedef $$BillReminderSettingsTableUpdateCompanionBuilder
    = BillReminderSettingsCompanion Function({
  Value<int> id,
  Value<bool> enabled,
  Value<int> daysBefore,
  Value<int> minuteOfDay,
  Value<DateTime> configuredAt,
});

class $$BillReminderSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BillReminderSettingsTable> {
  $$BillReminderSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysBefore => $composableBuilder(
      column: $table.daysBefore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get configuredAt => $composableBuilder(
      column: $table.configuredAt, builder: (column) => ColumnFilters(column));
}

class $$BillReminderSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillReminderSettingsTable> {
  $$BillReminderSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysBefore => $composableBuilder(
      column: $table.daysBefore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get configuredAt => $composableBuilder(
      column: $table.configuredAt,
      builder: (column) => ColumnOrderings(column));
}

class $$BillReminderSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillReminderSettingsTable> {
  $$BillReminderSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get daysBefore => $composableBuilder(
      column: $table.daysBefore, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => column);

  GeneratedColumn<DateTime> get configuredAt => $composableBuilder(
      column: $table.configuredAt, builder: (column) => column);
}

class $$BillReminderSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillReminderSettingsTable,
    BillReminderSettingsRow,
    $$BillReminderSettingsTableFilterComposer,
    $$BillReminderSettingsTableOrderingComposer,
    $$BillReminderSettingsTableAnnotationComposer,
    $$BillReminderSettingsTableCreateCompanionBuilder,
    $$BillReminderSettingsTableUpdateCompanionBuilder,
    (
      BillReminderSettingsRow,
      BaseReferences<_$AppDatabase, $BillReminderSettingsTable,
          BillReminderSettingsRow>
    ),
    BillReminderSettingsRow,
    PrefetchHooks Function()> {
  $$BillReminderSettingsTableTableManager(
      _$AppDatabase db, $BillReminderSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillReminderSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillReminderSettingsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillReminderSettingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> daysBefore = const Value.absent(),
            Value<int> minuteOfDay = const Value.absent(),
            Value<DateTime> configuredAt = const Value.absent(),
          }) =>
              BillReminderSettingsCompanion(
            id: id,
            enabled: enabled,
            daysBefore: daysBefore,
            minuteOfDay: minuteOfDay,
            configuredAt: configuredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required bool enabled,
            required int daysBefore,
            required int minuteOfDay,
            required DateTime configuredAt,
          }) =>
              BillReminderSettingsCompanion.insert(
            id: id,
            enabled: enabled,
            daysBefore: daysBefore,
            minuteOfDay: minuteOfDay,
            configuredAt: configuredAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BillReminderSettingsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $BillReminderSettingsTable,
        BillReminderSettingsRow,
        $$BillReminderSettingsTableFilterComposer,
        $$BillReminderSettingsTableOrderingComposer,
        $$BillReminderSettingsTableAnnotationComposer,
        $$BillReminderSettingsTableCreateCompanionBuilder,
        $$BillReminderSettingsTableUpdateCompanionBuilder,
        (
          BillReminderSettingsRow,
          BaseReferences<_$AppDatabase, $BillReminderSettingsTable,
              BillReminderSettingsRow>
        ),
        BillReminderSettingsRow,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$TransactionRevisionsTableTableManager get transactionRevisions =>
      $$TransactionRevisionsTableTableManager(_db, _db.transactionRevisions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$BillReminderSettingsTableTableManager get billReminderSettings =>
      $$BillReminderSettingsTableTableManager(_db, _db.billReminderSettings);
}
