// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount >= 0)',
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    direction,
    amount,
    category,
    subtype,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final String date;

  /// 'income' | 'outcome'
  final String direction;
  final double amount;
  final String category;

  /// NULL → plain category; 'home' → shown as 'Bill (home)'.
  final String? subtype;
  final String? note;
  final int createdAt;
  final int updatedAt;
  const Transaction({
    required this.id,
    required this.date,
    required this.direction,
    required this.amount,
    required this.category,
    this.subtype,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['direction'] = Variable<String>(direction);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      date: Value(date),
      direction: Value(direction),
      amount: Value(amount),
      category: Value(category),
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      direction: serializer.fromJson<String>(json['direction']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      subtype: serializer.fromJson<String?>(json['subtype']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'direction': serializer.toJson<String>(direction),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'subtype': serializer.toJson<String?>(subtype),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Transaction copyWith({
    int? id,
    String? date,
    String? direction,
    double? amount,
    String? category,
    Value<String?> subtype = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    date: date ?? this.date,
    direction: direction ?? this.direction,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    subtype: subtype.present ? subtype.value : this.subtype,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      direction: data.direction.present ? data.direction.value : this.direction,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('subtype: $subtype, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    direction,
    amount,
    category,
    subtype,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.date == this.date &&
          other.direction == this.direction &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.subtype == this.subtype &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> direction;
  final Value<double> amount;
  final Value<String> category;
  final Value<String?> subtype;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.direction = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.subtype = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String direction,
    required double amount,
    required String category,
    this.subtype = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : date = Value(date),
       direction = Value(direction),
       amount = Value(amount),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? direction,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? subtype,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (direction != null) 'direction': direction,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (subtype != null) 'subtype': subtype,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? direction,
    Value<double>? amount,
    Value<String>? category,
    Value<String?>? subtype,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('subtype: $subtype, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MoneyCategoriesTable extends MoneyCategories
    with TableInfo<$MoneyCategoriesTable, MoneyCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoneyCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEssentialMeta = const VerificationMeta(
    'isEssential',
  );
  @override
  late final GeneratedColumn<bool> isEssential = GeneratedColumn<bool>(
    'is_essential',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_essential" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    direction,
    name,
    isEssential,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'money_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoneyCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_essential')) {
      context.handle(
        _isEssentialMeta,
        isEssential.isAcceptableOrUnknown(
          data['is_essential']!,
          _isEssentialMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {direction, name},
  ];
  @override
  MoneyCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoneyCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isEssential: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_essential'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MoneyCategoriesTable createAlias(String alias) {
    return $MoneyCategoriesTable(attachedDatabase, alias);
  }
}

class MoneyCategory extends DataClass implements Insertable<MoneyCategory> {
  final int id;

  /// 'income' | 'outcome'
  final String direction;
  final String name;

  /// User-set essential flag (Categories tab). The daily budget itself keys
  /// off MoneyRepository.discretionaryCategories.
  final bool isEssential;
  final int sortOrder;
  const MoneyCategory({
    required this.id,
    required this.direction,
    required this.name,
    required this.isEssential,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['direction'] = Variable<String>(direction);
    map['name'] = Variable<String>(name);
    map['is_essential'] = Variable<bool>(isEssential);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MoneyCategoriesCompanion toCompanion(bool nullToAbsent) {
    return MoneyCategoriesCompanion(
      id: Value(id),
      direction: Value(direction),
      name: Value(name),
      isEssential: Value(isEssential),
      sortOrder: Value(sortOrder),
    );
  }

  factory MoneyCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoneyCategory(
      id: serializer.fromJson<int>(json['id']),
      direction: serializer.fromJson<String>(json['direction']),
      name: serializer.fromJson<String>(json['name']),
      isEssential: serializer.fromJson<bool>(json['isEssential']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'direction': serializer.toJson<String>(direction),
      'name': serializer.toJson<String>(name),
      'isEssential': serializer.toJson<bool>(isEssential),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MoneyCategory copyWith({
    int? id,
    String? direction,
    String? name,
    bool? isEssential,
    int? sortOrder,
  }) => MoneyCategory(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    name: name ?? this.name,
    isEssential: isEssential ?? this.isEssential,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MoneyCategory copyWithCompanion(MoneyCategoriesCompanion data) {
    return MoneyCategory(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      name: data.name.present ? data.name.value : this.name,
      isEssential: data.isEssential.present
          ? data.isEssential.value
          : this.isEssential,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoneyCategory(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('isEssential: $isEssential, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, direction, name, isEssential, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyCategory &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.name == this.name &&
          other.isEssential == this.isEssential &&
          other.sortOrder == this.sortOrder);
}

class MoneyCategoriesCompanion extends UpdateCompanion<MoneyCategory> {
  final Value<int> id;
  final Value<String> direction;
  final Value<String> name;
  final Value<bool> isEssential;
  final Value<int> sortOrder;
  const MoneyCategoriesCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.name = const Value.absent(),
    this.isEssential = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  MoneyCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String direction,
    required String name,
    this.isEssential = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : direction = Value(direction),
       name = Value(name);
  static Insertable<MoneyCategory> custom({
    Expression<int>? id,
    Expression<String>? direction,
    Expression<String>? name,
    Expression<bool>? isEssential,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (name != null) 'name': name,
      if (isEssential != null) 'is_essential': isEssential,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  MoneyCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? direction,
    Value<String>? name,
    Value<bool>? isEssential,
    Value<int>? sortOrder,
  }) {
    return MoneyCategoriesCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      name: name ?? this.name,
      isEssential: isEssential ?? this.isEssential,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isEssential.present) {
      map['is_essential'] = Variable<bool>(isEssential.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoneyCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('isEssential: $isEssential, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ExpenseRemindersTable extends ExpenseReminders
    with TableInfo<$ExpenseRemindersTable, ExpenseReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _remindDateMeta = const VerificationMeta(
    'remindDate',
  );
  @override
  late final GeneratedColumn<String> remindDate = GeneratedColumn<String>(
    'remind_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firedMeta = const VerificationMeta('fired');
  @override
  late final GeneratedColumn<bool> fired = GeneratedColumn<bool>(
    'fired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, transactionId, remindDate, fired];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('remind_date')) {
      context.handle(
        _remindDateMeta,
        remindDate.isAcceptableOrUnknown(data['remind_date']!, _remindDateMeta),
      );
    } else if (isInserting) {
      context.missing(_remindDateMeta);
    }
    if (data.containsKey('fired')) {
      context.handle(
        _firedMeta,
        fired.isAcceptableOrUnknown(data['fired']!, _firedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      remindDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_date'],
      )!,
      fired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fired'],
      )!,
    );
  }

  @override
  $ExpenseRemindersTable createAlias(String alias) {
    return $ExpenseRemindersTable(attachedDatabase, alias);
  }
}

class ExpenseReminder extends DataClass implements Insertable<ExpenseReminder> {
  final int id;
  final int transactionId;
  final String remindDate;
  final bool fired;
  const ExpenseReminder({
    required this.id,
    required this.transactionId,
    required this.remindDate,
    required this.fired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['remind_date'] = Variable<String>(remindDate);
    map['fired'] = Variable<bool>(fired);
    return map;
  }

  ExpenseRemindersCompanion toCompanion(bool nullToAbsent) {
    return ExpenseRemindersCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      remindDate: Value(remindDate),
      fired: Value(fired),
    );
  }

  factory ExpenseReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseReminder(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      remindDate: serializer.fromJson<String>(json['remindDate']),
      fired: serializer.fromJson<bool>(json['fired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'remindDate': serializer.toJson<String>(remindDate),
      'fired': serializer.toJson<bool>(fired),
    };
  }

  ExpenseReminder copyWith({
    int? id,
    int? transactionId,
    String? remindDate,
    bool? fired,
  }) => ExpenseReminder(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    remindDate: remindDate ?? this.remindDate,
    fired: fired ?? this.fired,
  );
  ExpenseReminder copyWithCompanion(ExpenseRemindersCompanion data) {
    return ExpenseReminder(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      remindDate: data.remindDate.present
          ? data.remindDate.value
          : this.remindDate,
      fired: data.fired.present ? data.fired.value : this.fired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseReminder(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('remindDate: $remindDate, ')
          ..write('fired: $fired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, remindDate, fired);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseReminder &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.remindDate == this.remindDate &&
          other.fired == this.fired);
}

class ExpenseRemindersCompanion extends UpdateCompanion<ExpenseReminder> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<String> remindDate;
  final Value<bool> fired;
  const ExpenseRemindersCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.remindDate = const Value.absent(),
    this.fired = const Value.absent(),
  });
  ExpenseRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required String remindDate,
    this.fired = const Value.absent(),
  }) : transactionId = Value(transactionId),
       remindDate = Value(remindDate);
  static Insertable<ExpenseReminder> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<String>? remindDate,
    Expression<bool>? fired,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (remindDate != null) 'remind_date': remindDate,
      if (fired != null) 'fired': fired,
    });
  }

  ExpenseRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? transactionId,
    Value<String>? remindDate,
    Value<bool>? fired,
  }) {
    return ExpenseRemindersCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      remindDate: remindDate ?? this.remindDate,
      fired: fired ?? this.fired,
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
    if (remindDate.present) {
      map['remind_date'] = Variable<String>(remindDate.value);
    }
    if (fired.present) {
      map['fired'] = Variable<bool>(fired.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRemindersCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('remindDate: $remindDate, ')
          ..write('fired: $fired')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $MoneyCategoriesTable moneyCategories = $MoneyCategoriesTable(
    this,
  );
  late final $ExpenseRemindersTable expenseReminders = $ExpenseRemindersTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    moneyCategories,
    expenseReminders,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expense_reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required String date,
      required String direction,
      required double amount,
      required String category,
      Value<String?> subtype,
      Value<String?> note,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> direction,
      Value<double> amount,
      Value<String> category,
      Value<String?> subtype,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExpenseRemindersTable, List<ExpenseReminder>>
  _expenseRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseReminders,
    aliasName: 'transactions__id__expense_reminders__transaction_id',
  );

  $$ExpenseRemindersTableProcessedTableManager get expenseRemindersRefs {
    final manager = $$ExpenseRemindersTableTableManager(
      $_db,
      $_db.expenseReminders,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseRemindersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> expenseRemindersRefs(
    Expression<bool> Function($$ExpenseRemindersTableFilterComposer f) f,
  ) {
    final $$ExpenseRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseReminders,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRemindersTableFilterComposer(
            $db: $db,
            $table: $db.expenseReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> expenseRemindersRefs<T extends Object>(
    Expression<T> Function($$ExpenseRemindersTableAnnotationComposer a) f,
  ) {
    final $$ExpenseRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseReminders,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool expenseRemindersRefs})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> subtype = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                date: date,
                direction: direction,
                amount: amount,
                category: category,
                subtype: subtype,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String direction,
                required double amount,
                required String category,
                Value<String?> subtype = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => TransactionsCompanion.insert(
                id: id,
                date: date,
                direction: direction,
                amount: amount,
                category: category,
                subtype: subtype,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseRemindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expenseRemindersRefs) db.expenseReminders,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expenseRemindersRefs)
                    await $_getPrefetchedData<
                      Transaction,
                      $TransactionsTable,
                      ExpenseReminder
                    >(
                      currentTable: table,
                      referencedTable: $$TransactionsTableReferences
                          ._expenseRemindersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransactionsTableReferences(
                            db,
                            table,
                            p0,
                          ).expenseRemindersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.transactionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool expenseRemindersRefs})
    >;
typedef $$MoneyCategoriesTableCreateCompanionBuilder =
    MoneyCategoriesCompanion Function({
      Value<int> id,
      required String direction,
      required String name,
      Value<bool> isEssential,
      Value<int> sortOrder,
    });
typedef $$MoneyCategoriesTableUpdateCompanionBuilder =
    MoneyCategoriesCompanion Function({
      Value<int> id,
      Value<String> direction,
      Value<String> name,
      Value<bool> isEssential,
      Value<int> sortOrder,
    });

class $$MoneyCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoneyCategoriesTable> {
  $$MoneyCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEssential => $composableBuilder(
    column: $table.isEssential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoneyCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoneyCategoriesTable> {
  $$MoneyCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEssential => $composableBuilder(
    column: $table.isEssential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoneyCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoneyCategoriesTable> {
  $$MoneyCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isEssential => $composableBuilder(
    column: $table.isEssential,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$MoneyCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoneyCategoriesTable,
          MoneyCategory,
          $$MoneyCategoriesTableFilterComposer,
          $$MoneyCategoriesTableOrderingComposer,
          $$MoneyCategoriesTableAnnotationComposer,
          $$MoneyCategoriesTableCreateCompanionBuilder,
          $$MoneyCategoriesTableUpdateCompanionBuilder,
          (
            MoneyCategory,
            BaseReferences<_$AppDatabase, $MoneyCategoriesTable, MoneyCategory>,
          ),
          MoneyCategory,
          PrefetchHooks Function()
        > {
  $$MoneyCategoriesTableTableManager(
    _$AppDatabase db,
    $MoneyCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoneyCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoneyCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoneyCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isEssential = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => MoneyCategoriesCompanion(
                id: id,
                direction: direction,
                name: name,
                isEssential: isEssential,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String direction,
                required String name,
                Value<bool> isEssential = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => MoneyCategoriesCompanion.insert(
                id: id,
                direction: direction,
                name: name,
                isEssential: isEssential,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoneyCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoneyCategoriesTable,
      MoneyCategory,
      $$MoneyCategoriesTableFilterComposer,
      $$MoneyCategoriesTableOrderingComposer,
      $$MoneyCategoriesTableAnnotationComposer,
      $$MoneyCategoriesTableCreateCompanionBuilder,
      $$MoneyCategoriesTableUpdateCompanionBuilder,
      (
        MoneyCategory,
        BaseReferences<_$AppDatabase, $MoneyCategoriesTable, MoneyCategory>,
      ),
      MoneyCategory,
      PrefetchHooks Function()
    >;
typedef $$ExpenseRemindersTableCreateCompanionBuilder =
    ExpenseRemindersCompanion Function({
      Value<int> id,
      required int transactionId,
      required String remindDate,
      Value<bool> fired,
    });
typedef $$ExpenseRemindersTableUpdateCompanionBuilder =
    ExpenseRemindersCompanion Function({
      Value<int> id,
      Value<int> transactionId,
      Value<String> remindDate,
      Value<bool> fired,
    });

final class $$ExpenseRemindersTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExpenseRemindersTable, ExpenseReminder> {
  $$ExpenseRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('expense_reminders__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpenseRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseRemindersTable> {
  $$ExpenseRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindDate => $composableBuilder(
    column: $table.remindDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fired => $composableBuilder(
    column: $table.fired,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseRemindersTable> {
  $$ExpenseRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindDate => $composableBuilder(
    column: $table.remindDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fired => $composableBuilder(
    column: $table.fired,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseRemindersTable> {
  $$ExpenseRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remindDate => $composableBuilder(
    column: $table.remindDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fired =>
      $composableBuilder(column: $table.fired, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseRemindersTable,
          ExpenseReminder,
          $$ExpenseRemindersTableFilterComposer,
          $$ExpenseRemindersTableOrderingComposer,
          $$ExpenseRemindersTableAnnotationComposer,
          $$ExpenseRemindersTableCreateCompanionBuilder,
          $$ExpenseRemindersTableUpdateCompanionBuilder,
          (ExpenseReminder, $$ExpenseRemindersTableReferences),
          ExpenseReminder,
          PrefetchHooks Function({bool transactionId})
        > {
  $$ExpenseRemindersTableTableManager(
    _$AppDatabase db,
    $ExpenseRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<String> remindDate = const Value.absent(),
                Value<bool> fired = const Value.absent(),
              }) => ExpenseRemindersCompanion(
                id: id,
                transactionId: transactionId,
                remindDate: remindDate,
                fired: fired,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int transactionId,
                required String remindDate,
                Value<bool> fired = const Value.absent(),
              }) => ExpenseRemindersCompanion.insert(
                id: id,
                transactionId: transactionId,
                remindDate: remindDate,
                fired: fired,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpenseRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.transactionId,
                                referencedTable:
                                    $$ExpenseRemindersTableReferences
                                        ._transactionIdTable(db),
                                referencedColumn:
                                    $$ExpenseRemindersTableReferences
                                        ._transactionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpenseRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseRemindersTable,
      ExpenseReminder,
      $$ExpenseRemindersTableFilterComposer,
      $$ExpenseRemindersTableOrderingComposer,
      $$ExpenseRemindersTableAnnotationComposer,
      $$ExpenseRemindersTableCreateCompanionBuilder,
      $$ExpenseRemindersTableUpdateCompanionBuilder,
      (ExpenseReminder, $$ExpenseRemindersTableReferences),
      ExpenseReminder,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$MoneyCategoriesTableTableManager get moneyCategories =>
      $$MoneyCategoriesTableTableManager(_db, _db.moneyCategories);
  $$ExpenseRemindersTableTableManager get expenseReminders =>
      $$ExpenseRemindersTableTableManager(_db, _db.expenseReminders);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
