import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// One sparkline day on the Money General page (spec 6.5).
class MoneyDayPoint {
  const MoneyDayPoint({required this.luxury, required this.overBudget});

  /// Sum of discretionary (Food + Market + Shopping) outcome that day.
  final double luxury;

  /// discretionary spend > dailyBudget → red dot, else green.
  final bool overBudget;
}

class CategoryTotal {
  const CategoryTotal({
    required this.name,
    required this.total,
    this.subtypes = const [],
  });

  final String name;
  final double total;

  /// 'Bill (home)' style breakdown — only subtyped rows appear here;
  /// totals are always per category (spec §9.2).
  final List<({String label, double total})> subtypes;
}

class MoneyGeneral {
  const MoneyGeneral({
    required this.dailyBudget,
    required this.days,
    required this.income,
    required this.outcome,
  });

  /// (month income − month essential outcome) / days in month.
  final double dailyBudget;

  /// Day of month → point; days without any outcome are absent.
  final Map<int, MoneyDayPoint> days;

  final List<CategoryTotal> income;
  final List<CategoryTotal> outcome;
}

/// One visual row of the Monthly table (spec 6.5): income on the left,
/// date in the middle, outcome on the right.
class MonthlyTableRow {
  const MonthlyTableRow({required this.date, this.income, this.outcome});

  final String date;
  final Transaction? income;
  final Transaction? outcome;
}

class MoneyRepository {
  MoneyRepository(this.db);

  final AppDatabase db;

