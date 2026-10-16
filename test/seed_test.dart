import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('seed data (fresh install)', () {
    test('schema starts at v1', () {
      expect(db.schemaVersion, 1);
    });

    test('money categories seeded with correct flags', () async {
      final categories = await db.select(db.moneyCategories).get();
      expect(categories, hasLength(5));
      final byName = {for (final c in categories) c.name: c};
      expect(byName['Rent']!.isEssential, isTrue);
      expect(byName['Bill']!.isEssential, isTrue);
      expect(byName['Food']!.isEssential, isFalse);
      expect(byName['Entertainment']!.direction, 'outcome');
      expect(byName['Scholarship']!.direction, 'income');
    });

    test('default settings seeded', () async {
      final settings = await db.select(db.appSettings).get();
      final map = {for (final s in settings) s.key: s.value};
      expect(map['backup_enabled'], 'false');
    });

    test('only the money tables exist', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(
        rows.map((r) => r.read<String>('name')),
        unorderedEquals([
          'transactions',
          'money_categories',
          'expense_reminders',
          'app_settings',
        ]),
      );
    });
  });

  group('constraints', () {
    test('negative amounts are rejected (CHECK amount >= 0)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        () => db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                date: '2026-06-10',
                direction: 'outcome',
                amount: -1,
                category: 'Food',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsException,
      );
    });

    test('UNIQUE(direction, name) on categories', () async {
      expect(
        () => db
            .into(db.moneyCategories)
            .insert(
              MoneyCategoriesCompanion.insert(
                direction: 'outcome',
                name: 'Food',
              ),
            ),
        throwsException,
      );
    });

    test('deleting a transaction cascades its reminders', () async {
      final money = MoneyRepository(db);
      final id = await money.addTransaction(
        date: '2026-06-10',
        direction: 'outcome',
        amount: 100,
        category: 'Bill',
        reminderDays: [5, 20],
      );
      expect(await db.select(db.expenseReminders).get(), hasLength(2));
      await money.deleteTransaction(id);
      expect(await db.select(db.expenseReminders).get(), isEmpty);
    });
  });
}
