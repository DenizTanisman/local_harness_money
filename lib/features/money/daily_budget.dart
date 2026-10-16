import 'dart:convert';

import 'package:drift/drift.dart' show innerJoin;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_key.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/io/money_extras.dart';
import '../../data/repositories/settings_repository.dart';
import 'money_providers.dart';

/// Daily spendable money ("günlük harcanabilir para"):
///
///   daily = (ana para − ödenmezler) / süre
///
/// * ana para  — the money there is: every income (whatever its date) minus
///   outcomes, as of the period's start day (that day's own spending counts
///   as spending, not as a deduction).
/// * ödenmezler — monthly bills & subscriptions (recurring outcome rules +
///   monthly reminders, by amount). If the previous one was paid (or there
///   is no previous one), the next one is ignored until 5 days before its
///   due date; if the previous one is unpaid, it is owed right away.
/// * süre — days until the next expected income (a recurring income rule
///   due within a month), otherwise until the end of the month.
///
/// A period's daily value is frozen once its first day is over. A new
/// period (= automatic recalculation) starts on a day money comes in, when
/// an income is entered for any date, when a bill enters its 5-day window,
/// when the period runs out, or on "yeniden hesapla". Overspending a day is
/// carried over and deducted from the following day(s); an under-spent day
/// just shows its plus.
const kDailyPeriodsKey = 'daily_periods';

/// Outcome categories that are "ödenmez" — never count as daily spending
/// (old English names kept for data entered before the rename).
const fixedCategories = {
  'Kira', 'Fatura', 'Abonelik', //
  'Rent', 'Bill', 'Subscription', 'Aidat',
};

class BudgetPeriod {
  const BudgetPeriod({
    required this.start,
    required this.end,
    required this.base,
    required this.fixed,
    required this.daily,
    this.since,
    this.madeAt,
  });

  final String start; // 'YYYY-MM-DD', inclusive
  final String end; // 'YYYY-MM-DD', inclusive
  final double base; // ana para
  final double fixed; // ödenmezler
  final double daily;

  /// Set when the user hit "yeniden hesapla": the epoch-ms moment of the
  /// recalculation. Everything entered before it is already in [base], so on
  /// the start day only entries created after it count as spending.
  final int? since;

  /// Epoch-ms when this period was (last) computed — an income entered
  /// after it triggers a recalculation.
  final int? madeAt;

  int get days => parseDateKey(end).difference(parseDateKey(start)).inDays + 1;

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'base': base,
    'fixed': fixed,
    'daily': daily,
    if (since != null) 'since': since,
    if (madeAt != null) 'madeAt': madeAt,
  };

  static BudgetPeriod fromJson(Map<String, dynamic> j) => BudgetPeriod(
    start: j['start'] as String,
    end: j['end'] as String,
    base: (j['base'] as num).toDouble(),
    fixed: (j['fixed'] as num).toDouble(),
    daily: (j['daily'] as num).toDouble(),
    since: (j['since'] as num?)?.toInt(),
    madeAt: (j['madeAt'] as num?)?.toInt(),
  );
}

/// One tracked day: its limit (daily − carried overspend), what was spent,
/// and the result (+ under, − over).
class DayStatus {
  const DayStatus({
    required this.date,
    required this.limit,
    required this.spent,
    required this.period,
  });

  final String date;
  final double limit;
  final double spent;
  final BudgetPeriod period;

  double get diff => limit - spent;
  double get carriedIn => period.daily - limit;
}

/// A monthly bill/subscription with a known amount, due on [day]. A
/// recurring rule ([from] null) is paid by the transaction it creates
/// (same category + amount); a reminder ([from] = its first transaction's
/// date) by any outcome of its [category].
typedef Obligation = ({int day, double amount, String category, String? from});

DateTime _d(String key) => parseDateKey(key);
String _addDays(String key, int n) {
  final d = _d(key);
  return dateKey(DateTime(d.year, d.month, d.day + n));
}

int _clampDay(int day, DateTime month) =>
    day.clamp(1, DateTime(month.year, month.month + 1, 0).day);

/// Last due date of a monthly [day] on or before [s].
DateTime _dueOnOrBefore(int day, DateTime s) {
  final here = DateTime(s.year, s.month, _clampDay(day, s));
  if (!here.isAfter(s)) return here;
  final prev = DateTime(s.year, s.month - 1, 1);
  return DateTime(prev.year, prev.month, _clampDay(day, prev));
}

