import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'core/hub_snapshot_publisher.dart';
import 'core/watch_bridge.dart';
import 'data/db/database_provider.dart';
import 'data/io/category_setup.dart';
import 'data/io/fresh_start.dart';
import 'data/io/money_extras.dart';
import 'features/backup/backup_worker.dart';
import 'features/notifications/notification_providers.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Errors must never include DB contents or the backup password
        // (spec §11.7) — only the framework diagnostics are logged.
      };
      Workmanager().initialize(backupCallbackDispatcher);
      final container = ProviderContainer();
      runApp(
        UncontrolledProviderScope(container: container, child: const ParaApp()),
      );
      // Initialize notifications after the first frame; reschedule the whole
      // local queue on every app open (spec §8).
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final db = container.read(databaseProvider);
        // One-shot: general Turkish categories (renames the old ones).
        await CategorySetup(db).runOnce();
        // One-shot: wipe all money data so entry starts from 0.
        await FreshStart(db).runOnce();
        // Create any transactions owed by recurring rules (idempotent).
        await RecurringApplier(db).runOnce();
        // Huawei watch quick entry (no-op without Huawei Health).
        unawaited(WatchBridge.start(db));
        // Hub contract §5: publish once the startup data work is done, then
        // keep the snapshot fresh on every DB write. Must run before
        // notification init — that awaits the Android 13+ permission dialog,
        // and the hub would see no data until the user answers it.
        await container.read(hubSnapshotPublisherProvider).start();
        final service = container.read(notificationServiceProvider);
        await service.init();
        await service.rescheduleAll();
      });
    },
    (error, stack) {
      debugPrint('Uncaught: $error');
    },
  );
}

class ParaApp extends StatelessWidget {
  const ParaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Para',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // Single dark theme built from tokens (CR1-B rule 7).
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
