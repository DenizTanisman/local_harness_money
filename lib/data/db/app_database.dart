import 'package:drift/drift.dart';

import 'seed_data.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Para's own encrypted database: the money tables + app_settings. Split
/// out of the Daily Tracker monolith as a fresh install, so the schema
/// starts again at v1 with no upgrade chain.
@DriftDatabase(
  tables: [Transactions, MoneyCategories, ExpenseReminders, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX idx_tx_date ON transactions(date)');
      await customStatement(
        'CREATE INDEX idx_reminders_tx ON expense_reminders(transaction_id)',
      );
      await _seed();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seed() async {
    await transaction(() async {
      for (var i = 0; i < seedMoneyCategories.length; i++) {
        final c = seedMoneyCategories[i];
        await into(moneyCategories).insert(
          MoneyCategoriesCompanion.insert(
            direction: c.direction,
            name: c.name,
            isEssential: Value(c.essential),
            sortOrder: Value(i),
          ),
        );
      }
      for (final entry in seedSettings.entries) {
        await into(appSettings).insert(
          AppSettingsCompanion.insert(key: entry.key, value: entry.value),
        );
      }
    });
  }
}
