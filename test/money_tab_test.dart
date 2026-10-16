import 'package:local_harness_para/data/db/app_database.dart';
import 'package:local_harness_para/data/db/database_provider.dart';
import 'package:local_harness_para/features/money/daily_page.dart';
import 'package:local_harness_para/features/money/money_page.dart';
import 'package:local_harness_para/features/shell/app_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// CR3-P2 acceptance: the Money page is the app's home and its inner nav
/// switches by tap; categories can be added.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget app(Widget home) {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    );
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
  }

  testWidgets('inner nav switches by tap (Overview/Transactions/Categories)', (
    tester,
  ) async {
    await pump(tester, const MoneyPage());
    expect(find.textContaining('Balance:'), findsOneWidget); // Overview default

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Outcome categories'), findsOneWidget);
    expect(find.text('Income categories'), findsOneWidget);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Balance:'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('the shell opens straight on the Money page', (tester) async {
    await pump(tester, const AppShell());
    expect(find.byType(DailyPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing); // no 5-tab shell
    expect(find.byKey(const ValueKey('settings-button')), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Categories: adding a category persists', (tester) async {
    await pump(tester, const MoneyPage());
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Groceries');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final cats = await db.select(db.moneyCategories).get();
    expect(cats.where((c) => c.name == 'Groceries'), hasLength(1));
    await closeApp(tester);
  });
}
