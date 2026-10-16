import 'package:flutter_test/flutter_test.dart';
import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/io/money_extras.dart';
import 'package:local_harness_para/features/money/daily_budget.dart';

var _id = 0;
Transaction tx(String date, String dir, double amount, [String cat = 'Food']) =>
    Transaction(
      id: ++_id,
      date: date,
      direction: dir,
      amount: amount,
      category: cat,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  test('until month end; a bill counts only from 5 days before it', () {
    final p = computePeriod(
      start: '2026-10-21',
      txs: [
        tx('2026-10-01', 'income', 12000),
        tx('2026-09-25', 'outcome', 1000, 'Fatura'), // previous one paid
        tx('2026-10-03', 'outcome', 999, 'Abonelik'), // previous one paid
      ],
      rules: const [],
      reminders: const [
        (day: 25, amount: 1000, category: 'Fatura', from: '2026-09-25'),
        (day: 3, amount: 999, category: 'Abonelik', from: '2026-09-03'),
      ],
    );
    expect(p.end, '2026-10-31');
    expect(p.days, 11);
    expect(p.base, 12000 - 1000 - 999);
    expect(p.fixed, 1000); // Oct 25 is 4 days away; Nov 3 is outside
  });

  test('an unpaid previous bill is owed right away', () {
    final p = computePeriod(
      start: '2026-10-15',
      txs: [tx('2026-10-01', 'income', 3000)],
      rules: const [],
      reminders: const [
        (day: 8, amount: 500, category: 'Fatura', from: '2026-09-08'),
      ],
    );
    expect(p.fixed, 500); // Oct 8 was not paid
  });

  test('no previous one yet → waits for the 5-day window', () {
    final p = computePeriod(
      start: '2026-10-15',
      txs: [tx('2026-10-01', 'income', 3000)],
      rules: const [],
      reminders: const [
        (day: 8, amount: 500, category: 'Fatura', from: '2026-10-12'),
      ],
    );
    expect(p.fixed, 0);
  });

  test('expected income within a month sets the end', () {
    final p = computePeriod(
      start: '2026-10-16',
      txs: [tx('2026-10-01', 'income', 1500)],
      rules: const [
        RecurringRule(id: 'a', direction: 'income', amount: 9000, category: 'Scholarship', day: 26),
      ],
      reminders: const [],
    );
    expect(p.end, '2026-10-25');
    expect(p.daily, 150);
  });

  test('overspend carries forward day by day, plus does not', () {
    const p = BudgetPeriod(start: '2026-10-01', end: '2026-10-31', base: 0, fixed: 0, daily: 100);
    final s = dayStatuses(
      periods: [p],
      today: '2026-10-05',
      txs: [
        tx('2026-10-01', 'outcome', 40), // +60
        tx('2026-10-02', 'outcome', 350), // −250
        tx('2026-10-03', 'outcome', 0), // limit −150 → −150
        tx('2026-10-04', 'outcome', 999, 'Bill'), // fixed: ignored → limit −50
      ],
      rules: const [],
    );
    expect(s['2026-10-01']!.diff, 60);
    expect(s['2026-10-02']!.diff, -250);
    expect(s['2026-10-03']!.diff, -150);
    expect(s['2026-10-04']!.diff, -50);
    expect(s['2026-10-05']!.limit, 50);
  });

  test('frozen after start day; new income opens a new period', () {
    final txs = [tx('2026-10-01', 'income', 3100)];
    var periods = ensurePeriods(stored: const [], today: '2026-10-01', txs: txs, rules: const [], reminders: const []);
    expect(periods.single.daily, 100);
    // Later edits to the past do not move a frozen period.
    txs.add(tx('2026-09-01', 'income', 99999));
    periods = ensurePeriods(stored: periods, today: '2026-10-05', txs: txs, rules: const [], reminders: const []);
    expect(periods.single.daily, 100);
    txs.add(tx('2026-10-10', 'income', 5000));
    periods = ensurePeriods(stored: periods, today: '2026-10-12', txs: txs, rules: const [], reminders: const []);
    expect(periods.length, 2);
    expect(periods.last.start, '2026-10-10');
  });

  test('a repeated Food outcome is ödenmez, other Food is spending', () {
    const rules = [
      RecurringRule(id: 'r', direction: 'outcome', amount: 300, category: 'Food', day: 2),
    ];
    const p = BudgetPeriod(start: '2026-10-01', end: '2026-10-31', base: 0, fixed: 0, daily: 100);
    final s = dayStatuses(
      periods: [p],
      today: '2026-10-02',
      txs: [tx('2026-10-02', 'outcome', 300), tx('2026-10-02', 'outcome', 30)],
      rules: rules,
    );
    expect(s['2026-10-02']!.spent, 30);
  });

  test('recalculation: money left now, only later spending counts today', () {
    Transaction at(String date, String dir, double amount, int created, [String cat = 'Yeme-İçme']) =>
        Transaction(id: ++_id, date: date, direction: dir, amount: amount, category: cat, createdAt: created, updatedAt: created);
    final txs = [
      at('2026-10-01', 'income', 6000, 1),
      at('2026-10-17', 'outcome', 1500, 10), // big spend before recalculation
    ];
    final p = computePeriod(start: '2026-10-17', txs: txs, rules: const [], reminders: const [], since: 20);
    expect(p.base, 4500);
    expect(p.daily, 300); // 4500 / 15 days (17–31)
    txs.add(at('2026-10-17', 'outcome', 100, 30));
    txs.add(at('2026-10-17', 'income', 1500, 40)); // later income same day
    final periods = ensurePeriods(stored: [p], today: '2026-10-17', txs: txs, rules: const [], reminders: const []);
    expect(periods.single.base, 6000);
    final s = dayStatuses(periods: periods, today: '2026-10-17', txs: txs, rules: const []);
    expect(s['2026-10-17']!.spent, 100);
  });

  test("the user's case: paid October rent, November rent waits", () {
    final txs = [
      tx('2026-10-05', 'income', 14750, 'Harçlık'),
      tx('2026-10-05', 'outcome', 14750, 'Kira'),
      tx('2026-10-06', 'income', 4000, 'Burs'),
    ];
    const rules = [
      RecurringRule(id: 'k', direction: 'outcome', amount: 14750, category: 'Kira', day: 5),
      RecurringRule(id: 'b', direction: 'income', amount: 4000, category: 'Burs', day: 6),
    ];
    final p = computePeriod(start: '2026-10-16', txs: txs, rules: rules, reminders: const []);
    expect(p.end, '2026-11-05');
    expect(p.base, 4000);
    expect(p.fixed, 0);
    expect(p.daily, closeTo(190.48, 0.01));

    // On Oct 31 (5 days before Nov 5) the rent enters and it recalculates.
    final periods = ensurePeriods(
      stored: [p],
      today: '2026-10-31',
      txs: txs,
      rules: rules,
      reminders: const [],
      nowMs: 100,
    );
    expect(periods.length, 2);
    expect(periods.last.start, '2026-10-31');
    expect(periods.last.fixed, 14750);
  });

  test('an income entered later for a past date recalculates today', () {
    final txs = [tx('2026-10-01', 'income', 3100)];
    final first = ensurePeriods(stored: const [], today: '2026-10-01', txs: txs, rules: const [], reminders: const [], nowMs: 5);
    final late = Transaction(id: ++_id, date: '2026-09-20', direction: 'income', amount: 1000, category: 'İade', createdAt: 50, updatedAt: 50);
    final periods = ensurePeriods(stored: first, today: '2026-10-10', txs: [...txs, late], rules: const [], reminders: const [], nowMs: 60);
    expect(periods.last.start, '2026-10-10');
    expect(periods.last.base, 4100);
  });

  test('reloading the same day does not change the stored periods', () {
    final txs = [tx('2026-10-16', 'income', 3000)];
    final a = ensurePeriods(stored: const [], today: '2026-10-16', txs: txs, rules: const [], reminders: const [], nowMs: 1);
    final b = ensurePeriods(stored: a, today: '2026-10-16', txs: txs, rules: const [], reminders: const [], nowMs: 2);
    expect(b.single.toJson(), a.single.toJson());
  });
}
