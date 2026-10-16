import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_harness_para/core/date_key.dart';
import 'package:local_harness_para/core/watch_bridge.dart';
import 'package:local_harness_para/data/db/app_database.dart';

void main() {
  final ms = DateTime(2026, 10, 16, 12).millisecondsSinceEpoch;

  test('parses a watch entry and maps the category', () {
    final e = WatchEntry.parse('{"id":"$ms","d":"o","a":45.5,"c":"yeme","n":"Kahve"}')!;
    expect(e.direction, 'outcome');
    expect(e.amount, 45.5);
    expect(e.category, 'Yeme-İçme');
    expect(e.note, 'Kahve');
    expect(e.date, dateKey(DateTime(2026, 10, 16)));
  });

  test('unknown category falls back to Diğer; bad input is rejected', () {
    expect(WatchEntry.parse('{"id":"$ms","d":"i","a":10,"c":"x"}')!.category, 'Diğer gelir');
    expect(WatchEntry.parse('{"id":"$ms","d":"o","a":-1,"c":"yeme"}'), isNull);
    expect(WatchEntry.parse('{"d":"o","a":5}'), isNull);
    expect(WatchEntry.parse('not json'), isNull);
  });

  test('the same entry is saved only once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final e = WatchEntry.parse('{"id":"$ms","d":"o","a":20,"c":"market"}')!;
    expect(await applyWatchEntry(db, e), isTrue);
    expect(await applyWatchEntry(db, e), isFalse);
    final txs = await db.select(db.transactions).get();
    expect(txs.single.category, 'Market');
  });
}