  Stream<void> changes() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.transactions, db.moneyCategories, db.expenseReminders},
      )
      .watch()
      .map((_) {});

  // ---------- categories ----------

  Stream<List<MoneyCategory>> watchCategories(String direction) {
    final query = db.select(db.moneyCategories)
      ..where((c) => c.direction.equals(direction))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch();
  }

  Future<int> addCategory(String direction, String name) async {
    final max = db.moneyCategories.sortOrder.max();
    final row = await (db.selectOnly(
      db.moneyCategories,
    )..addColumns([max])).getSingle();
    return db
        .into(db.moneyCategories)
        .insert(
          MoneyCategoriesCompanion.insert(
            direction: direction,
            name: name.trim(),
            sortOrder: Value((row.read(max) ?? 0) + 1),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // ---------- transactions ----------

  /// All of one [date]'s transactions, oldest first — the editable
  /// per-day breakdown under the money form.
  Stream<List<Transaction>> watchDayTransactions(String date) {
    final query = db.select(db.transactions)
      ..where((t) => t.date.equals(date))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  /// Every transaction, newest first — feeds Search and Reports.
  Stream<List<Transaction>> watchAllTransactions() {
    final query = db.select(db.transactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch();
  }

  /// Active reminders joined with their transaction's category/direction —
  /// feeds the Upcoming payments view (each recurs monthly on its day).
  Stream<List<({int id, int day, String category, String direction})>>
  watchUpcomingReminders() {
    final query = db.select(db.expenseReminders).join([
      innerJoin(
        db.transactions,
        db.transactions.id.equalsExp(db.expenseReminders.transactionId),
      ),
    ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            id: row.readTable(db.expenseReminders).id,
            day: reminderDayOfMonth(
              row.readTable(db.expenseReminders).remindDate,
            ),
            category: row.readTable(db.transactions).category,
            direction: row.readTable(db.transactions).direction,
          ),
      ],
    );
  }

  /// Flat list of [month]'s transactions, newest first (CR-3 §4 İşlemler).
  Stream<List<Transaction>> watchTransactions(String month) {
    final query = db.select(db.transactions)
      ..where((t) => t.date.like('$month-%'))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch();
  }

  /// Saves a transaction; for outcomes, [reminderDays] (each a day-of-month
  /// 1–31) queue MONTHLY-recurring reminders that fire every month on that
  /// day until muted.
  Future<int> addTransaction({
    required String date,
    required String direction,
    required double amount,
    required String category,
    String? subtype,
    String? note,
    List<int> reminderDays = const [],
  }) {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              date: date,
              direction: direction,
              amount: amount,
              category: category,
              subtype: Value(_clean(subtype)),
              note: Value(_clean(note)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (direction == 'outcome') {
        for (final day in reminderDays) {
          await addMonthlyReminder(id, day);
        }
      }
      return id;
    });
  }

  /// Edits any field of an existing transaction. [date] and [direction] are
  /// now editable too (any value of any record can be changed).
  Future<void> updateTransaction(
    int id, {
    String? date,
    String? direction,
    double? amount,
    String? category,
    String? subtype,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        date: date != null ? Value(date) : const Value.absent(),
        direction: direction != null ? Value(direction) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        subtype: Value(_clean(subtype)),
        note: Value(_clean(note)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteTransaction(int id) =>
      (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();

  // ---------- monthly recurring reminders ----------

  /// A reminder's recurring day-of-month (1–31) is stored in the day part of
  /// [remindDate]; the sentinel year/month are ignored. These helpers keep the
  /// encoding in one place so no schema change was needed.
  static String monthlyReminderMarker(int day) =>
      '2000-01-${day.toString().padLeft(2, '0')}';

  static int reminderDayOfMonth(String remindDate) =>
      int.parse(remindDate.substring(8));

  /// Reminders queued for one transaction, by day-of-month.
  Stream<List<ExpenseReminder>> watchReminders(int transactionId) {
    final query = db.select(db.expenseReminders)
      ..where((r) => r.transactionId.equals(transactionId))
      ..orderBy([(r) => OrderingTerm.asc(r.remindDate)]);
    return query.watch();
  }

  /// Adds a MONTHLY reminder for an existing expense: it fires on [day]
  /// (1–31) of every month, at 10:00, until muted. Adding the same day twice
  /// for one transaction is ignored.
  Future<int> addMonthlyReminder(int transactionId, int day) async {
    final marker = monthlyReminderMarker(day.clamp(1, 31));
    final existing =
        await (db.select(db.expenseReminders)..where(
              (r) =>
                  r.transactionId.equals(transactionId) &
                  r.remindDate.equals(marker),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.expenseReminders)
        .insert(
          ExpenseRemindersCompanion.insert(
            transactionId: transactionId,
            remindDate: marker,
          ),
        );
  }

  /// Mutes (stops) a recurring reminder by removing it.
  Future<void> deleteReminder(int id) =>
      (db.delete(db.expenseReminders)..where((r) => r.id.equals(id))).go();

  String? _clean(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  // ---------- General view (spec 6.5) ----------

  Stream<MoneyGeneral> watchGeneral(String month) =>
      changes().asyncMap((_) => loadGeneral(month));

  /// Categories the daily budget is meant to cover: eating/drinking (Food +
  /// Market) and online shopping. EVERYTHING ELSE is treated as a fixed
  /// deduction from income. Daily budget formula (per user spec):
  ///   (all income − all non-discretionary outcome) / days in month.
  static const discretionaryCategories = {
    'Yeme-İçme', 'Market', 'Alışveriş', //
    'Food', 'Shopping',
  };

  Future<MoneyGeneral> loadGeneral(String month) async {
    final rows = await (db.select(
      db.transactions,
    )..where((t) => t.date.like('$month-%'))).get();

    final parts = month.split('-').map(int.parse).toList();
    final daysInMonth = DateTime(parts[0], parts[1] + 1, 0).day;

    var monthIncome = 0.0;
    var monthNonDiscretionary = 0.0;
    final discretionaryByDay = <int, double>{};
    final outcomeDays = <int>{};
    for (final tx in rows) {
      final day = int.parse(tx.date.substring(8));
      if (tx.direction == 'income') {
        monthIncome += tx.amount;
        continue;
      }
      outcomeDays.add(day);
      if (discretionaryCategories.contains(tx.category)) {
        discretionaryByDay[day] = (discretionaryByDay[day] ?? 0) + tx.amount;
      } else {
        // Rent, bills, subscriptions, transfers, … come straight off income.
        monthNonDiscretionary += tx.amount;
      }
    }
    final dailyBudget = (monthIncome - monthNonDiscretionary) / daysInMonth;

    final days = <int, MoneyDayPoint>{
      for (final day in outcomeDays)
        day: MoneyDayPoint(
          luxury: discretionaryByDay[day] ?? 0,
          overBudget: (discretionaryByDay[day] ?? 0) > dailyBudget,
        ),
    };

    return MoneyGeneral(
      dailyBudget: dailyBudget,
      days: days,
      income: _categoryTotals(rows, 'income'),
      outcome: _categoryTotals(rows, 'outcome'),
    );
  }

  List<CategoryTotal> _categoryTotals(
    List<Transaction> rows,
    String direction,
  ) {
    final byCategory = <String, double>{};
    final bySubtype = <String, Map<String, double>>{};
    for (final tx in rows.where((t) => t.direction == direction)) {
      byCategory[tx.category] = (byCategory[tx.category] ?? 0) + tx.amount;
      if (tx.subtype != null) {
        final subs = bySubtype.putIfAbsent(tx.category, () => {});
        subs[tx.subtype!] = (subs[tx.subtype!] ?? 0) + tx.amount;
      }
    }
    final names = byCategory.keys.toList()
      ..sort((a, b) => byCategory[b]!.compareTo(byCategory[a]!));
    return [
      for (final name in names)
        CategoryTotal(
          name: name,
          total: byCategory[name]!,
          subtypes: [
            for (final sub
                in (bySubtype[name] ?? const <String, double>{}).entries)
              (label: '$name (${sub.key})', total: sub.value),
          ],
        ),
    ];
  }

  // ---------- Monthly table (spec 6.5) ----------

  Stream<List<MonthlyTableRow>> watchMonthlyTable(String month) =>
      changes().asyncMap((_) => loadMonthlyTable(month));

  /// Dynamic rows: a date with N entries on one side spans N rows; dates
  /// with no entries at all do not appear.
  Future<List<MonthlyTableRow>> loadMonthlyTable(String month) async {
    final rows =
        await (db.select(db.transactions)
              ..where((t) => t.date.like('$month-%'))
              ..orderBy([
                (t) => OrderingTerm.asc(t.date),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();

    final byDate =
        <String, ({List<Transaction> income, List<Transaction> outcome})>{};
    for (final tx in rows) {
      final bucket = byDate.putIfAbsent(
        tx.date,
        () => (income: <Transaction>[], outcome: <Transaction>[]),
      );
      (tx.direction == 'income' ? bucket.income : bucket.outcome).add(tx);
    }

    final result = <MonthlyTableRow>[];
    for (final date in byDate.keys.toList()..sort()) {
      final bucket = byDate[date]!;
      final count = bucket.income.length > bucket.outcome.length
          ? bucket.income.length
          : bucket.outcome.length;
      for (var i = 0; i < count; i++) {
        result.add(
          MonthlyTableRow(
            date: date,
            income: i < bucket.income.length ? bucket.income[i] : null,
            outcome: i < bucket.outcome.length ? bucket.outcome[i] : null,
          ),
        );
      }
    }
    return result;
  }
}

/// 'Bill' or 'Bill (home)' display name (spec §9.2 — never string-parsed).
String displayCategory(Transaction tx) =>
    tx.subtype == null ? tx.category : '${tx.category} (${tx.subtype})';
