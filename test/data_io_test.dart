import 'dart:io';

import 'package:archive/archive.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/io/backup_service.dart';
import 'package:local_harness_para/data/io/export_service.dart';
import 'package:local_harness_para/data/io/import_service.dart';
import 'package:local_harness_para/data/repositories/money_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 7 acceptance: export → fresh install import → identical data;
/// corrupt CSV rolls back FULLY; backup unreadable without the password.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedData() async {
    final money = MoneyRepository(db);
    await money.addTransaction(
      date: '2026-06-09',
      direction: 'outcome',
      amount: 2000,
      category: 'Bill',
      subtype: 'home',
      note: 'electricity, "tricky, quoted"',
    );
    await money.addTransaction(
      date: '2026-06-10',
      direction: 'income',
      amount: 15000.5,
      category: 'Scholarship',
    );
  }

  group('export → fresh import round trip', () {
    test('transactions survive identically', () async {
      await seedData();
      final txCsv = await ExportService(db).transactionsCsv();

      // Fresh install: a brand-new seeded database.
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final report = await ImportService(fresh).importTransactionsCsv(txCsv);
      expect(report.skipped, isEmpty);
      expect(report.imported, 2);

      final tx = await fresh.select(fresh.transactions).get();
      expect(tx, hasLength(2));
      final bill = tx.firstWhere((t) => t.category == 'Bill');
      expect(bill.subtype, 'home');
      expect(bill.amount, 2000);
      expect(bill.note, 'electricity, "tricky, quoted"');
      final income = tx.firstWhere((t) => t.direction == 'income');
      expect(income.amount, 15000.5);
      expect(income.subtype, isNull);
      expect(income.note, isNull);
    });
  });

  group('import validation (spec 10.2)', () {
    test('bad date and bad direction are skipped and reported', () async {
      const csv =
          'date,direction,category,subtype,amount,note\n'
          '2026-06-09,outcome,Food,,30,\n'
          '2026-06-09,sideways,Food,,1,\n'
          'junk-date,outcome,Food,,2,\n';
      final report = await ImportService(db).importTransactionsCsv(csv);
      expect(report.imported, 1);
      expect(report.skipped, hasLength(2));
      expect(report.skipped[0], contains('bad direction'));
      expect(report.skipped[1], contains('bad date'));
    });

    test('structurally corrupt row rolls back the WHOLE import', () async {
      const csv =
          'date,direction,category,subtype,amount,note\n'
          '2026-06-09,outcome,Food,,30,\n'
          '2026-06-10,outcome,Food,,not-a-number,\n';
      await expectLater(
        ImportService(db).importTransactionsCsv(csv),
        throwsA(isA<ImportFormatException>()),
      );

      // The valid first row must NOT have been kept (full rollback).
      expect(await db.select(db.transactions).get(), isEmpty);
    });

    test('wrong header rejected outright', () async {
      await expectLater(
        ImportService(db).importTransactionsCsv('a,b,c\n1,2,3\n'),
        throwsA(isA<ImportFormatException>()),
      );
    });
  });

  group('encrypted backup (spec 10.3)', () {
    test('backup decrypts with the right password into a valid ZIP', () async {
      await seedData();
      final service = BackupService(db);
      final encrypted = await service.createEncryptedBackup('hunter2');

      final zipBytes = await BackupService.decryptBackup(encrypted, 'hunter2');
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(
        archive.files.map((f) => f.name),
        unorderedEquals(['transactions.csv', 'app_settings.json']),
      );
    });

    test('wrong password cannot open the backup', () async {
      final encrypted = await BackupService(
        db,
      ).createEncryptedBackup('correct');
      await expectLater(
        BackupService.decryptBackup(encrypted, 'wrong'),
        throwsA(anything),
      );
    });

    test('backup bytes contain no plaintext CSV', () async {
      await seedData();
      final encrypted = await BackupService(
        db,
      ).createEncryptedBackup('hunter2');
      final asString = String.fromCharCodes(encrypted);
      expect(asString, isNot(contains('direction')));
      expect(asString, isNot(contains('Bill')));
    });

    test('prune keeps only the newest 8 backups', () async {
      final dir = await Directory.systemTemp.createTemp('para_backups');
      addTearDown(() => dir.delete(recursive: true));
      final service = BackupService(db);
      for (var i = 1; i <= 10; i++) {
        await service.backupTo(dir, 'pw', now: DateTime(2026, 6, i, 3));
      }
      final remaining =
          dir
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last)
              .toList()
            ..sort();
      expect(remaining, hasLength(8));
      expect(
        remaining.every((n) => n.startsWith('local_harness_para_')),
        isTrue,
      );
      expect(remaining.every((n) => n.endsWith('.dtbak')), isTrue);
      // The two oldest (June 1, June 2) were pruned.
      expect(remaining.first, contains('2026-06-03'));
    });

    test('weekly run lands on Sunday 03:00 strictly in the future', () {
      // 2026-06-11 is a Thursday → next Sunday is 06-14.
      expect(
        BackupService.nextWeeklyRun(DateTime(2026, 6, 11, 9)),
        DateTime(2026, 6, 14, 3),
      );
      // Sunday after 03:00 → the following Sunday.
      expect(
        BackupService.nextWeeklyRun(DateTime(2026, 6, 14, 4)),
        DateTime(2026, 6, 21, 3),
      );
      // Sunday before 03:00 → same day.
      expect(
        BackupService.nextWeeklyRun(DateTime(2026, 6, 14, 1)),
        DateTime(2026, 6, 14, 3),
      );
    });
  });

  group('excel export', () {
    test('produces a non-empty xlsx with the transactions sheet', () async {
      await seedData();
      final bytes = await ExportService(db).excelBytes();
      expect(bytes, isNotEmpty);
      // xlsx is a ZIP container.
      final archive = ZipDecoder().decodeBytes(bytes);
      final workbook = archive.files.firstWhere(
        (f) => f.name == 'xl/workbook.xml',
      );
      final xml = String.fromCharCodes(workbook.content as List<int>);
      expect(xml, contains('transactions'));
    });
  });

  group('sample CSV', () {
    test(
      'sample parses through the importer without structural errors',
      () async {
        final report = await ImportService(
          db,
        ).importTransactionsCsv(ExportService.sampleCsv());
        expect(report.imported, 3);
        expect(report.skipped, isEmpty);
      },
    );
  });
}
