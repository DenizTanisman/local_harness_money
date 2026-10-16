import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/db/app_database.dart';
import '../data/repositories/money_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'date_key.dart';

/// Watch category ids → Para categories (the watch sends short ASCII ids).
const watchCategories = <String, Map<String, String>>{
  'outcome': {
    'yeme': 'Yeme-İçme',
    'market': 'Market',
    'ulasim': 'Ulaşım',
    'alisveris': 'Alışveriş',
    'eglence': 'Eğlence',
    'saglik': 'Sağlık',
    'diger': 'Diğer',
  },
  'income': {
    'harclik': 'Harçlık',
    'burs': 'Burs',
    'iade': 'İade',
    'diger': 'Diğer gelir',
  },
};

/// One quick entry sent by the Huawei watch app.
class WatchEntry {
  const WatchEntry({
    required this.id,
    required this.date,
    required this.direction,
    required this.amount,
    required this.category,
    this.note,
  });

  final String id;
  final String date;
  final String direction;
  final double amount;
  final String category;
  final String? note;

  /// `{"id":"<ms>","d":"o"|"i","a":12.5,"c":"yeme","n":"Kahve"}` → entry;
  /// null when malformed. The date is the moment it was entered on the
  /// watch (an entry queued offline keeps its own day).
  static WatchEntry? parse(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final direction = switch (j['d']) {
        'i' => 'income',
        'o' => 'outcome',
        _ => null,
      };
      final amount = (j['a'] as num?)?.toDouble();
      final ms = int.tryParse('${j['id']}');
      if (direction == null || amount == null || ms == null) return null;
      if (amount <= 0 || amount > 10000000) return null;
      final names = watchCategories[direction]!;
      final note = (j['n'] as String?)?.trim();
      return WatchEntry(
        id: '$ms',
        date: dateKey(DateTime.fromMillisecondsSinceEpoch(ms)),
        direction: direction,
        amount: amount,
        category: names[j['c']] ?? names['diger']!,
        note: note == null || note.isEmpty ? null : note,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Saves a watch entry once (ids already seen are ignored, so a resend after
/// a lost acknowledgement never doubles it). Returns whether it was added.
Future<bool> applyWatchEntry(AppDatabase db, WatchEntry entry) async {
  const seenKey = 'watch_seen_ids';
  final settings = SettingsRepository(db);
  final seen = ((await settings.loadAll())[seenKey] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toList();
  if (seen.contains(entry.id)) return false;
  await MoneyRepository(db).addTransaction(
    date: entry.date,
    direction: entry.direction,
    amount: entry.amount,
    category: entry.category,
    note: entry.note,
  );
  seen.add(entry.id);
  await settings.set(
    seenKey,
    seen.skip(seen.length > 200 ? seen.length - 200 : 0).join(','),
  );
  return true;
}

/// Listens for entries from the Huawei watch (see android WatchBridge.kt).
class WatchBridge {
  static const _channel = MethodChannel('local_harness_para/watch');

  static Future<void> start(AppDatabase db) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'entry') return;
      final entry = WatchEntry.parse('${call.arguments}');
      if (entry != null) await applyWatchEntry(db, entry);
    });
    try {
      final status = await _channel.invokeMethod<String>('start');
      debugPrint('watch: $status');
    } on MissingPluginException {
      // Tests / non-Android hosts.
    } catch (_) {
      // No Huawei Health / permission yet — the app works without the watch.
    }
  }
}