/// First due date of a monthly [day] after [s].
DateTime _dueAfter(int day, DateTime s) {
  final here = DateTime(s.year, s.month, _clampDay(day, s));
  if (here.isAfter(s)) return here;
  final next = DateTime(s.year, s.month + 1, 1);
  return DateTime(next.year, next.month, _clampDay(day, next));
}

/// Whether [o] counts as ödenmez for a period starting [start] that runs
/// through [end] (see the rule at the top of the file).
bool _owes(Obligation o, String start, String end, List<Transaction> txs) {
  final s = _d(start);
  final prev = _dueOnOrBefore(o.day, s);
  final paidFrom = dateKey(prev.subtract(const Duration(days: 7)));
  final paid = txs.any(
    (tx) =>
        tx.direction == 'outcome' &&
        tx.category == o.category &&
        (o.from != null || tx.amount == o.amount) &&
        tx.date.compareTo(paidFrom) >= 0 &&
        tx.date.compareTo(start) <= 0,
  );
  // A rule pays itself, so an unpaid "previous" means it did not exist yet.
  final hadPrev = o.from == null ? paid : dateKey(prev).compareTo(o.from!) >= 0;
  if (hadPrev && !paid) return true;
  final next = _dueAfter(o.day, s);
  return !next.isAfter(_d(end)) && next.difference(s).inDays <= 5;
}

List<Obligation> _obligations(
  List<RecurringRule> rules,
  List<Obligation> reminders,
) => [
  for (final r in rules.where((r) => r.direction == 'outcome'))
    (day: r.day, amount: r.amount, category: r.category, from: null),
  ...reminders,
];

/// The recurring rule that created [tx] (same direction, category, amount
/// and day of month), if any.
RecurringRule? ruleFor(Transaction tx, List<RecurringRule> rules) {
  final d = _d(tx.date);
  for (final r in rules) {
    if (r.direction == tx.direction &&
        r.category == tx.category &&
        r.amount == tx.amount &&
        _clampDay(r.day, d) == d.day) {
      return r;
    }
  }
  return null;
}

/// "Ödenmez" outcome: a bill/subscription category or a recurring outcome.
bool isFixedOutcome(Transaction tx, List<RecurringRule> rules) =>
    tx.direction == 'outcome' &&
    (fixedCategories.contains(tx.category) || ruleFor(tx, rules) != null);

/// Computes a period that starts on [start] (pure; see the formula above).
BudgetPeriod computePeriod({
  required String start,
  required List<Transaction> txs,
  required List<RecurringRule> rules,
  required List<Obligation> reminders,
  int? since,
  int? madeAt,
}) {
  final s = _d(start);

  // süre: next expected income within a month, else end of month.
  DateTime? nextIncome;
  for (final r in rules.where((r) => r.direction == 'income')) {
    var due = DateTime(s.year, s.month, _clampDay(r.day, s));
    if (!due.isAfter(s)) {
      final next = DateTime(s.year, s.month + 1, 1);
      due = DateTime(next.year, next.month, _clampDay(r.day, next));
    }
    if (nextIncome == null || due.isBefore(nextIncome)) nextIncome = due;
  }
  final end = nextIncome != null && nextIncome.difference(s).inDays <= 31
      ? dateKey(nextIncome.subtract(const Duration(days: 1)))
      : dateKey(DateTime(s.year, s.month + 1, 0));

  // ana para: everything before the start day (and, after a
  // recalculation, everything entered on it before that moment), plus the
  // start day's later income, minus its later fixed payments.
  var base = 0.0;
  for (final tx in txs) {
    final c = tx.date.compareTo(start);
    if (c < 0 || (c == 0 && since != null && tx.createdAt <= since)) {
      base += tx.direction == 'income' ? tx.amount : -tx.amount;
    } else if (c == 0) {
      if (tx.direction == 'income') base += tx.amount;
      if (isFixedOutcome(tx, rules)) base -= tx.amount;
    }
  }

  // ödenmezler
  var owed = 0.0;
  for (final o in _obligations(rules, reminders)) {
    if (_owes(o, start, end, txs)) owed += o.amount;
  }

  final days = _d(end).difference(s).inDays + 1;
  return BudgetPeriod(
    start: start,
    end: end,
    base: base,
    fixed: owed,
    daily: (base - owed) / days,
    since: since,
    madeAt: madeAt,
  );
}

