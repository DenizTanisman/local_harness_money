import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/io/money_extras.dart';
import '../../data/repositories/money_repository.dart';
import '../../theme/app_tokens.dart';
import '../../theme/glow_background.dart';
import '../settings/settings_button.dart';
import '../settings/settings_providers.dart';
import '../shared/continuous_sparkline.dart';
import '../shared/period_bar.dart';
import 'category_donut.dart';
import 'day_money_editor.dart';
import 'money_card_body.dart';
import 'money_providers.dart';
import 'money_reveal.dart';
import 'recurring_page.dart';
import 'reports_page.dart';
import 'search_page.dart';
import 'upcoming_page.dart';

/// Money page (CR-3 §4) — the app's single home: entry form on top, then a
/// tap-only inner nav (Overview / Table / Categories). FLAG_SECURE is
/// handled app-wide by AppShell (CR-3 §14).
class MoneyPage extends ConsumerStatefulWidget {
  const MoneyPage({super.key});

  @override
  ConsumerState<MoneyPage> createState() => _MoneyPageState();
}

enum _MoneyView { overview, transactions, categories }

class _MoneyPageState extends ConsumerState<MoneyPage> {
  _MoneyView _view = _MoneyView.overview;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(moneyMonthProvider);
    final date = ref.watch(moneyDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detay'),
        actions: [
          IconButton(
            tooltip: 'Ara & filtrele',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionSearchPage()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              final page =
                  switch (v) {
                        'reports' => const ReportsPage(),
                        'upcoming' => const UpcomingPage(),
                        _ => const RecurringPage(),
                      }
                      as Widget;
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reports',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Raporlar'),
                ),
              ),
              PopupMenuItem(
                value: 'upcoming',
                child: ListTile(
                  leading: Icon(Icons.event_available),
                  title: Text('Yaklaşan ödemeler'),
                ),
              ),
              PopupMenuItem(
                value: 'recurring',
                child: ListTile(
                  leading: Icon(Icons.event_repeat),
                  title: Text('Tekrarlayan işlemler'),
                ),
              ),
            ],
          ),
          const SettingsButton(),
        ],
      ),
      body: GlowBackground(
        child: ListView(
          // Bottom room for the floating nav bar (AppShell).
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Shared entry form — only on Overview so Transactions /
            // Categories aren't crowded by it (CR-3 follow-up #7).
            if (_view == _MoneyView.overview)
              Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: MoneyCardBody(key: ValueKey('money-tab-form-$date')),
                ),
              ),
            // Unified month selector (CR-3 follow-up #5).
            PeriodBar(
              label: month,
              highlighted: month != currentMonth(),
              resetLabel: 'This month',
              onReset: () => ref.read(moneyMonthProvider.notifier).reset(),
              onPrev: () => ref.read(moneyMonthProvider.notifier).shift(-1),
              onNext: () => ref.read(moneyMonthProvider.notifier).shift(1),
            ),
            // Choice chips, as in the Notes app's filter row.
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: [
                  for (final (view, text) in const [
                    (_MoneyView.overview, 'Overview'),
                    (_MoneyView.transactions, 'Table'),
                    (_MoneyView.categories, 'Categories'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(text),
                        selected: _view == view,
                        onSelected: (_) => setState(() => _view = view),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            switch (_view) {
              _MoneyView.overview => const _OverviewSection(),
              _MoneyView.transactions => const _MonthlyTableSection(),
              _MoneyView.categories => const _CategoriesSection(),
            },
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Overview

class _OverviewSection extends ConsumerWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(moneyMonthProvider);
    final general = ref.watch(moneyGeneralByMonthProvider(month));
    return general.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
      data: (data) {
        final balance = monthBalance(data);
        final incomeTotal = data.income.fold<double>(0, (a, c) => a + c.total);
        final outcomeTotal = data.outcome.fold<double>(
          0,
          (a, c) => a + c.total,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MoneyText(
                id: 'money-balance',
                prefix: 'Balance: ',
                amount:
                    '${balance >= 0 ? '+' : '−'}${formatAmount(balance.abs())} ₺',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Red/green daily-budget sparkline (spec §6.5 General, kept as
            // an Overview sub-view per CR-3 §4).
            Builder(
              builder: (context) {
                final parts = month.split('-').map(int.parse).toList();
                final days = DateTime(parts[0], parts[1] + 1, 0).day;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: KeyedSubtree(
                    key: const ValueKey('money-sparkline'),
                    child: ContinuousSparkline(
                      daysInMonth: days,
                      values: {
                        for (final e in data.days.entries)
                          e.key: e.value.luxury,
                      },
                      dayColors: moneyDayColors(days, data),
                      lineColor: AppTokens.moneyGreen,
                      selectedDay: 1,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: MoneyText(
                id: 'money-daily-budget',
                prefix: 'Daily budget: ',
                amount: '${formatAmount(data.dailyBudget)} ₺',
                suffix: ' (red = food/market/online over budget)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            CategoryDonut(categories: data.outcome),
            _BudgetsCard(data: data),
            _CategoryBlock(
              key: const ValueKey('income-block'),
              label: 'Income',
              idPrefix: 'income',
              total: incomeTotal,
              categories: data.income,
            ),
            _CategoryBlock(
              key: const ValueKey('outcome-block'),
              label: 'Outcome',
              idPrefix: 'outcome',
              total: outcomeTotal,
              categories: data.outcome,
            ),
          ],
        );
      },
    );
  }
}

/// Collapsible Income/Outcome breakdown (CR1-A style): category total with
/// a 'Bill (home)' subtype breakdown underneath. All amounts masked until
/// revealed (privacy).
class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    super.key,
    required this.label,
    required this.idPrefix,
    required this.total,
    required this.categories,
  });

  final String label;
  final String idPrefix;
  final double total;
  final List<CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: MoneyText(
        id: 'money-$idPrefix-total',
        prefix: '$label: ',
        amount: formatAmount(total),
        style: theme.textTheme.titleMedium,
      ),
      initiallyExpanded: true,
      childrenPadding: const EdgeInsets.only(left: 32, bottom: 8, right: 16),
      children: [
        for (final category in categories) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: MoneyText(
              id: 'money-$idPrefix-${category.name}',
              prefix: '> ${category.name}: ',
              amount: formatAmount(category.total),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          for (final sub in category.subtypes)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MoneyText(
                  id: 'money-$idPrefix-sub-${sub.label}',
                  prefix: '>> ${sub.label}: ',
                  amount: formatAmount(sub.total),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------- Monthly table

/// Income | Date | Outcome table for the Money tab's month (spec 6.5).
/// Tap any income/outcome cell to edit it (password required).
class _MonthlyTableSection extends ConsumerWidget {
  const _MonthlyTableSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(moneyTabTableProvider);
    return table.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No entries this month.'),
          );
        }
        final theme = Theme.of(context);
        final head = theme.textTheme.labelLarge;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Income',
                        style: head,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Date',
                        style: head,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Outcome',
                        style: head,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final row in rows) _TableRow(row: row),
            ],
          ),
        );
      },
    );
  }
}

