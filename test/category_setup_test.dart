import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/io/category_setup.dart';
import 'package:local_harness_para/data/io/money_extras.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:local_harness_para/data/repositories/settings_repository.dart';

void main() {
  test('renames old categories everywhere and adds the general set', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MoneyRepository(db);
    await repo.addCategory('outcome', 'Market'); // already exists on device
    await repo.addTransaction(date: '2026-10-01', direction: 'outcome', amount: 50, category: 'Food');
    await repo.addTransaction(date: '2026-10-01', direction: 'outcome', amount: 900, category: 'Bill');
    await saveRecurringRules(SettingsRepository(db), const [
      RecurringRule(id: 'x', direction: 'outcome', amount: 99, category: 'Subscription', day: 5),
    ]);

    await CategorySetup(db).runOnce();
    await CategorySetup(db).runOnce(); // idempotent

    final txs = await db.select(db.transactions).get();
    expect(txs.map((t) => t.category).toSet(), {'Yeme-İçme', 'Fatura'});
    final cats = await db.select(db.moneyCategories).get();
    final names = cats.map((c) => c.name).toSet();
    expect(names, containsAll(['Kira', 'Fatura', 'Abonelik', 'Yeme-İçme', 'Burs']));
    expect(names, isNot(contains('Food')));
    final rules = parseRecurringRules(await SettingsRepository(db).loadAll());
    expect(rules.single.category, 'Abonelik');
  });
}