/// Brings the stored period list up to [today]: starts tracking today if
/// empty and opens a new period (an automatic recalculation) on each later
/// trigger — see the rule at the top of the file. A period that started
/// today stays live; earlier ones are frozen.
List<BudgetPeriod> ensurePeriods({
  required List<BudgetPeriod> stored,
  required String today,
  required List<Transaction> txs,
  required List<RecurringRule> rules,
  required List<Obligation> reminders,
  int? nowMs,
}) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  BudgetPeriod compute(String start, {int? since}) => computePeriod(
    start: start,
    txs: txs,
    rules: rules,
    reminders: reminders,
    since: since,
    madeAt: now,
  );
  final obligations = _obligations(rules, reminders);
  final list = [...stored];
  if (list.isEmpty) list.add(compute(today));
  final incomeDays = {
    for (final tx in txs)
      if (tx.direction == 'income') tx.date,
  }.toList()..sort();
  String? earlier(String? a, String? b) =>
      a == null ? b : (b == null || a.compareTo(b) <= 0 ? a : b);
  while (true) {
    final last = list.last;
    if (last.start == today) {
      // Live until the day is over — but keep the stored copy (and its
      // madeAt) when nothing changed, so a reload never rewrites settings
      // (that would re-trigger the provider in an endless loop).
      final fresh = compute(today, since: last.since);
      if (!_sameValues(fresh, last)) list[list.length - 1] = fresh;
      break;
    }
    String? next;
    // Money came in on a later day.
    for (final day in incomeDays) {
      if (day.compareTo(last.start) > 0 && day.compareTo(today) <= 0) {
        next = day;
        break;
      }
    }
    // The period ran out.
    final afterEnd = _addDays(last.end, 1);
    if (afterEnd.compareTo(today) <= 0) next = earlier(next, afterEnd);
    // A bill due inside the period enters its 5-day window.
    final until = last.end.compareTo(today) < 0 ? last.end : today;
    for (
      var day = _addDays(last.start, 1);
      day.compareTo(until) <= 0;
      day = _addDays(day, 1)
    ) {
      final due = _d(_addDays(day, 5));
      if (dateKey(due).compareTo(last.end) <= 0 &&
          obligations.any((o) => _clampDay(o.day, due) == due.day)) {
        next = earlier(next, day);
        break;
      }
    }
    // An income was entered (for any date) after the period was computed.
    final madeAt = last.madeAt;
    if (madeAt != null &&
        txs.any((tx) => tx.direction == 'income' && tx.createdAt > madeAt)) {
      next = earlier(next, today);
    }
    if (next == null) break;
    list.add(compute(next));
  }
  return list;
}

bool _sameValues(BudgetPeriod a, BudgetPeriod b) =>
    a.start == b.start &&
    a.end == b.end &&
    a.base == b.base &&
    a.fixed == b.fixed &&
    a.since == b.since;

/// Walks every tracked day up to [today], carrying overspend forward.
Map<String, DayStatus> dayStatuses({
  required List<BudgetPeriod> periods,
  required String today,
  required List<Transaction> txs,
  required List<RecurringRule> rules,
}) {
  final spentByDay = <String, double>{};
  for (final tx in txs) {
    if (tx.direction == 'outcome' && !isFixedOutcome(tx, rules)) {
      spentByDay[tx.date] = (spentByDay[tx.date] ?? 0) + tx.amount;
    }
  }
  final out = <String, DayStatus>{};
  for (var i = 0; i < periods.length; i++) {
    final p = periods[i];
    var last = p.end.compareTo(today) < 0 ? p.end : today;
    if (i + 1 < periods.length) {
      final beforeNext = _addDays(periods[i + 1].start, -1);
      if (beforeNext.compareTo(last) < 0) last = beforeNext;
    }
    var carry = 0.0;
    for (var day = p.start; day.compareTo(last) <= 0; day = _addDays(day, 1)) {
      final status = DayStatus(
        date: day,
        limit: p.daily - carry,
        spent: p.since != null && day == p.start
            ? _spentSince(txs, rules, day, p.since!)
            : spentByDay[day] ?? 0,
        period: p,
      );
      out[day] = status;
      carry = status.diff < 0 ? -status.diff : 0;
    }
  }
  return out;
}

