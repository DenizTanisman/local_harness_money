import 'dart:convert';

import 'package:local_harness_para/core/hub_bridge.dart';
import 'package:local_harness_para/core/hub_snapshot_publisher.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/io/money_extras.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:local_harness_para/data/repositories/settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// HUB_CONTRACT §4/§5: Para's snapshot is a pure function of the DB with
/// the agreed schema-1 shape and correct month / all-time balance math.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MoneyRepository money;
  final now = DateTime(2026, 10, 4, 12, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    money = MoneyRepository(db);
  });
  tearDown(() => db.close());

  Future<void> add(
    String date,
    String direction,
    double amount,
    String category, {
    String? note,
  }) => money.addTransaction(
    date: date,
    direction: direction,
    amount: amount,
    category: category,
    note: note,
  );

  test('empty DB → schema keys with zeroed numbers', () async {
    final snap = await buildHubSnapshot(db, now: now);
    expect(snap.keys, [
      'app',
      'schema',
      'generatedAt',
      'date',
      'headline',
      'data',
    ]);
    expect(snap['app'], 'para');
    expect(snap['schema'], 1);
    expect(snap['date'], '2026-10-04');
    expect(snap['generatedAt'], '2026-10-04T12:30:00.000');
    final data = snap['data']! as Map<String, Object?>;
    expect(
      data.keys,
      unorderedEquals([
        'currency',
        'month',
        'monthIncome',
        'monthOutcome',
        'monthBalance',
        'allTimeBalance',
        'todayIncome',
        'todayOutcome',
        'recent',
        'upcoming',
      ]),
    );
    expect(data['currency'], 'TL');
    expect(data['month'], '2026-10');
    expect(data['monthBalance'], 0);
    expect(data['allTimeBalance'], 0);
    expect(data['recent'], isEmpty);
    expect(data['upcoming'], isEmpty);
    // Must survive the trip through the platform channel as JSON.
    expect(jsonDecode(jsonEncode(snap)), snap);
  });

  test('month vs all-time balance, today totals, recent order', () async {
    await add('2026-09-15', 'income', 1000, 'Scholarship'); // last month
    await add('2026-10-01', 'income', 5000, 'Scholarship');
    await add('2026-10-02', 'outcome', 1200.5, 'Rent');
    await add('2026-10-04', 'outcome', 0.1, 'Food');
    await add('2026-10-04', 'outcome', 0.2, 'Food', note: 'simit');
    await add('2026-10-04', 'income', 50, 'Gift');
    await add('2026-11-01', 'outcome', 99, 'Rent'); // future-dated, next month

    final snap = await buildHubSnapshot(db, now: now);
    final data = snap['data']! as Map<String, Object?>;

    expect(data['monthIncome'], 5050);
    expect(data['monthOutcome'], 1200.8); // float noise rounded away
    expect(data['monthBalance'], 3849.2);
    // Σ income − Σ outcome over EVERY transaction, any month.
    expect(data['allTimeBalance'], 4750.2);
    expect(data['todayIncome'], 50);
    expect(data['todayOutcome'], 0.3);

    final recent = (data['recent']! as List).cast<Map<String, Object?>>();
    expect(recent, hasLength(5));
    expect(recent.map((r) => r['date']), [
      '2026-11-01',
      '2026-10-04',
      '2026-10-04',
      '2026-10-04',
      '2026-10-02',
    ]);
    expect(recent[1], {
      'date': '2026-10-04',
      'direction': 'income',
      'amount': 50,
      'category': 'Gift',
      'note': null,
    });
    expect(recent[2]['note'], 'simit');

    expect(snap['headline'], 'Bu ay +3.849,20 TL · Bakiye +4.750,20 TL');
  });

  test('upcoming lists recurring rules by next due date', () async {
    await saveRecurringRules(SettingsRepository(db), const [
      RecurringRule(
        id: 'rent',
        direction: 'outcome',
        amount: 8000,
        category: 'Rent',
        day: 2, // already passed this month → 2026-11-02
        lastApplied: '2026-10',
      ),
      RecurringRule(
        id: 'netflix',
        direction: 'outcome',
        amount: 229.99,
        category: 'Subscription',
        day: 10,
        lastApplied: '2026-09',
      ),
    ]);

    final data =
        (await buildHubSnapshot(db, now: now))['data']! as Map<String, Object?>;
    expect(data['upcoming'], [
      {
        'date': '2026-10-10',
        'category': 'Subscription',
        'amount': 229.99,
        'direction': 'outcome',
      },
      {
        'date': '2026-11-02',
        'category': 'Rent',
        'amount': 8000,
        'direction': 'outcome',
      },
    ]);
  });

  test('bridge calls are silent no-ops without the platform side', () async {
    await HubBridge.publishSnapshot(await buildHubSnapshot(db, now: now));
    expect(await HubBridge.readPeerSnapshot('program'), isNull);
    expect(await HubBridge.isInstalled('hub'), isFalse);
    expect(await HubBridge.launchApp('hub'), isFalse);
  });
}