class _TableRow extends ConsumerWidget {
  const _TableRow({required this.row});

  final MonthlyTableRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reveal = ref.watch(moneyRevealProvider);
    Widget cell(Transaction? tx, bool income) {
      if (tx == null) return const SizedBox.shrink();
      final id = 'money-tx-${tx.id}';
      final shown = reveal.shows(id);
      return InkWell(
        // Masked → reveal (password); revealed → edit (password). Both gated.
        onTap: () => shown
            ? editTransactionFlow(context, ref, tx)
            : revealMoneyFlow(context, ref, id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: income
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              MoneyText(
                id: id,
                interactive: false,
                amount: '${income ? '+' : '−'}${formatAmount(tx.amount)} ₺',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: income ? AppTokens.moneyGreen : AppTokens.danger,
                ),
              ),
              Text(
                displayCategory(tx),
                style: theme.textTheme.bodySmall,
                textAlign: income ? TextAlign.start : TextAlign.end,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: cell(row.income, true)),
            Expanded(
              child: Text(
                row.date.substring(8), // day of month
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(child: cell(row.outcome, false)),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// -------------------------------------------------------------- Categories

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allMoneyCategoriesProvider);
    final budgets = ref.watch(categoryBudgetsProvider);
    final db = ref.watch(databaseProvider);
    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
      data: (rows) {
        Widget section(String direction, String label) {
          final items = rows.where((c) => c.direction == direction).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    TextButton.icon(
                      onPressed: () => _addCategory(context, ref, direction),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              for (final c in items)
                ListTile(
                  title: Text(c.name),
                  subtitle: direction == 'outcome'
                      ? Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Essential'),
                              selected: c.isEssential,
                              onSelected: (v) =>
                                  (db.update(
                                    db.moneyCategories,
                                  )..where((m) => m.id.equals(c.id))).write(
                                    MoneyCategoriesCompanion(
                                      isEssential: Value(v),
                                    ),
                                  ),
                            ),
                          ],
                        )
                      : null,
                  trailing: direction == 'outcome'
                      ? TextButton.icon(
                          icon: const Icon(Icons.savings_outlined, size: 16),
                          label: Text(
                            budgets[c.name] == null
                                ? 'Bütçe'
                                : '${formatAmount(budgets[c.name]!)} ₺',
                          ),
                          onPressed: () =>
                              editCategoryBudget(context, ref, c.name),
                        )
                      : null,
                ),
            ],
          );
        }

