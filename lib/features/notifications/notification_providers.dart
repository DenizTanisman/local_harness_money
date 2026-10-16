import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database_provider.dart';
import '../money/money_providers.dart';
import 'notification_service.dart';

/// App-wide navigator, so a notification tap can pop back to the Money page.
final navigatorKey = GlobalKey<NavigatorState>();

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(databaseProvider),
    onTapPayload: (payload) {
      // Notification entry always lands on TODAY (CR1-D), on the Money
      // page — the app's only home.
      ref.read(moneyDateProvider.notifier).resetToToday();
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    },
  );
});
