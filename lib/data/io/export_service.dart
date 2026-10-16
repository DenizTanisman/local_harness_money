import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../db/app_database.dart';

/// CSV / Excel export of the money transactions (spec 10.1).
class ExportService {
  ExportService(this.db);

  final AppDatabase db;

  static const transactionsHeader = [
    'date',
    'direction',
    'category',
    'subtype',
    'amount',
    'note',
  ];

  static const _csv = CsvEncoder(lineDelimiter: '\n');

  Future<String> transactionsCsv() async {
    final rows = await (db.select(
      db.transactions,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
    return _csv.convert([
      transactionsHeader,
      for (final t in rows)
        [
          t.date,
          t.direction,
          t.category,
          t.subtype ?? '',
          t.amount,
          t.note ?? '',
        ],
    ]);
  }

  /// The transactions sheet as a single .xlsx (spec 10.1).
  Future<List<int>> excelBytes() async {
    final excel = Excel.createExcel();
    final sheet = excel['transactions'];
    const parser = CsvDecoder();
    for (final row in parser.convert(await transactionsCsv())) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell.toString())]);
    }
    excel.delete('Sheet1');
    return excel.encode()!;
  }

  /// "Download sample CSV" template — export format with 3 example rows
  /// (spec 10.2).
  static String sampleCsv() => _csv.convert([
    transactionsHeader,
    ['2026-06-10', 'income', 'Scholarship', '', 15000, ''],
    ['2026-06-10', 'outcome', 'Bill', 'home', 2000, 'electricity'],
    ['2026-06-11', 'outcome', 'Food', '', 120.5, ''],
  ]);
}
