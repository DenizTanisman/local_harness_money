import 'dart:io';

import 'package:local_harness_para/features/notifications/notification_planner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 6 acceptance: amounts NEVER appear in notification content;
/// monthly reminder timing; stable ids for the "Sustur" mute action.
void main() {
  final now = DateTime(2026, 6, 11, 9, 0);

  List<PlannedNotification> planWith(List<ReminderInput> reminders) =>
      NotificationPlanner.plan(now: now, reminders: reminders);

  group('expense reminders never leak amounts (spec §8/§11.4)', () {
    test('content is category-only by construction', () {
      final plan = planWith([
        const ReminderInput(id: 7, dayOfMonth: 13, category: 'Bill'),
      ]);
      expect(plan, hasLength(NotificationPlanner.expenseMonthsAhead));
      final first = plan.first;
      expect(first.title, 'Reminder: Bill');
      expect(first.body, isNull);
      expect(first.payload, 'money|7');
      expect(first.when, DateTime(2026, 6, 13, 10, 0));
      // Paranoid sweep: nothing numeric beyond the category name.
      for (final item in plan) {
        expect(item.title.contains(RegExp(r'\d')), isFalse);
      }
    });

    test('whole plan never contains TL-like amounts', () {
      final plan = planWith([
        const ReminderInput(id: 1, dayOfMonth: 12, category: 'Rent'),
        const ReminderInput(id: 2, dayOfMonth: 28, category: 'Aidat'),
      ]);
      for (final item in plan) {
        final text = '${item.title} ${item.body ?? ''}';
        expect(
          text.contains(RegExp(r'\d+([.,]\d+)?\s*TL')),
          isFalse,
          reason: text,
        );
      }
    });
  });

  group('monthly schedule', () {
    test("a day already passed this month starts next month", () {
      final plan = planWith([
        const ReminderInput(id: 1, dayOfMonth: 10, category: 'Bill'),
      ]);
      expect(plan.first.when, DateTime(2026, 7, 10, 10, 0));
      expect(plan, hasLength(NotificationPlanner.expenseMonthsAhead - 1));
    });

    test('day 31 is clamped to short months', () {
      final plan = planWith([
        const ReminderInput(id: 1, dayOfMonth: 31, category: 'Bill'),
      ]);
      expect(plan.map((p) => p.when), [
        DateTime(2026, 6, 30, 10),
        DateTime(2026, 7, 31, 10),
        DateTime(2026, 8, 31, 10),
        DateTime(2026, 9, 30, 10),
      ]);
    });

    test('ids are stable and never collide across reminders', () {
      final plan = planWith([
        const ReminderInput(id: 1, dayOfMonth: 20, category: 'A'),
        const ReminderInput(id: 2, dayOfMonth: 20, category: 'B'),
      ]);
      final ids = plan.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.first, NotificationPlanner.expenseNotificationId(1, 0));
    });

    test('no reminders → nothing scheduled (no quotes/evening nudges)', () {
      expect(planWith(const []), isEmpty);
    });
  });

  group('boot recovery (spec §8)', () {
    test('manifest registers BOOT_COMPLETED receiver and permission', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
      expect(manifest, contains('POST_NOTIFICATIONS'));
      expect(
        manifest,
        isNot(contains('android.permission.SCHEDULE_EXACT_ALARM')),
        reason: 'inexact alarms by default',
      );
    });
  });
}
