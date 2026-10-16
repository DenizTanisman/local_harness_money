import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/io/fresh_start.dart';
import 'package:local_harness_para/data/io/money_extras.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:local_harness_para/data/repositories/settings_repository.dart';

void main() {
  test('wipes money data once, keeps categories and budgets', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MoneyRepository(db);
    final settings = SettingsRepository(db);
    await repo.addTransaction(date: '2026-10-01', direction: 'outcome', amount: 50, category: 'Bill', reminderDays: [5]);
    await saveRecurringRules(settings, const [
      RecurringRule(id: 'x', direction: 'outcome', amount: 99, category: 'Bill', day: 5),
    ]);
    await saveCategoryBudgets(settings, {'Bill': 500});
    final cats = (await db.select(db.moneyCategories).get()).length;

    await FreshStart(db).runOnce();
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.expenseReminders).get(), isEmpty);
    final s = await settings.loadAll();
    expect(parseRecurringRules(s), isEmpty);
    expect(parseCategoryBudgets(s), {'Bill': 500});
    expect((await db.select(db.moneyCategories).get()).length, cats);

    // Runs only once: data entered afterwards survives.
    await repo.addTransaction(date: '2026-10-16', direction: 'income', amount: 1, category: 'Burs');
    await FreshStart(db).runOnce();
    expect(await db.select(db.transactions).get(), hasLength(1));
  });
}
