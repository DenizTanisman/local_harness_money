import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../repositories/settings_repository.dart';
import 'money_extras.dart';

/// One-shot: switches to the general Turkish category set. Old (English)
/// names are renamed in place — categories, transactions, recurring rules
/// and budgets — so history stays under the new names; the rest is added.
class CategorySetup {
  CategorySetup(this.db);

  final AppDatabase db;

  static const _flagKey = 'categories_tr_v1';

  /// (direction, name, ödenmez?, old names folded into it), in list order.
  static const categories =
      <({String direction, String name, bool fixed, List<String> from})>[
        (direction: 'outcome', name: 'Yeme-İçme', fixed: false, from: ['Food']),
        (direction: 'outcome', name: 'Market', fixed: false, from: []),
        (
          direction: 'outcome',
          name: 'Ulaşım',
          fixed: false,
          from: ['Transport'],
        ),
        (
          direction: 'outcome',
          name: 'Alışveriş',
          fixed: false,
          from: ['Shopping'],
        ),
        (direction: 'outcome', name: 'Sağlık', fixed: false, from: ['Health']),
        (
          direction: 'outcome',
          name: 'Eğlence',
          fixed: false,
          from: ['Entertainment'],
        ),
        (
          direction: 'outcome',
          name: 'Eğitim',
          fixed: false,
          from: ['Education'],
        ),
        (direction: 'outcome', name: 'Kişisel bakım', fixed: false, from: []),
        (direction: 'outcome', name: 'Transfer', fixed: false, from: []),
        (direction: 'outcome', name: 'Nakit', fixed: false, from: ['Cash']),
        (
          direction: 'outcome',
          name: 'Yatırım',
          fixed: false,
          from: ['Investment'],
        ),
        (
          direction: 'outcome',
          name: 'Diğer',
          fixed: false,
          from: ['Other', 'Fee'],
        ),
        (
          direction: 'outcome',
          name: 'Kira',
          fixed: true,
          from: ['Rent', 'Aidat'],
        ),
        (direction: 'outcome', name: 'Fatura', fixed: true, from: ['Bill']),
        (
          direction: 'outcome',
          name: 'Abonelik',
          fixed: true,
          from: ['Subscription'],
        ),
        (
          direction: 'income',
          name: 'Burs',
          fixed: false,
          from: ['Scholarship'],
        ),
        (direction: 'income', name: 'Maaş', fixed: false, from: []),
        (direction: 'income', name: 'Harçlık', fixed: false, from: []),
        (direction: 'income', name: 'İade', fixed: false, from: []),
        (
          direction: 'income',
          name: 'Diğer gelir',
          fixed: false,
          from: ['Other'],
        ),
        (
          direction: 'income',
          name: 'Düzeltme',
          fixed: false,
          from: ['Adjustment'],
        ),
      ];

  Future<void> runOnce() async {
    final settingsRepo = SettingsRepository(db);
    final settings = await settingsRepo.loadAll();
    if (settings[_flagKey] != null) return;

    await db.transaction(() async {
      for (var i = 0; i < categories.length; i++) {
        final c = categories[i];
        for (final old in c.from) {
          await (db.update(db.transactions)..where(
                (t) => t.direction.equals(c.direction) & t.category.equals(old),
              ))
              .write(TransactionsCompanion(category: Value(c.name)));
          await (db.delete(db.moneyCategories)..where(
                (m) => m.direction.equals(c.direction) & m.name.equals(old),
              ))
              .go();
        }
        final values = MoneyCategoriesCompanion(
          isEssential: Value(c.fixed),
          sortOrder: Value(i + 1),
        );
        final updated =
            await (db.update(db.moneyCategories)..where(
                  (m) =>
                      m.direction.equals(c.direction) & m.name.equals(c.name),
                ))
                .write(values);
        if (updated == 0) {
          await db
              .into(db.moneyCategories)
              .insert(
                values.copyWith(
                  direction: Value(c.direction),
                  name: Value(c.name),
                ),
              );
        }
      }

      // Recurring rules and budgets reference categories by name too.
      String rename(String direction, String name) {
        for (final c in categories) {
          if (c.direction == direction && c.from.contains(name)) return c.name;
        }
        return name;
      }

      final rules = parseRecurringRules(settings);
      if (rules.isNotEmpty) {
        await saveRecurringRules(settingsRepo, [
          for (final r in rules)
            RecurringRule.fromJson({
              ...r.toJson(),
              'category': rename(r.direction, r.category),
            }),
        ]);
      }
      final budgets = parseCategoryBudgets(settings);
      if (budgets.isNotEmpty) {
        await settingsRepo.set(
          kCategoryBudgetsKey,
          jsonEncode({
            for (final e in budgets.entries) rename('outcome', e.key): e.value,
          }),
        );
      }
      await settingsRepo.set(_flagKey, 'done');
    });
  }
}
