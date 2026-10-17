import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../core/date_key.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/io/money_extras.dart';
import '../../data/repositories/money_repository.dart';
import '../../theme/app_tokens.dart';
import '../../theme/glow_background.dart';
import '../settings/settings_button.dart';
import '../settings/settings_providers.dart';
import 'daily_budget.dart';
import 'day_money_editor.dart';
import 'money_providers.dart';

/// Home screen: one month per page, swiped up/down (current month on
/// open). Each page shows the month's +/− line chart and a calendar with
/// every day's result; tapping a day opens its income/outcome entry.
/// The old full Money page stays one tap away.
class DailyPage extends ConsumerStatefulWidget {
  const DailyPage({super.key});

  static const _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String label(String key) {
    final d = parseDateKey(key);
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// How many months back the pager reaches.
  static const monthsBack = 36;

  @override
  ConsumerState<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends ConsumerState<DailyPage> {
  final _pager = PageController(initialPage: DailyPage.monthsBack);

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Back to the current month whenever the app returns (AppShell resets
    // the date to today on resume).
    ref.listen(moneyDateProvider, (_, _) {
      if (_pager.hasClients) _pager.jumpToPage(DailyPage.monthsBack);
    });
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const _Balance(),
          actions: [
            IconButton(
              key: const ValueKey('daily-recalc'),
              tooltip: 'Yeniden hesapla',
              icon: const Icon(Icons.calculate_outlined),
              onPressed: () => recalculateFlow(context, ref),
            ),
            const SettingsButton(),
          ],
        ),
        body: PageView.builder(
          controller: _pager,
          scrollDirection: Axis.vertical,
          itemCount: DailyPage.monthsBack + 1,
          itemBuilder: (_, i) => _MonthPage(
            month: DateTime(now.year, now.month - DailyPage.monthsBack + i),
          ),
        ),
      ),
    );
  }
}

/// Money left right now, in place of the app title.
class _Balance extends ConsumerWidget {
  const _Balance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balance = ref.watch(dailyBudgetProvider).value?.balance;
    if (balance == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kalan para', style: theme.textTheme.labelMedium),
        Text(
          '${balance < 0 ? '−' : ''}${formatAmount((balance.abs() * 100).round() / 100)} ₺',
          key: const ValueKey('daily-balance'),
          style: theme.textTheme.titleLarge?.copyWith(
            color: balance < 0 ? AppTokens.danger : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// One day's entry screen: spendable summary + Outcome | Income.
class DayEntryPage extends StatelessWidget {
  const DayEntryPage({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(DailyPage.label(date))),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            _Summary(date: date),
            _DayColumns(date: date),
          ],
        ),
      ),
    );
  }
}

/// Confirms, then restarts the daily budget from the money left right now.
/// Past days keep their values; today onward uses the new daily amount.
Future<void> recalculateFlow(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Yeniden hesapla?'),
      content: const Text(
        'Günlük harcanabilir para şu anki kalan paraya göre bugünden '
        'itibaren yeniden hesaplanır. Geçmiş günler değişmez; bugüne kadar '
        'girilenler yeni hesaba dahil olur.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hesapla'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final p = await recalculateDailyBudget(ref.read(databaseProvider));
  ref.invalidate(dailyBudgetProvider);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Yeni günlük: ${formatAmount(p.daily.roundToDouble())} ₺ '
        '(${p.days} gün)',
      ),
    ),
  );
}

String _signed(double v) =>
    '${v >= 0 ? '+' : '−'}${formatAmount(v.abs().roundToDouble())}';

Color _tone(double v) => v >= 0 ? AppTokens.moneyGreen : AppTokens.danger;

// ---------------------------------------------------------- month page

