import 'dart:ui' show DartPluginRegistrant;

import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/db/app_database.dart';
import '../../data/db/open_connection.dart';
import 'notification_planner.dart';

/// Action id for the "Sustur" (mute) button shown on expense reminders.
const _muteActionId = 'mute';

/// Parses the reminder id out of an expense payload like 'money|123'.
int? _reminderIdFromPayload(String payload) {
  final i = payload.indexOf('|');
  if (i < 0) return null;
  return int.tryParse(payload.substring(i + 1));
}

/// Background isolate handler for notification actions (app terminated). Mutes
/// the reminder straight from the notification shade — deletes its row and
/// cancels its upcoming occurrences without opening the app.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  if (response.actionId != _muteActionId) return;
  final rid = _reminderIdFromPayload(response.payload ?? '');
  if (rid == null) return;
  DartPluginRegistrant.ensureInitialized();
  final db = AppDatabase(openEncryptedConnection());
  try {
    await (db.delete(db.expenseReminders)..where((r) => r.id.equals(rid))).go();
  } finally {
    await db.close();
  }
  final plugin = FlutterLocalNotificationsPlugin();
  for (var k = 0; k < NotificationPlanner.expenseMonthsAhead; k++) {
    await plugin.cancel(id: NotificationPlanner.expenseNotificationId(rid, k));
  }
}

/// Thin plugin layer: everything decision-shaped lives in
/// NotificationPlanner; this class only initializes the plugin and applies
/// the plan with zonedSchedule.
class NotificationService {
  NotificationService(this.db, {this.onTapPayload});

  final AppDatabase db;
  final void Function(String payload)? onTapPayload;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Expense reminders, with a "Sustur" action button that mutes them.
  static const _expenseChannel = AndroidNotificationDetails(
    'local_harness_para',
    'Para',
    channelDescription: 'Expense reminders',
    importance: Importance.defaultImportance,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        _muteActionId,
        'Sustur',
        cancelNotification: true,
        showsUserInterface: false,
      ),
    ],
  );

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to the bundled default location.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // Android 13+ runtime permission (spec §8) — asked on first launch.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Foreground / background-with-app-alive handler. The "Sustur" action mutes
  /// the reminder; a plain tap opens the Money page on today.
  Future<void> _onResponse(NotificationResponse response) async {
    final payload = response.payload ?? 'money';
    if (response.actionId == _muteActionId) {
      final rid = _reminderIdFromPayload(payload);
      if (rid != null) {
        await (db.delete(
          db.expenseReminders,
        )..where((r) => r.id.equals(rid))).go();
        await rescheduleAll();
      }
      return;
    }
    onTapPayload?.call(payload.split('|').first);
  }

  /// Recomputes and re-applies the whole schedule. Called on app open;
  /// after a reboot the plugin's boot receiver restores what was scheduled.
  Future<void> rescheduleAll() async {
    if (!_initialized) return;
    final reminderJoin = db.select(db.expenseReminders).join([
      innerJoin(
        db.transactions,
        db.transactions.id.equalsExp(db.expenseReminders.transactionId),
      ),
    ])..where(db.expenseReminders.fired.equals(false));
    final reminders = [
      for (final row in await reminderJoin.get())
        ReminderInput(
          id: row.readTable(db.expenseReminders).id,
          // Day-of-month is stored in the day part of remindDate.
          dayOfMonth: int.parse(
            row.readTable(db.expenseReminders).remindDate.substring(8),
          ),
          // Only the category crosses into the notification layer.
          category: row.readTable(db.transactions).category,
        ),
    ];

    final plan = NotificationPlanner.plan(
      now: DateTime.now(),
      reminders: reminders,
    );

    await _plugin.cancelAll();
    for (final item in plan) {
      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: tz.TZDateTime.from(item.when, tz.local),
        notificationDetails: const NotificationDetails(
          android: _expenseChannel,
        ),
        // Inexact by default — no SCHEDULE_EXACT_ALARM permission (spec §8).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: item.payload,
      );
    }
  }
}
