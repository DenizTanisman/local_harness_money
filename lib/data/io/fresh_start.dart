import '../db/app_database.dart';
import '../repositories/settings_repository.dart';
import 'money_extras.dart';

/// One-shot fresh start (user request, 2026-10-16): wipes every
/// transaction, reminder, recurring rule and daily-budget period so the
/// balance is 0 and entry starts from scratch. Categories and budget
/// limits stay. Flag-gated so it runs only once.
class FreshStart {
  FreshStart(this.db);

  final AppDatabase db;

  static const _flagKey = 'fresh_start_2026_10_16';

  Future<void> runOnce() async {
    final settingsRepo = SettingsRepository(db);
    final settings = await settingsRepo.loadAll();
    if (settings[_flagKey] != null) return;
    await db.transaction(() async {
      await db.delete(db.expenseReminders).go();
      await db.delete(db.transactions).go();
      await (db.delete(db.appSettings)..where(
            (s) => s.key.isIn([kRecurringRulesKey, 'daily_periods']),
          ))
          .go();
      await settingsRepo.set(_flagKey, 'done');
    });
  }
}
