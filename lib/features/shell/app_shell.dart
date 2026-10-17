import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hub_snapshot_publisher.dart';
import '../../core/secure_window.dart';
import '../../core/date_key.dart';
import '../money/daily_page.dart';
import '../money/money_page.dart';
import '../money/money_providers.dart';
import '../settings/settings_providers.dart';
import 'floating_nav_bar.dart';

/// Two tabs — Takvim (month pages) · Detay (the full Money page) — on the
/// Notes app's floating pill bar, whose round + opens today's entry. Owns
/// the app-wide concerns — FLAG_SECURE and re-publishing the hub snapshot
/// when the app leaves the foreground.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _secured = false;
  int _tab = 0;

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
    // Always land on today's month when the app comes back.
    if (state == AppLifecycleState.resumed) {
      ref.read(moneyDateProvider.notifier).resetToToday();
      if (_tab != 0) setState(() => _tab = 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_secured) SecureWindow.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [DailyPage(), MoneyPage()],
      ),
      // The floating bar sits over the content; pages pad their bottom.
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        index: _tab,
        onSelect: (i) => setState(() => _tab = i),
        items: const [
          NavItem(
            Icons.calendar_month_outlined,
            Icons.calendar_month,
            'Takvim',
          ),
          NavItem(Icons.view_list_outlined, Icons.view_list, 'Detay'),
        ],
        actionIcon: Icons.add,
        actionTooltip: 'Bugüne ekle',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayEntryPage(date: dateKey(DateTime.now())),
          ),
        ),
      ),
    );
  }
}
