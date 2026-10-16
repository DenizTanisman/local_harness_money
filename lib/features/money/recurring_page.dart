import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../data/db/database_provider.dart';
import '../../data/io/money_extras.dart';
import '../settings/settings_providers.dart';
import 'day_money_editor.dart' show DayOfMonthPicker;
import 'money_providers.dart';

/// Recurring auto-transactions: rules that automatically create an income or
/// expense on a chosen day of every month (rent, salary, subscriptions…).
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  Future<void> _persist(WidgetRef ref, List<RecurringRule> rules) async {
    await saveRecurringRules(ref.read(settingsRepositoryProvider), rules);
    // Create anything already due so the user sees it immediately.
    await RecurringApplier(ref.read(databaseProvider)).runOnce();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tekrarlayan işlemler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, rules, null),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: rules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz tekrarlayan işlem yok.\n'
                  'Kira, maaş, abonelik gibi her ay tekrar eden işlemleri '
                  'ekleyin; uygulama o gün otomatik kaydeder.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final r in rules)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.direction == 'income'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      child: Icon(
                        r.direction == 'income'
                            ? Icons.south_west
                            : Icons.north_east,
                        size: 18,
                        color: r.direction == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(
                      '${r.category}'
                      '${r.subtype != null ? ' (${r.subtype})' : ''}',
                    ),
                    subtitle: Text(
                      'Her ayın ${r.day}. günü • '
                      '${r.direction == 'income' ? '+' : '−'}'
                      '${formatAmount(r.amount)} ₺',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, ref, rules, r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _persist(
                              ref,
                              rules.where((x) => x.id != r.id).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<RecurringRule> rules,
    RecurringRule? existing,
  ) async {
    final result = await showDialog<RecurringRule>(
      context: context,
      builder: (_) => _RecurringRuleDialog(rule: existing),
    );
    if (result == null) return;
    final next = [
      for (final r in rules)
        if (r.id != result.id) r,
      result,
    ];
    await _persist(ref, next);
  }
}

class _RecurringRuleDialog extends ConsumerStatefulWidget {
  const _RecurringRuleDialog({this.rule});

  final RecurringRule? rule;

  @override
  ConsumerState<_RecurringRuleDialog> createState() =>
      _RecurringRuleDialogState();
}

class _RecurringRuleDialogState extends ConsumerState<_RecurringRuleDialog> {
  late String _direction = widget.rule?.direction ?? 'outcome';
  late String? _category = widget.rule?.category;
  late int _day = widget.rule?.day ?? 1;
  late final TextEditingController _amount = TextEditingController(
    text: widget.rule == null ? '' : formatAmount(widget.rule!.amount),
  );
  late final TextEditingController _subtype = TextEditingController(
    text: widget.rule?.subtype ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.rule?.note ?? '',
  );

  @override
  void dispose() {
    _amount.dispose();
    _subtype.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(moneyCategoriesProvider(_direction)).value ?? const [];
    final names = {for (final c in categories) c.name, ?_category}.toList();

    return AlertDialog(
      title: Text(widget.rule == null ? 'Yeni tekrarlayan' : 'Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'income', label: Text('Gelir')),
                ButtonSegment(value: 'outcome', label: Text('Gider')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: names.contains(_category) ? _category : null,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final n in names)
                  DropdownMenuItem(value: n, child: Text(n)),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                suffixText: 'TL',
              ),
            ),
            TextField(
              controller: _subtype,
              decoration: const InputDecoration(
                labelText: 'Alt tür (isteğe bağlı)',
              ),
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Açıklama (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDialog<int>(
                  context: context,
                  builder: (_) => const DayOfMonthPicker(),
                );
                if (d != null) setState(() => _day = d);
              },
              icon: const Icon(Icons.event_repeat),
              label: Text('Her ayın $_day. günü'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final amount = parseNum(_amount.text);
            if (amount == null || amount < 0 || _category == null) return;
            final subtype = _subtype.text.trim();
            final note = _note.text.trim();
            Navigator.pop(
              context,
              RecurringRule(
                id:
                    widget.rule?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                direction: _direction,
                amount: amount,
                category: _category!,
                day: _day,
                subtype: subtype.isEmpty ? null : subtype,
                note: note.isEmpty ? null : note,
                lastApplied: widget.rule?.lastApplied ?? '',
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
