import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_key.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/io/money_extras.dart';
import '../../data/repositories/money_repository.dart';
import '../settings/settings_providers.dart';

final moneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => MoneyRepository(ref.watch(databaseProvider)),
);

final moneyCategoriesProvider =
    StreamProvider.family<List<MoneyCategory>, String>(
      (ref, direction) =>
          ref.watch(moneyRepositoryProvider).watchCategories(direction),
    );

/// Active write date of the money form (CR1-D): defaults to today, may be
/// moved to any PAST day; the future stays blocked. Never persisted —
/// every app start and notification tap resets to today. (Was the home
/// page's date in the monolith; Money is the whole app now.)
class MoneyDateNotifier extends Notifier<String> {
  @override
  String build() => dateKey(DateTime.now());

  void select(String date) {
    if (date.compareTo(dateKey(DateTime.now())) > 0) return;
    state = date;
  }

  /// Move the selected day by whole months, keeping the day-of-month (clamped
  /// to the target month's length). The future stays blocked.
  void shiftMonths(int months) {
    final parts = state.split('-').map(int.parse).toList();
    final targetLen = DateTime(parts[0], parts[1] + months + 1, 0).day;
    final day = parts[2] < targetLen ? parts[2] : targetLen;
    select(dateKey(DateTime(parts[0], parts[1] + months, day)));
  }

  void resetToToday() => state = dateKey(DateTime.now());
}

final moneyDateProvider = NotifierProvider<MoneyDateNotifier, String>(
  MoneyDateNotifier.new,
);

/// General view for an explicit 'YYYY-MM'.
final moneyGeneralByMonthProvider = StreamProvider.family<MoneyGeneral, String>(
  (ref, month) => ref.watch(moneyRepositoryProvider).watchGeneral(month),
);

/// Net income − outcome for [month] ('YYYY-MM').
double monthBalance(MoneyGeneral general) {
  final income = general.income.fold<double>(0, (a, c) => a + c.total);
  final outcome = general.outcome.fold<double>(0, (a, c) => a + c.total);
  return income - outcome;
}

/// The month shown on the Money page (CR-3 §4) — the month of the
/// selected day. ‹ › move the day by a month so the entry form and the
/// month views stay in sync; reset jumps back to today.
class MoneyMonthNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(moneyDateProvider).substring(0, 7);

  void shift(int months) =>
      ref.read(moneyDateProvider.notifier).shiftMonths(months);

  void reset() => ref.read(moneyDateProvider.notifier).resetToToday();
}

/// Current month 'YYYY-MM' (for highlight/reset comparisons).
String currentMonth() => dateKey(DateTime.now()).substring(0, 7);

final moneyMonthProvider = NotifierProvider<MoneyMonthNotifier, String>(
  MoneyMonthNotifier.new,
);

/// One day's transactions — the editable breakdown under the money form.
final dayTransactionsProvider =
    StreamProvider.family<List<Transaction>, String>(
      (ref, date) =>
          ref.watch(moneyRepositoryProvider).watchDayTransactions(date),
    );

/// Unfired reminders queued for a single transaction (edit dialog).
final txRemindersProvider = StreamProvider.family<List<ExpenseReminder>, int>(
  (ref, txId) => ref.watch(moneyRepositoryProvider).watchReminders(txId),
);

/// Monthly table (income | date | outcome) for the Money tab's month.
final moneyTabTableProvider = StreamProvider<List<MonthlyTableRow>>((ref) {
  return ref
      .watch(moneyRepositoryProvider)
      .watchMonthlyTable(ref.watch(moneyMonthProvider));
});

/// Money-tab transaction list (newest first).
final moneyTabTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref
      .watch(moneyRepositoryProvider)
      .watchTransactions(ref.watch(moneyMonthProvider));
});

/// Every transaction, newest first — Search & Reports.
final allTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(moneyRepositoryProvider).watchAllTransactions(),
);

/// Active reminders with their category/direction — Upcoming payments.
final upcomingRemindersProvider =
    StreamProvider<
      List<({int id, int day, String category, String direction})>
    >((ref) => ref.watch(moneyRepositoryProvider).watchUpcomingReminders());

/// Per-category monthly budget limits {categoryName: limit}.
final categoryBudgetsProvider = Provider<Map<String, double>>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const {};
  return parseCategoryBudgets(settings);
});

/// Recurring auto-transaction rules.
final recurringRulesProvider = Provider<List<RecurringRule>>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const {};
  return parseRecurringRules(settings);
});

/// All money categories (both directions) for the Categories sub-tab.
final allMoneyCategoriesProvider = StreamProvider<List<MoneyCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.moneyCategories)
    ..orderBy([
      (c) => OrderingTerm.asc(c.direction),
      (c) => OrderingTerm.asc(c.sortOrder),
    ]);
  return query.watch();
});