        return Column(
          children: [
            section('outcome', 'Outcome categories'),
            const Divider(),
            section('income', 'Income categories'),
          ],
        );
      },
    );
  }

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref,
    String direction,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewCategoryDialog(),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(moneyRepositoryProvider).addCategory(direction, name);
    }
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Per-day line colors for the Money budget sparkline (spec §6.5): red when
/// the day's luxury spend exceeds the daily budget, green otherwise.
/// Index 0 unused; 1..N are days. Used by the Overview chart and tests.
List<Color> moneyDayColors(int daysInMonth, MoneyGeneral general) => [
  AppTokens.moneyGreen,
  for (var day = 1; day <= daysInMonth; day++)
    (general.days[day]?.overBudget ?? false)
        ? AppTokens.moneyRed
        : AppTokens.moneyGreen,
];

// ---------------------------------------------------------------- Budgets

/// Per-category monthly budget limits with progress bars (green→orange→red).
/// Only categories that have a limit set are shown.
class _BudgetsCard extends ConsumerWidget {
  const _BudgetsCard({required this.data});

  final MoneyGeneral data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(categoryBudgetsProvider);
    final theme = Theme.of(context);
    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          'Kategori bütçesi yok — Categories sekmesinden limit ekleyebilirsin.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final spent = {for (final c in data.outcome) c.name: c.total};
    final names = budgets.keys.toList()..sort();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bütçeler', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final name in names)
              Builder(
                builder: (context) {
                  final limit = budgets[name]!;
                  final s = spent[name] ?? 0;
                  final ratio = limit <= 0 ? 0.0 : (s / limit);
                  final color = ratio >= 1
                      ? AppTokens.danger
                      : ratio >= 0.8
                      ? Colors.orange
                      : AppTokens.moneyGreen;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: theme.textTheme.bodyMedium),
                            Text(
                              '${formatAmount(s)} / ${formatAmount(limit)} ₺',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Sets or clears a category's monthly budget limit.
Future<void> editCategoryBudget(
  BuildContext context,
  WidgetRef ref,
  String category,
) async {
  final budgets = ref.read(categoryBudgetsProvider);
  final controller = TextEditingController(
    text: budgets[category] == null ? '' : formatAmount(budgets[category]!),
  );
  final result = await showDialog<double?>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$category aylık bütçe'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Limit (boş = bütçe yok)',
          suffixText: 'TL',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final raw = controller.text
                .trim()
                .replaceAll('.', '')
                .replaceAll(',', '.');
            Navigator.pop(
              context,
              raw.isEmpty ? 0.0 : double.tryParse(raw) ?? 0.0,
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (result == null) return;
  final next = {...budgets};
  if (result > 0) {
    next[category] = result;
  } else {
    next.remove(category);
  }
  await saveCategoryBudgets(ref.read(settingsRepositoryProvider), next);
}
