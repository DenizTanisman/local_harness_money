import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../core/date_key.dart';
import '../../data/io/money_extras.dart';
import '../../theme/app_tokens.dart';
import '../../theme/glow_background.dart';
import 'money_providers.dart';
import 'recurring_page.dart';

/// One upcoming obligation: either a recurring auto-transaction (with amount)
/// or a monthly reminder (category nudge, no amount).
class _Upcoming {
  const _Upcoming({
    required this.date,
    required this.title,
    required this.recurring,
    this.amount,
    this.direction = 'outcome',
  });

  final DateTime date;
  final String title;
  final bool recurring;
  final double? amount;
  final String direction;
}

/// Upcoming payments / bills: recurring auto-transactions and monthly
/// reminders, sorted by their next due date, with this month's remaining
/// recurring-outcome total for cash-flow awareness.
class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key});

  static DateTime _nextDueForDay(int day, DateTime now) {
    var month = DateTime(now.year, now.month, 1);
    for (var i = 0; i < 24; i++) {
      final dim = DateTime(month.year, month.month + 1, 0).day;
      final d = day.clamp(1, dim);
      final candidate = DateTime(month.year, month.month, d);
      if (!candidate.isBefore(DateTime(now.year, now.month, now.day))) {
        return candidate;
      }
      month = DateTime(month.year, month.month + 1, 1);
    }
    return now;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final rules = ref.watch(recurringRulesProvider);
    final reminders = ref.watch(upcomingRemindersProvider).value ?? const [];
    final theme = Theme.of(context);

    final items = <_Upcoming>[
      for (final r in rules)
        _Upcoming(
          date: parseDateKey(nextDueDate(r, now)),
          title: '${r.category}${r.subtype != null ? ' (${r.subtype})' : ''}',
          recurring: true,
          amount: r.amount,
          direction: r.direction,
        ),
      for (final rm in reminders)
        _Upcoming(
          date: _nextDueForDay(rm.day, now),
          title: rm.category,
          recurring: false,
          direction: rm.direction,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    // Cash-flow: recurring outcome still due before this month ends.
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dueThisMonth = items
        .where(
          (i) =>
              i.recurring &&
              i.direction == 'outcome' &&
              !i.date.isAfter(endOfMonth),
        )
        .fold<double>(0, (a, i) => a + (i.amount ?? 0));

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Yaklaşan ödemeler'),
          actions: [
            IconButton(
              tooltip: 'Tekrarlayanları yönet',
              icon: const Icon(Icons.event_repeat),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringPage()),
              ),
            ),
          ],
        ),
        body: items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Yaklaşan ödeme yok.\n'
                    'Tekrarlayan işlem ekleyin ya da bir gidere aylık '
                    'hatırlatma kurun.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    color: AppTokens.danger.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bu ay kalan otomatik gider',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${formatAmount(dueThisMonth)} ₺',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final income = it.direction == 'income';
                        return ListTile(
                          leading: Icon(
                            it.recurring
                                ? Icons.event_repeat
                                : Icons.notifications_active,
                            color: it.recurring
                                ? theme.colorScheme.primary
                                : Colors.orange,
                          ),
                          title: Text(it.title),
                          subtitle: Text(
                            '${dateKey(it.date)}'
                            '${it.recurring ? ' • otomatik' : ' • hatırlatma'}',
                          ),
                          trailing: it.amount == null
                              ? null
                              : Text(
                                  '${income ? '+' : '−'}${formatAmount(it.amount!)} ₺',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: income
                                        ? AppTokens.moneyGreen
                                        : AppTokens.danger,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