class _MonthPage extends ConsumerWidget {
  const _MonthPage({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statuses = ref.watch(dailyBudgetProvider).value?.statuses ?? const {};
    final days = DateTime(month.year, month.month + 1, 0).day;
    final keys = [
      for (var d = 1; d <= days; d++)
        dateKey(DateTime(month.year, month.month, d)),
    ];
    final monthTotal = keys.fold<double>(
      0,
      (a, k) => a + (statuses[k]?.diff ?? 0),
    );
    final tracked = keys.any(statuses.containsKey);
    return Padding(
      // Bottom room for the floating nav bar (AppShell).
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DailyPage._monthNames[month.month - 1]} ${month.year}',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (tracked)
                Text(
                  '${_signed(monthTotal)} ₺',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _tone(monthTotal),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _MonthChartPainter(
                [for (final k in keys) statuses[k]?.diff],
                dateKey(DateTime.now()).startsWith(keys.first.substring(0, 7))
                    ? DateTime.now().day
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _Calendar(month: month, keys: keys, statuses: statuses),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.keys,
    required this.statuses,
  });

  final DateTime month;
  final List<String> keys;
  final Map<String, DayStatus> statuses;

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateKey(DateTime.now());
    final lead = month.weekday - 1; // Monday first
    final rows = ((lead + keys.length) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _cell(context, r * 7 + c - lead, today)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int index, String today) {
    if (index < 0 || index >= keys.length) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final key = keys[index];
    final future = key.compareTo(today) > 0;
    final s = statuses[key];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: key == today
            ? AppTokens.accentStart.withValues(alpha: 0.25)
            : AppTokens.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('day-$key'),
          borderRadius: BorderRadius.circular(10),
          onTap: future
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DayEntryPage(date: key)),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: future
                      ? AppTokens.textSecondary.withValues(alpha: 0.4)
                      : null,
                ),
              ),
              if (s != null)
                FittedBox(
                  child: Text(
                    _signed(s.diff),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _tone(s.diff),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month's day results as a line (tracked days only) around a zero line.
class _MonthChartPainter extends CustomPainter {
  _MonthChartPainter(this.values, this.todayDay);

  final List<double?> values; // index 0 = day 1; null = not tracked
  final int? todayDay;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / values.length;
    final maxAbs = values.fold<double>(
      1,
      (m, v) => v != null && v.abs() > m ? v.abs() : m,
    );
    final mid = size.height / 2;
    final half = size.height / 2 - 8;
    double x(int i) => i * step + step / 2;
    double y(double v) => mid - v / maxAbs * half;

    if (todayDay != null) {
      canvas.drawLine(
        Offset(x(todayDay! - 1), 0),
        Offset(x(todayDay! - 1), size.height),
        Paint()
          ..color = AppTokens.accentEnd.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
    }
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = AppTokens.textSecondary.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    final line = Path();
    var started = false;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      started ? line.lineTo(x(i), y(v)) : line.moveTo(x(i), y(v));
      started = true;
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppTokens.textAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      canvas.drawCircle(Offset(x(i), y(v)), 3, Paint()..color = _tone(v));
    }
  }

  @override
  bool shouldRepaint(_MonthChartPainter old) => true;
}

// ------------------------------------------------------------ summary

class _Summary extends ConsumerWidget {
  const _Summary({required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budget = ref.watch(dailyBudgetProvider);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: budget.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Hata: $e'),
          data: (b) {
            final s = b.statuses[date];
            if (s == null) {
              return Text(
                'Bu gün takip başlamadan önce.',
                style: theme.textTheme.bodyMedium,
              );
            }
            final p = s.period;
            final small = theme.textTheme.bodySmall;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_signed(s.diff)} ₺',
                  key: const ValueKey('daily-diff'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: _tone(s.diff),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Harcanabilir ${formatAmount(s.limit.roundToDouble())} ₺ · '
                  'Harcanan ${formatAmount(s.spent)} ₺',
                  style: theme.textTheme.bodyMedium,
                ),
                if (s.carriedIn > 0.5)
                  Text(
                    'Önceki günlerin aşımı düşüldü: '
                    '−${formatAmount(s.carriedIn.roundToDouble())} ₺',
                    style: small?.copyWith(color: AppTokens.danger),
                  ),
                const SizedBox(height: 6),
                Text(
                  '(${formatAmount(p.base.roundToDouble())} ana para − '
                  '${formatAmount(p.fixed.roundToDouble())} ödenmez) / '
                  '${p.days} gün = '
                  '${formatAmount(p.daily.roundToDouble())} ₺/gün',
                  style: small,
                ),
                Text(
                  '${DailyPage.label(p.start)} → ${DailyPage.label(p.end)}'
                  '${p.since != null ? ' · yeniden hesaplandı' : ''}',
                  style: small,
                ),
                if (date == dateKey(DateTime.now()))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => recalculateFlow(context, ref),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Yeniden hesapla'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ columns

class _DayColumns extends ConsumerWidget {
  const _DayColumns({required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(dayTransactionsProvider(date)).value ?? const [];
    List<Transaction> of(String dir) =>
        txs.where((t) => t.direction == dir).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TxColumn(
              title: 'Outcome',
              direction: 'outcome',
              date: date,
              items: of('outcome'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TxColumn(
              title: 'Income',
              direction: 'income',
              date: date,
              items: of('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxColumn extends ConsumerWidget {
  const _TxColumn({
    required this.title,
    required this.direction,
    required this.date,
    required this.items,
  });

  final String title;
  final String direction;
  final String date;
  final List<Transaction> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final income = direction == 'income';
    final color = income ? AppTokens.moneyGreen : AppTokens.danger;
    final total = items.fold<double>(0, (a, t) => a + t.amount);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  key: ValueKey('daily-add-$direction'),
                  tooltip: 'Ekle',
                  icon: Icon(Icons.add_circle, color: color),
                  onPressed: () => _add(context, ref),
                ),
              ],
            ),
            Text(
              '${income ? '+' : '−'}${formatAmount(total)} ₺',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const Divider(),
            if (items.isEmpty) Text('—', style: theme.textTheme.bodySmall),
            for (final tx in items) _tile(context, ref, tx, color),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
    Color color,
  ) {
    final theme = Theme.of(context);
    final rules = ref.watch(recurringRulesProvider);
    final rule = ruleFor(tx, rules);
    return InkWell(
      onTap: () => editTransactionFlow(context, ref, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatAmount(tx.amount)} ₺',
                    style: theme.textTheme.bodyLarge?.copyWith(color: color),
                  ),
                  Text(
                    displayCategory(tx) +
                        (isFixedOutcome(tx, rules) ? ' · ödenmez' : ''),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tx.note != null)
                    Text(
                      tx.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (rule != null)
              IconButton(
                tooltip: 'Tekrarı kapat',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.repeat_on, size: 20),
                color: AppTokens.textAccent,
                onPressed: () => _stopRepeat(context, ref, rule),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopRepeat(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tekrarı kapat?'),
        content: Text(
          '${rule.category} ${formatAmount(rule.amount)} ₺ — her ayın '
          '${rule.day}. günü. Girilmiş kayıtlar silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final rules = ref.read(recurringRulesProvider);
    await saveRecurringRules(ref.read(settingsRepositoryProvider), [
      for (final r in rules)
        if (r.id != rule.id) r,
    ]);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result =
        await showDialog<
          ({double amount, String category, String note, bool repeat})
        >(
          context: context,
          builder: (_) => _QuickAddDialog(direction: direction),
        );
    if (result == null) return;
    await ref
        .read(moneyRepositoryProvider)
        .addTransaction(
          date: date,
          direction: direction,
          amount: result.amount,
          category: result.category,
          note: result.note,
        );
    if (!result.repeat) return;
    // Monthly on this day until switched off; this month is already entered.
    await saveRecurringRules(ref.read(settingsRepositoryProvider), [
      ...ref.read(recurringRulesProvider),
      RecurringRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        direction: direction,
        amount: result.amount,
        category: result.category,
        day: parseDateKey(date).day,
        note: result.note.trim().isEmpty ? null : result.note.trim(),
        lastApplied: date.substring(0, 7),
      ),
    ]);
    await RecurringApplier(ref.read(databaseProvider)).runOnce();
  }
}

class _QuickAddDialog extends ConsumerStatefulWidget {
  const _QuickAddDialog({required this.direction});

  final String direction;

  @override
  ConsumerState<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<_QuickAddDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  bool _repeat = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(moneyCategoriesProvider(widget.direction)).value ?? const [];
    _category ??= categories.isEmpty ? null : categories.first.name;
    final amount = parseNum(_amount.text);
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.direction == 'income' ? 'Income ekle' : 'Outcome ekle',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('daily-amount'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tutar',
              suffixText: 'TL',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              for (final c in categories)
                DropdownMenuItem(
                  value: c.name,
                  child: Text(
                    fixedCategories.contains(c.name)
                        ? '${c.name} · ödenmez'
                        : c.name,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('daily-note'),
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Açıklama'),
          ),
          SwitchListTile(
            key: const ValueKey('daily-repeat'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.repeat),
            title: const Text('Tekrarla'),
            subtitle: const Text('Her ay bu gün, sen kapatana kadar'),
            value: _repeat,
            onChanged: (v) => setState(() => _repeat = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const ValueKey('daily-save'),
          onPressed: amount == null || amount <= 0 || _category == null
              ? null
              : () => Navigator.pop(context, (
                  amount: amount,
                  category: _category!,
                  note: _note.text,
                  repeat: _repeat,
                )),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
