// Fills a fresh install with a demo month, for the README screenshots
// (tool/screenshots/README.md). Not part of the app:
//
//   flutter build apk --release -t tool/screenshots/seed_demo.dart
//
// Every amount is made up.
import 'package:flutter/material.dart';

import 'package:local_harness_para/core/date_key.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/db/open_connection.dart';
import 'package:local_harness_para/data/io/money_extras.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:local_harness_para/data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Status('Demo verisi yükleniyor…'));
  final db = AppDatabase(openEncryptedConnection());
  final money = MoneyRepository(db);
  final settings = SettingsRepository(db);

  for (final name in ['Market', 'Ulaşım', 'Kahve']) {
    await money.addCategory('outcome', name);
  }
  await money.addCategory('income', 'Maaş');

  final now = DateTime.now();
  String day(int d) => dateKey(DateTime(now.year, now.month, d));
  Future<void> out(int d, double amount, String category, [String? note]) =>
      money.addTransaction(
        date: day(d),
        direction: 'outcome',
        amount: amount,
        category: category,
        note: note,
      );

  await money.addTransaction(
    date: day(1),
    direction: 'income',
    amount: 32000,
    category: 'Maaş',
  );
  await money.addTransaction(
    date: day(1),
    direction: 'outcome',
    amount: 11000,
    category: 'Rent',
    reminderDays: const [1],
  );
  await money.addTransaction(
    date: day(5),
    direction: 'outcome',
    amount: 950,
    category: 'Bill',
    subtype: 'home',
    note: 'Elektrik',
    reminderDays: const [5],
  );
  // A plausible month up to today: groceries, coffee, transport, a night out.
  const daily = <(double, String, String?)>[
    (420, 'Market', null),
    (95, 'Kahve', null),
    (60, 'Ulaşım', null),
    (180, 'Food', 'Öğle yemeği'),
    (75, 'Kahve', null),
    (640, 'Entertainment', 'Konser'),
    (310, 'Market', null),
    (60, 'Ulaşım', null),
  ];
  for (var d = 2; d <= now.day; d++) {
    final (amount, category, note) = daily[d % daily.length];
    await out(d, amount, category, note);
    if (d % 3 == 0) await out(d, 60, 'Ulaşım');
  }

  await saveRecurringRules(settings, [
    RecurringRule(
      id: 'maas',
      direction: 'income',
      amount: 32000,
      category: 'Maaş',
      day: 1,
      lastApplied: _ym(now),
    ),
    RecurringRule(
      id: 'kira',
      direction: 'outcome',
      amount: 11000,
      category: 'Rent',
      day: 1,
      lastApplied: _ym(now),
    ),
  ]);
  await saveCategoryBudgets(settings, {
    'Market': 4000,
    'Kahve': 1200,
    'Entertainment': 1500,
  });
  // The app's one-shot fresh start (lib/data/io/fresh_start.dart) would
  // wipe these transactions: mark it as done.
  await settings.set('fresh_start_2026_10_16', 'done');
  await db.close();
  runApp(const _Status('Demo hazır. Şimdi uygulamanın kendisini kur.'));
}

String _ym(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

class _Status extends StatelessWidget {
  const _Status(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(body: Center(child: Text(text))),
  );
}
