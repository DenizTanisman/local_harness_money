import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../core/date_key.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/money_repository.dart';
import '../notifications/notification_providers.dart';
import 'money_providers.dart';
import 'money_reveal.dart';

/// Password-gated edit (then delete-or-update) of one transaction. Shared by
/// the day breakdown and the monthly table. New data is never gated — only
/// changes to existing rows are. Any field can be changed (date, direction,
/// amount, category, subtype, note) and reminders can be added/removed here.
Future<void> editTransactionFlow(
  BuildContext context,
  WidgetRef ref,
  Transaction tx,
) async {
  // Editing is no longer password-gated (user request).
  final result = await showDialog<_EditResult>(
    context: context,
    builder: (_) => _EditTransactionDialog(tx: tx),
  );
  final repo = ref.read(moneyRepositoryProvider);
  if (result != null) {
    if (result.delete) {
      await repo.deleteTransaction(tx.id);
    } else {
      await repo.updateTransaction(
        tx.id,
        date: result.date,
        direction: result.direction,
        amount: result.amount,
        category: result.category,
        subtype: result.subtype,
        note: result.note,
      );
    }
  }
  // Reminders may have been queued/removed live in the dialog, and edits may
  // have changed the category shown on the lock screen — re-apply the queue.
  await ref.read(notificationServiceProvider).rescheduleAll();
}

/// Collapsible per-day Income / Outcome breakdown shown under the money
/// form. Tap any row to edit name / amount / note (password required).
class DayMoneyEditor extends ConsumerWidget {
  const DayMoneyEditor({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(dayTransactionsProvider(date)).value ?? const [];
    if (txs.isEmpty) return const SizedBox.shrink();
    final income = txs.where((t) => t.direction == 'income').toList();
    final outcome = txs.where((t) => t.direction == 'outcome').toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (income.isNotEmpty)
            _DirectionDropdown(rows: income, isIncome: true),
          if (outcome.isNotEmpty)
            _DirectionDropdown(rows: outcome, isIncome: false),
        ],
      ),
    );
  }
}

class _DirectionDropdown extends ConsumerWidget {
  const _DirectionDropdown({required this.rows, required this.isIncome});

  final List<Transaction> rows;
  final bool isIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reveal = ref.watch(moneyRevealProvider);
    final total = rows.fold<double>(0, (a, t) => a + t.amount);
    final dir = isIncome ? 'income' : 'outcome';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: MoneyText(
          id: 'money-day-$dir-total',
          prefix: '${isIncome ? 'Income' : 'Outcome'}: ',
          amount: '${formatAmount(total)} ₺',
          style: theme.textTheme.titleSmall,
        ),
        children: [
          for (final tx in rows)
            Builder(
              builder: (context) {
                final id = 'money-day-tx-${tx.id}';
                final shown = reveal.shows(id);
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 24, right: 12),
                  title: Text(displayCategory(tx)),
                  subtitle: tx.note == null ? null : Text(tx.note!),
                  trailing: MoneyText(
                    id: id,
                    interactive: false,
                    amount:
                        '${isIncome ? '+' : '−'}${formatAmount(tx.amount)} ₺',
                    style: theme.textTheme.bodyMedium,
                  ),
                  // Masked → reveal; revealed → edit. Both password-gated.
                  onTap: () => shown
                      ? editTransactionFlow(context, ref, tx)
                      : revealMoneyFlow(context, ref, id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EditResult {
  const _EditResult({
    this.delete = false,
    this.date,
    this.direction,
    this.amount,
    this.category,
    this.subtype,
    this.note,
  });

  final bool delete;
  final String? date;
  final String? direction;
  final double? amount;
  final String? category;
  final String? subtype;
  final String? note;
}

class _EditTransactionDialog extends ConsumerStatefulWidget {
  const _EditTransactionDialog({required this.tx});

  final Transaction tx;

  @override
  ConsumerState<_EditTransactionDialog> createState() =>
      _EditTransactionDialogState();
}

class _EditTransactionDialogState
    extends ConsumerState<_EditTransactionDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: formatAmount(widget.tx.amount),
  );
  late final TextEditingController _subtype = TextEditingController(
    text: widget.tx.subtype ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.tx.note ?? '',
  );
  late String? _category = widget.tx.category;
  late String _direction = widget.tx.direction;
  late String _date = widget.tx.date; // 'YYYY-MM-DD'

  @override
  void dispose() {
    _amount.dispose();
    _subtype.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDateKey(_date),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateKey(picked));
  }

  Future<void> _addReminder() async {
    final day = await showDialog<int>(
      context: context,
      builder: (_) => const DayOfMonthPicker(),
    );
    if (day == null) return;
    await ref
        .read(moneyRepositoryProvider)
        .addMonthlyReminder(widget.tx.id, day);
    // Apply immediately so the new monthly reminder starts firing.
    await ref.read(notificationServiceProvider).rescheduleAll();
  }

  Future<void> _muteReminder(int id) async {
    await ref.read(moneyRepositoryProvider).deleteReminder(id);
    await ref.read(notificationServiceProvider).rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        ref.watch(moneyCategoriesProvider(_direction)).value ?? const [];
    // Keep the current category selectable even if it was since removed.
    final names = {for (final c in categories) c.name, ?_category}.toList();
    final reminders =
        ref.watch(txRemindersProvider(widget.tx.id)).value ?? const [];

    return AlertDialog(
      title: Text(_direction == 'income' ? 'Geliri düzenle' : 'Gideri düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Direction is editable too (any value of any record).
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'income', label: Text('Gelir')),
                ButtonSegment(value: 'outcome', label: Text('Gider')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 12),
            // Editable date.
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tarih'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_date),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
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
            const SizedBox(height: 16),
            // Monthly recurring reminders — set on any saved expense, any time.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aylık hatırlatmalar',
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 4),
            if (reminders.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in reminders)
                    InputChip(
                      avatar: const Icon(Icons.notifications_active, size: 16),
                      label: Text(
                        'Her ayın '
                        '${MoneyRepository.reminderDayOfMonth(r.remindDate)}. günü',
                      ),
                      deleteIcon: const Icon(Icons.notifications_off, size: 18),
                      deleteButtonTooltipMessage: 'Sustur',
                      onDeleted: () => _muteReminder(r.id),
                    ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Hatırlatma yok', style: theme.textTheme.bodySmall),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alert, size: 18),
                label: const Text('Aylık hatırlatma ekle'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _EditResult(delete: true)),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Sil'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final amount = parseNum(_amount.text);
            if (amount == null || amount < 0 || _category == null) return;
            Navigator.pop(
              context,
              _EditResult(
                date: _date,
                direction: _direction,
                amount: amount,
                category: _category,
                subtype: _subtype.text,
                note: _note.text,
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// Picks a day of the month (1–31) for a monthly recurring reminder.
class DayOfMonthPicker extends StatelessWidget {
  const DayOfMonthPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Her ayın hangi günü?'),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var d = 1; d <= 31; d++)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.pop(context, d),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text('$d'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
