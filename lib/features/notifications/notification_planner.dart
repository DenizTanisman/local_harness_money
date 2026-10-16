/// What to schedule, computed purely so it can be unit-tested.
/// The thin plugin layer (NotificationService) just applies this list.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    this.body,
    required this.payload,
  });

  final int id;
  final DateTime when;
  final String title;
  final String? body;

  /// `money|<reminderId>` — tap routing + the "Sustur" mute action (spec §8).
  final String payload;
}

/// A monthly expense reminder (id + day-of-month + CATEGORY ONLY — amounts
/// never reach the notification layer, spec §8/§11.4).
class ReminderInput {
  const ReminderInput({
    required this.id,
    required this.dayOfMonth,
    required this.category,
  });

  final int id;

  /// 1–31; clamped to the last day of short months when scheduled.
  final int dayOfMonth;
  final String category;
}

class NotificationPlanner {
  static const expenseBaseId = 30000;
  static const expenseHour = 10;

  /// How many upcoming monthly occurrences of each reminder are scheduled
  /// ahead. Refreshed on every app open / boot, so the window keeps sliding.
  static const expenseMonthsAhead = 4;

  /// Stable notification id for the [k]-th upcoming occurrence of reminder
  /// [reminderId]. Used by both the planner and the mute action.
  static int expenseNotificationId(int reminderId, int k) =>
      expenseBaseId + reminderId * expenseMonthsAhead + k;

  /// Monthly recurring expense reminders: the next few occurrences of each,
  /// on its day-of-month (clamped to short months), at 10:00.
  static List<PlannedNotification> plan({
    required DateTime now,
    required List<ReminderInput> reminders,
  }) {
    final result = <PlannedNotification>[];
    for (final reminder in reminders) {
      for (var k = 0; k < expenseMonthsAhead; k++) {
        final base = DateTime(now.year, now.month + k, 1);
        final daysInMonth = DateTime(base.year, base.month + 1, 0).day;
        final day = reminder.dayOfMonth.clamp(1, daysInMonth);
        final when = DateTime(base.year, base.month, day, expenseHour);
        if (!when.isAfter(now)) continue;
        // CATEGORY NAME ONLY — never the amount (lock-screen leak, spec §8).
        // payload carries the reminder id so the "Sustur" action can mute it.
        result.add(
          PlannedNotification(
            id: expenseNotificationId(reminder.id, k),
            when: when,
            title: 'Reminder: ${reminder.category}',
            payload: 'money|${reminder.id}',
          ),
        );
      }
    }
    return result;
  }
}