double _spentSince(
  List<Transaction> txs,
  List<RecurringRule> rules,
  String day,
  int since,
) => txs
    .where(
      (tx) =>
          tx.date == day &&
          tx.createdAt > since &&
          tx.direction == 'outcome' &&
          !isFixedOutcome(tx, rules),
    )
    .fold(0.0, (a, tx) => a + tx.amount);

class DailyBudget {
  const DailyBudget({
    required this.periods,
    required this.statuses,
    required this.balance,
  });

  final List<BudgetPeriod> periods;

  /// Money left right now: all income − all outcome.
  final double balance;
  final Map<String, DayStatus> statuses; // date → status, oldest first
}

List<BudgetPeriod> _parsePeriods(Map<String, String> settings) {
  final raw = settings[kDailyPeriodsKey];
  if (raw == null || raw.isEmpty) return [];
  try {
    return [
      for (final e in jsonDecode(raw) as List)
        BudgetPeriod.fromJson(e as Map<String, dynamic>),
    ];
  } catch (_) {
    return [];
  }
}

typedef _Inputs = ({
  Map<String, String> settings,
  List<RecurringRule> rules,
  List<Transaction> txs,
  List<Obligation> reminders,
});

Future<_Inputs> _loadInputs(AppDatabase db) async {
  final settings = await SettingsRepository(db).loadAll();
  final reminderRows = await db.select(db.expenseReminders).join([
    innerJoin(
      db.transactions,
      db.transactions.id.equalsExp(db.expenseReminders.transactionId),
    ),
  ]).get();
  return (
    settings: settings,
    rules: parseRecurringRules(settings),
    txs: await db.select(db.transactions).get(),
    reminders: <Obligation>[
      for (final row in reminderRows)
        (
          day: int.parse(
            row.readTable(db.expenseReminders).remindDate.substring(8),
          ),
          amount: row.readTable(db.transactions).amount,
          category: row.readTable(db.transactions).category,
          from: row.readTable(db.transactions).date,
        ),
    ],
  );
}

List<BudgetPeriod> _ensure(_Inputs inputs, String today) => ensurePeriods(
  stored: _parsePeriods(inputs.settings),
  today: today,
  txs: inputs.txs,
  rules: inputs.rules,
  reminders: inputs.reminders,
);

Future<void> _save(
  AppDatabase db,
  _Inputs inputs,
  List<BudgetPeriod> periods,
) async {
  final encoded = jsonEncode([for (final p in periods) p.toJson()]);
  if (encoded != inputs.settings[kDailyPeriodsKey]) {
    await SettingsRepository(db).set(kDailyPeriodsKey, encoded);
  }
}

Future<DailyBudget> loadDailyBudget(AppDatabase db, {DateTime? now}) async {
  final today = dateKey(now ?? DateTime.now());
  final inputs = await _loadInputs(db);
  final periods = _ensure(inputs, today);
  await _save(db, inputs, periods);
  return DailyBudget(
    periods: periods,
    balance: inputs.txs.fold(
      0,
      (a, tx) => a + (tx.direction == 'income' ? tx.amount : -tx.amount),
    ),
    statuses: dayStatuses(
      periods: periods,
      today: today,
      txs: inputs.txs,
      rules: inputs.rules,
    ),
  );
}

/// "Yeniden hesapla": starts a new period right now from the money left.
/// Past days keep their frozen values; only today onward changes.
Future<BudgetPeriod> recalculateDailyBudget(
  AppDatabase db, {
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final today = dateKey(at);
  final inputs = await _loadInputs(db);
  final periods = _ensure(inputs, today);
  final fresh = computePeriod(
    start: today,
    txs: inputs.txs,
    rules: inputs.rules,
    reminders: inputs.reminders,
    since: at.millisecondsSinceEpoch,
    madeAt: at.millisecondsSinceEpoch,
  );
  if (periods.last.start == today) {
    periods[periods.length - 1] = fresh;
  } else {
    periods.add(fresh);
  }
  await _save(db, inputs, periods);
  return fresh;
}

/// Re-evaluates on every money write and settings change.
final dailyBudgetProvider = StreamProvider<DailyBudget>((ref) {
  final db = ref.watch(databaseProvider);
  ref.watch(recurringRulesProvider);
  return ref
      .watch(moneyRepositoryProvider)
      .changes()
      .asyncMap((_) => loadDailyBudget(db));
});
