import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'export_service.dart';

/// Per-file report shown to the user after import (spec 10.2).
class ImportReport {
  ImportReport();

  int imported = 0;
  final List<String> skipped = []; // 'row N: reason'

  @override
  String toString() => 'imported $imported, skipped ${skipped.length}';
}

/// Thrown on structural corruption — the surrounding DB transaction rolls
/// back COMPLETELY (spec 10.2 acceptance: partial imports never happen).
class ImportFormatException implements Exception {
  ImportFormatException(this.message);

  final String message;

  @override
  String toString() => 'ImportFormatException: $message';
}

class ImportService {
  ImportService(this.db);

  final AppDatabase db;

  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Imports a transactions.csv in the export format. Bad date or direction
  /// → row skipped and reported; structural errors (wrong column count,
  /// unparsable amount) → ImportFormatException → full rollback.
  Future<ImportReport> importTransactionsCsv(String csvText) async {
    const parser = CsvDecoder();
    final rows = parser
        .convert(csvText.replaceAll('\r\n', '\n'))
        .where((r) => r.isNotEmpty && r.join().trim().isNotEmpty)
        .toList();
    if (rows.isEmpty) throw ImportFormatException('empty file');
    final header = rows.first.map((c) => c.toString().trim()).toList();
    if (header.join(',') != ExportService.transactionsHeader.join(',')) {
      throw ImportFormatException('unexpected header: ${header.join(',')}');
    }

    final report = ImportReport();
    await db.transaction(() async {
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length != ExportService.transactionsHeader.length) {
          throw ImportFormatException(
            'row ${i + 1}: expected ${ExportService.transactionsHeader.length} '
            'columns, got ${row.length}',
          );
        }
        final date = row[0].toString().trim();
        final direction = row[1].toString().trim();
        if (!_dateRe.hasMatch(date)) {
          report.skipped.add('row ${i + 1}: bad date "$date"');
          continue;
        }
        if (direction != 'income' && direction != 'outcome') {
          report.skipped.add('row ${i + 1}: bad direction "$direction"');
          continue;
        }
        final amount = double.tryParse(row[4].toString().trim());
        if (amount == null || amount < 0) {
          throw ImportFormatException(
            'row ${i + 1}: unparsable amount "${row[4]}"',
          );
        }
        final subtype = row[3].toString().trim();
        final note = row[5].toString().trim();
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                date: date,
                direction: direction,
                amount: amount,
                category: row[2].toString().trim(),
                subtype: Value(subtype.isEmpty ? null : subtype),
                note: Value(note.isEmpty ? null : note),
                createdAt: now,
                updatedAt: now,
              ),
            );
        report.imported++;
      }
    });
    return report;
  }
}
