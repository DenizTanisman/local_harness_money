import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../theme/pill_buttons.dart';
import '../notifications/notification_providers.dart';
import 'day_money_editor.dart';
import 'money_providers.dart';

/// Money card body (spec 6.2): Income | Outcome buttons opening an inline
/// form; outcome asks for optional MONTHLY reminders before saving.
class MoneyCardBody extends ConsumerStatefulWidget {
  const MoneyCardBody({super.key});

  @override
  ConsumerState<MoneyCardBody> createState() => _MoneyCardBodyState();
}

class _MoneyCardBodyState extends ConsumerState<MoneyCardBody> {
  String? _direction; // null = collapsed
  final _amount = TextEditingController();
  final _subtype = TextEditingController();
  String? _category;
  final Set<int> _reminders = {};

  @override
  void dispose() {
    _amount.dispose();
    _subtype.dispose();
    super.dispose();
  }

  void _toggle(String direction) {
    setState(() {
      if (_direction == direction) {
        _direction = null;
      } else {
        _direction = direction;
        _category = null;
        _amount.clear();
        _subtype.clear();
        _reminders.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PillToggleButton(
                label: 'Income',
                selected: _direction == 'income',
                onTap: () => _toggle('income'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillToggleButton(
                label: 'Outcome',
                selected: _direction == 'outcome',
                onTap: () => _toggle('outcome'),
              ),
            ),
          ],
        ),
        if (_direction != null) _form(_direction!),
        // Editable breakdown of what was already entered for the active day.
        DayMoneyEditor(date: ref.watch(moneyDateProvider)),
      ],
    );
  }

  Widget _form(String direction) {
    final categories = ref.watch(moneyCategoriesProvider(direction));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('money-amount'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              suffixText: 'TL',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          categories.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (rows) => Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('money-category'),
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final c in rows)
                        DropdownMenuItem(value: c.name, child: Text(c.name)),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ),
                IconButton(
                  key: const ValueKey('money-new-category'),
                  icon: const Icon(Icons.add),
                  tooltip: 'New category',
                  onPressed: () => _newCategory(direction),
                ),
              ],
            ),
          ),
          if (_category != null) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('money-subtype'),
              controller: _subtype,
              decoration: InputDecoration(
                labelText: 'Subtype? (optional — e.g. ${_category!} (home))',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          if (direction == 'outcome') ...[
            const SizedBox(height: 8),
            Text(
              'Aylık hatırlatma? (her ay tekrar eder)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final day in _reminders.toList()..sort())
                  InputChip(
                    label: Text('Her ayın $day. günü'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _reminders.remove(day)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_alert, size: 16),
                  label: const Text('Gün ekle'),
                  onPressed: _pickReminderDay,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('money-save'),
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool get _canSave => _category != null && (parseNum(_amount.text) ?? -1) >= 0;

  Future<void> _pickReminderDay() async {
    final day = await showDialog<int>(
      context: context,
      builder: (_) => const DayOfMonthPicker(),
    );
    if (day != null) setState(() => _reminders.add(day));
  }

  Future<void> _newCategory(String direction) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewCategoryDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(moneyRepositoryProvider).addCategory(direction, name);
    setState(() => _category = name.trim());
  }

  Future<void> _save() async {
    final direction = _direction!;
    await ref
        .read(moneyRepositoryProvider)
        .addTransaction(
          date: ref.read(moneyDateProvider),
          direction: direction,
          amount: parseNum(_amount.text)!,
          category: _category!,
          subtype: _subtype.text,
          reminderDays: direction == 'outcome' ? _reminders.toList() : const [],
        );
    // Apply the newly queued monthly reminders right away.
    if (direction == 'outcome' && _reminders.isNotEmpty) {
      await ref.read(notificationServiceProvider).rescheduleAll();
    }
    setState(() {
      _direction = null;
    });
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
