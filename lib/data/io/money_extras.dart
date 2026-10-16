import 'dart:convert';

import '../../core/date_key.dart';
import '../db/app_database.dart';
import '../repositories/money_repository.dart';
import '../repositories/settings_repository.dart';

/// Settings keys for the money "extras" that are stored as JSON in app_settings
/// (no schema migration needed).
const kCategoryBudgetsKey = 'category_budgets';
const kRecurringRulesKey = 'recurring_rules';

// --------------------------------------------------------------- budgets

/// Parses the {categoryName: monthlyLimit} budget map from the settings map.
Map<String, double> parseCategoryBudgets(Map<String, String> settings) {
  final raw = settings[kCategoryBudgetsKey];
  if (raw == null || raw.isEmpty) return {};
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in m.entries) e.key: (e.value as num).toDouble(),
    };
  } catch (_) {
    return {};
  }
}

Future<void> saveCategoryBudgets(
  SettingsRepository repo,
  Map<String, double> budgets,
) {
  // Drop zero/negative limits so they don't show as "0 limit".
  final clean = {
    for (final e in budgets.entries)
      if (e.value > 0) e.key: e.value,
  };
  return repo.set(kCategoryBudgetsKey, jsonEncode(clean));
}

// ------------------------------------------------------------- recurring

/// A rule that auto-creates a transaction on [day] of every month.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.direction,
    required this.amount,
    required this.category,
    required this.day,
    this.subtype,
    this.note,
    this.lastApplied = '',
  });

  final String id;
  final String direction; // 'income' | 'outcome'
  final double amount;
  final String category;
  final int day; // 1–31, clamped to short months
  final String? subtype;
  final String? note;

  /// 'YYYY-MM' of the last month a transaction was created for, or '' if none.
  final String lastApplied;

  RecurringRule copyWith({String? lastApplied}) => RecurringRule(
    id: id,
    direction: direction,
    amount: amount,
    category: category,
    day: day,
    subtype: subtype,
    note: note,
    lastApplied: lastApplied ?? this.lastApplied,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'direction': direction,
    'amount': amount,
    'category': category,
    'day': day,
    if (subtype != null) 'subtype': subtype,
    if (note != null) 'note': note,
    'lastApplied': lastApplied,
  };

  static RecurringRule fromJson(Map<String, dynamic> j) => RecurringRule(
    id: j['id'] as String,
    direction: j['direction'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String,
    day: (j['day'] as num).toInt(),
    subtype: j['subtype'] as String?,
    note: j['note'] as String?,
    lastApplied: (j['lastApplied'] as String?) ?? '',
  );
}

List<RecurringRule> parseRecurringRules(Map<String, String> settings) {
  final raw = settings[kRecurringRulesKey];
  if (raw == null || raw.isEmpty) return [];
  try {
    return [
      for (final e in jsonDecode(raw) as List)
        RecurringRule.fromJson(e as Map<String, dynamic>),
    ];
  } catch (_) {
    return [];
  }
}

Future<void> saveRecurringRules(
  SettingsRepository repo,
  List<RecurringRule> rules,
) => repo.set(
  kRecurringRulesKey,
  jsonEncode([for (final r in rules) r.toJson()]),
);

String _ym(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// The 'YYYY-MM' values a rule still owes a transaction for, given [now].
/// Past months are always due; the current month is due only once its [day]
/// has arrived.
List<String> dueMonths(RecurringRule rule, DateTime now) {
  final current = _ym(now);
  // Never applied → start from last month so we don't backfill history.
  var cursor = rule.lastApplied.isEmpty
      ? DateTime(now.year, now.month - 1, 1)
      : DateTime(
          int.parse(rule.lastApplied.substring(0, 4)),
          int.parse(rule.lastApplied.substring(5, 7)),
          1,
        );
  final out = <String>[];
  cursor = DateTime(cursor.year, cursor.month + 1, 1); // month after lastApplied
  while (true) {
    final ym = _ym(cursor);
    if (ym.compareTo(current) > 0) break;
    if (ym == current && now.day < rule.day) break; // day not reached yet
    out.add(ym);
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return out;
}

/// Applies all recurring rules: creates any owed transactions and advances
/// each rule's [lastApplied]. Runs once on app open (idempotent).
class RecurringApplier {
  RecurringApplier(this.db);

  final AppDatabase db;

  Future<void> runOnce({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final settings = await SettingsRepository(db).loadAll();
    final rules = parseRecurringRules(settings);
    if (rules.isEmpty) return;

    final repo = MoneyRepository(db);
    var changed = false;
    final updated = <RecurringRule>[];
    for (final rule in rules) {
      final months = dueMonths(rule, at);
      for (final ym in months) {
        final parts = ym.split('-').map(int.parse).toList();
        final daysInMonth = DateTime(parts[0], parts[1] + 1, 0).day;
        final day = rule.day.clamp(1, daysInMonth);
        final date = '$ym-${day.toString().padLeft(2, '0')}';
        await repo.addTransaction(
          date: date,
          direction: rule.direction,
          amount: rule.amount,
          category: rule.category,
          subtype: rule.subtype,
          note: rule.note,
        );
        changed = true;
      }
      updated.add(
        months.isEmpty ? rule : rule.copyWith(lastApplied: months.last),
      );
    }
    if (changed) {
      await saveRecurringRules(SettingsRepository(db), updated);
    }
  }
}

/// Next future due date ('YYYY-MM-DD') for a rule, for the Upcoming view.
String nextDueDate(RecurringRule rule, DateTime now) {
  var month = DateTime(now.year, now.month, 1);
  for (var i = 0; i < 24; i++) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final day = rule.day.clamp(1, daysInMonth);
    final candidate = DateTime(month.year, month.month, day);
    if (!candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      return dateKey(candidate);
    }
    month = DateTime(month.year, month.month + 1, 1);
  }
  return dateKey(now);
}
