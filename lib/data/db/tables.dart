import 'package:drift/drift.dart';

/// Money subsystem: N transactions per day (ADR-4).
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();

  /// 'income' | 'outcome'
  TextColumn get direction => text()();
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK (amount >= 0)')();
  TextColumn get category => text()();

  /// NULL → plain category; 'home' → shown as 'Bill (home)'.
  TextColumn get subtype => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Category dictionary: dropdown source + essential flag.
class MoneyCategories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'income' | 'outcome'
  TextColumn get direction => text()();
  TextColumn get name => text()();

  /// User-set essential flag (Categories tab). The daily budget itself keys
  /// off MoneyRepository.discretionaryCategories.
  BoolColumn get isEssential => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {direction, name},
  ];
}

/// Expense reminder queue (local notifications). Monthly-recurring: the
/// day-of-month lives in the day part of [remindDate] (see MoneyRepository).
class ExpenseReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get remindDate => text()();
  BoolColumn get fired => boolean().withDefault(const Constant(false))();
}

/// App settings key-value store. Also holds the money extras as JSON
/// (category budgets, recurring rules — see money_extras.dart).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
