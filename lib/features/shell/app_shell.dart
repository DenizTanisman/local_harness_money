import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hub_snapshot_publisher.dart';
import '../../core/secure_window.dart';
import '../money/daily_page.dart';
import '../money/money_providers.dart';
import '../settings/settings_providers.dart';

/// Single-screen shell: the daily page is home (the full Money page opens
/// from its app bar). Owns the app-wide concerns — FLAG_SECURE and
/// re-publishing the hub snapshot when the app leaves the foreground.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _secured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FLAG_SECURE (spec §11.6 / CR-3 §14) — app-wide when enabled.
    // Default off.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(settingsRepositoryProvider).loadAll();
      if (mounted && settings['flag_secure'] == 'true') {
        _secured = true;
        await SecureWindow.enable();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hub contract §5: leave a fresh snapshot behind on the way out.
    if (state == AppLifecycleState.paused) {
      ref.read(hubSnapshotPublisherProvider).publishNow();
    }
    // Always land on today's day when the app comes back.
    if (state == AppLifecycleState.resumed) {
      ref.read(moneyDateProvider.notifier).resetToToday();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_secured) SecureWindow.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const DailyPage();
}
