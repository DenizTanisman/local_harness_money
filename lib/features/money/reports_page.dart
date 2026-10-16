import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../theme/app_tokens.dart';
import 'money_providers.dart';

/// Monthly income/outcome trend over the last 12 months plus a net summary
/// and the biggest spending categories across the whole history.
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allTransactionsProvider).value ?? const [];
    final theme = Theme.of(context);

    // Aggregate per YYYY-MM.
    final income = <String, double>{};
    final outcome = <String, double>{};
    final byCategory = <String, double>{};
    for (final t in all) {
      final ym = t.date.substring(0, 7);
      if (t.direction == 'income') {
        income[ym] = (income[ym] ?? 0) + t.amount;
      } else {
        outcome[ym] = (outcome[ym] ?? 0) + t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final months = {...income.keys, ...outcome.keys}.toList()..sort();
    final shown = months.length > 12
        ? months.sublist(months.length - 12)
        : months;
    final maxVal = [
      1.0,
      for (final m in shown) ...[income[m] ?? 0, outcome[m] ?? 0],
    ].reduce((a, b) => a > b ? a : b);

    final topCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: all.isEmpty
          ? const Center(child: Text('Veri yok'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Aylık gelir / gider (son ${shown.length} ay)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final m in shown)
                          _MonthBars(
                            month: m,
                            income: income[m] ?? 0,
                            outcome: outcome[m] ?? 0,
                            maxVal: maxVal,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(AppTokens.moneyGreen, 'Gelir'),
                    const SizedBox(width: 16),
                    _legend(AppTokens.danger, 'Gider'),
                  ],
                ),
                const Divider(height: 32),
                _SummaryRows(income: income, outcome: outcome, shown: shown),
                const Divider(height: 32),
                Text(
                  'En çok harcanan kategoriler (tüm zamanlar)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final e in topCats.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key),
                        Text(
                          '${formatAmount(e.value)} ₺',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTokens.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 4),
      Text(label),
    ],
  );
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.month,
    required this.income,
    required this.outcome,
    required this.maxVal,
  });

  final String month;
  final double income;
  final double outcome;
  final double maxVal;

  @override
  Widget build(BuildContext context) {
    const maxH = 150.0;
    Widget bar(double v, Color c) => Container(
      width: 12,
      height: (v / maxVal * maxH).clamp(2.0, maxH),
      decoration: BoxDecoration(
        color: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar(income, AppTokens.moneyGreen),
              const SizedBox(width: 3),
              bar(outcome, AppTokens.danger),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            month.substring(5),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({
    required this.income,
    required this.outcome,
    required this.shown,
  });

  final Map<String, double> income;
  final Map<String, double> outcome;
  final List<String> shown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgOut = shown.isEmpty
        ? 0.0
        : shown.fold<double>(0, (a, m) => a + (outcome[m] ?? 0)) / shown.length;
    final thisM = shown.isNotEmpty ? shown.last : null;
    final prevM = shown.length >= 2 ? shown[shown.length - 2] : null;
    final thisOut = thisM == null ? 0.0 : (outcome[thisM] ?? 0);
    final prevOut = prevM == null ? 0.0 : (outcome[prevM] ?? 0);
    final delta = thisOut - prevOut;

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        row('Ortalama aylık gider', '${formatAmount(avgOut)} ₺'),
        row('Bu ay gider', '${formatAmount(thisOut)} ₺'),
        row(
          'Geçen aya göre',
          '${delta >= 0 ? '+' : '−'}${formatAmount(delta.abs())} ₺',
          color: delta > 0 ? AppTokens.danger : AppTokens.moneyGreen,
        ),
      ],
    );
  }
}
