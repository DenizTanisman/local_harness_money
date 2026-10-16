import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/amounts.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/money_repository.dart' show displayCategory;
import '../../theme/app_tokens.dart';
import 'day_money_editor.dart' show editTransactionFlow;
import 'money_providers.dart';

/// Search & filter across every transaction: free text (category / subtype /
/// note), direction, category, date range and amount range. Tap a result to
/// edit it.
class TransactionSearchPage extends ConsumerStatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  ConsumerState<TransactionSearchPage> createState() =>
      _TransactionSearchPageState();
}

class _TransactionSearchPageState extends ConsumerState<TransactionSearchPage> {
  final _query = TextEditingController();
  String _direction = 'all'; // all | income | outcome
  String? _category;
  DateTimeRange? _range;
  double? _min;
  double? _max;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Transaction t) {
    if (_direction != 'all' && t.direction != _direction) return false;
    if (_category != null && t.category != _category) return false;
    if (_min != null && t.amount < _min!) return false;
    if (_max != null && t.amount > _max!) return false;
    if (_range != null) {
      final d = t.date;
      final from = _fmtDate(_range!.start);
      final to = _fmtDate(_range!.end);
      if (d.compareTo(from) < 0 || d.compareTo(to) > 0) return false;
    }
    final q = _query.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${t.category} ${t.subtype ?? ''} ${t.note ?? ''}'
          .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allTransactionsProvider).value ?? const [];
    final categories = {for (final t in all) t.category}.toList()..sort();
    final results = all.where(_matches).toList();
    final sum = results.fold<double>(
      0,
      (a, t) => a + (t.direction == 'income' ? t.amount : -t.amount),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ara & filtrele')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Kategori, alt tür veya açıklama ara',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query.clear()),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Hepsi')),
                    ButtonSegment(value: 'income', label: Text('Gelir')),
                    ButtonSegment(value: 'outcome', label: Text('Gider')),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (s) =>
                      setState(() => _direction = s.first),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _category ?? 'Kategori',
                  active: _category != null,
                  onTap: () => _pickCategory(categories),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _range == null
                      ? 'Tarih'
                      : '${_fmtDate(_range!.start).substring(5)} → ${_fmtDate(_range!.end).substring(5)}',
                  active: _range != null,
                  onTap: _pickRange,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: (_min == null && _max == null)
                      ? 'Tutar'
                      : '${_min?.toStringAsFixed(0) ?? '0'}–${_max?.toStringAsFixed(0) ?? '∞'}',
                  active: _min != null || _max != null,
                  onTap: _pickAmount,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} işlem',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Net: ${sum >= 0 ? '+' : '−'}${formatAmount(sum.abs())} ₺',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sum >= 0 ? AppTokens.moneyGreen : AppTokens.danger,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('Sonuç yok'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final t = results[i];
                      final income = t.direction == 'income';
                      return ListTile(
                        dense: true,
                        title: Text(displayCategory(t)),
                        subtitle: Text(
                          '${t.date}${t.note != null ? ' • ${t.note}' : ''}',
                        ),
                        trailing: Text(
                          '${income ? '+' : '−'}${formatAmount(t.amount)} ₺',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: income
                                ? AppTokens.moneyGreen
                                : AppTokens.danger,
                          ),
                        ),
                        onTap: () => editTransactionFlow(context, ref, t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) => FilterChip(
    label: Text(label),
    selected: active,
    onSelected: (_) => onTap(),
    showCheckmark: false,
  );

  Future<void> _pickCategory(List<String> categories) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Tüm kategoriler'),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final c in categories)
              ListTile(title: Text(c), onTap: () => Navigator.pop(context, c)),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _category = picked.isEmpty ? null : picked);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    setState(() => _range = picked ?? _range);
    if (picked == null && _range != null) {
      // long-press style clear not available; offer clear via a second tap.
    }
  }

  Future<void> _pickAmount() async {
    final minC = TextEditingController(text: _min?.toStringAsFixed(0) ?? '');
    final maxC = TextEditingController(text: _max?.toStringAsFixed(0) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutar aralığı'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: maxC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              minC.clear();
              maxC.clear();
              Navigator.pop(context, true);
            },
            child: const Text('Temizle'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _min = double.tryParse(minC.text.trim());
      _max = double.tryParse(maxC.text.trim());
    });
  }
}
