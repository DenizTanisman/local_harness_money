import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/database_provider.dart';
import '../data/io/money_extras.dart';
import '../data/repositories/settings_repository.dart';
import 'amounts.dart';
import 'date_key.dart';
import 'debouncer.dart';
import 'hub_bridge.dart';

/// Hub snapshot schema version (docs/HUB_CONTRACT.md §4).
const hubSnapshotSchema = 1;

/// How far ahead recurring rules are listed under `upcoming`.
const _upcomingWindowDays = 30;

/// How many of the newest transactions are listed under `recent`.
const _recentCount = 5;

/// Builds Para's hub snapshot (schema 1) — a pure function of the DB so it
/// is unit-testable with an in-memory database. Only summaries and the last
/// few transactions leave the app; the hub reads it through HubProvider,
/// which is guarded by the signature-level HUB permission.
Future<Map<String, Object?>> buildHubSnapshot(
  AppDatabase db, {
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final today = dateKey(at);
  final month = today.substring(0, 7);

  Future<double> sum(String direction, {String? datePattern}) async {
    final total = db.transactions.amount.sum();
    var where = db.transactions.direction.equals(direction);
    if (datePattern != null) {
      where = where & db.transactions.date.like(datePattern);
    }
    final row =
        await (db.selectOnly(db.transactions)
              ..addColumns([total])
              ..where(where))
            .getSingle();
    return row.read(total) ?? 0.0;
  }

  final monthIncome = await sum('income', datePattern: '$month-%');
  final monthOutcome = await sum('outcome', datePattern: '$month-%');
  final allTimeBalance = await sum('income') - await sum('outcome');
  final todayIncome = await sum('income', datePattern: today);
  final todayOutcome = await sum('outcome', datePattern: today);

  final recent =
      await (db.select(db.transactions)
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(_recentCount))
          .get();

  // Next due date of every recurring rule, kept when within the window.
  final rules = parseRecurringRules(await SettingsRepository(db).loadAll());
  final horizon = dateKey(at.add(const Duration(days: _upcomingWindowDays)));
  final upcoming =
      [
          for (final rule in rules) (rule: rule, date: nextDueDate(rule, at)),
        ].where((u) => u.date.compareTo(horizon) <= 0).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final monthBalance = monthIncome - monthOutcome;
  String signed(double v) =>
      '${v > 0
          ? '+'
          : v < 0
          ? '−'
          : ''}${formatAmount(v.abs())}';

  return {
    'app': 'para',
    'schema': hubSnapshotSchema,
    'generatedAt': at.toIso8601String(),
    'date': today,
    'headline':
        'Bu ay ${signed(_round(monthBalance))} TL · '
        'Bakiye ${signed(_round(allTimeBalance))} TL',
    'data': {
      'currency': 'TL',
      'month': month,
      'monthIncome': _round(monthIncome),
      'monthOutcome': _round(monthOutcome),
      'monthBalance': _round(monthBalance),
      'allTimeBalance': _round(allTimeBalance),
      'todayIncome': _round(todayIncome),
      'todayOutcome': _round(todayOutcome),
      'recent': [
        for (final tx in recent)
          {
            'date': tx.date,
            'direction': tx.direction,
            'amount': _round(tx.amount),
            'category': tx.category,
            'note': tx.note,
          },
      ],
      'upcoming': [
        for (final u in upcoming)
          {
            'date': u.date,
            'category': u.rule.category,
            'amount': _round(u.rule.amount),
            'direction': u.rule.direction,
          },
      ],
    },
  };
}

/// Two decimals — keeps float noise (0.1 + 0.2) out of the JSON.
double _round(double v) => (v * 100).roundToDouble() / 100;

/// Publishes the snapshot (docs/HUB_CONTRACT.md §5): once at startup, then
/// debounced on every DB write, and on AppLifecycleState.paused.
class HubSnapshotPublisher {
  HubSnapshotPublisher(this.db, {Duration debounce = defaultDebounce})
    : _debouncer = Debouncer(debounce);

  static const defaultDebounce = Duration(milliseconds: 1500);

  final AppDatabase db;
  final Debouncer _debouncer;
  StreamSubscription<Set<TableUpdate>>? _updates;

  /// Publishes now and starts listening for table updates. Idempotent.
  Future<void> start() async {
    _updates ??= db.tableUpdates().listen(
      (_) => _debouncer(() => unawaited(publishNow())),
    );
    await publishNow();
  }

  Future<void> publishNow() async {
    try {
      await HubBridge.publishSnapshot(await buildHubSnapshot(db));
    } catch (_) {
      // Best effort: the hub just shows the previous snapshot. Never log
      // the payload — it carries amounts (spec §11.7).
    }
  }

  void dispose() {
    _debouncer.dispose();
    _updates?.cancel();
    _updates = null;
  }
}

final hubSnapshotPublisherProvider = Provider<HubSnapshotPublisher>((ref) {
  final publisher = HubSnapshotPublisher(ref.watch(databaseProvider));
  ref.onDispose(publisher.dispose);
  return publisher;
});
