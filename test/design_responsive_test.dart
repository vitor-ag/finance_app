import 'package:drift/native.dart';
import 'package:finance_app/core/design/adaptive_scaffold.dart';
import 'package:finance_app/core/design/app_theme.dart';
import 'package:finance_app/core/design/balance_card.dart';
import 'package:finance_app/core/design/components.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final (family, asset) in [
      ('Outfit', 'assets/fonts/Outfit.ttf'),
      ('Inter', 'assets/fonts/Inter.ttf'),
      (
        'packages/material_symbols_icons/${Symbols.home_rounded.fontFamily}',
        'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      ),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final (width, height) in [
    (360, 640),
    (700, 852),
    (1000, 660),
    (1400, 900),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'navigation and balance at $width × $height in ${brightness.name}',
        (tester) async {
          _resize(tester, width.toDouble(), height.toDouble());
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Theme(
                  data: appTheme(brightness, WindowSizeClass.of(context), 0),
                  child: AdaptiveScaffold(
                    index: 0,
                    onSelect: (_) {},
                    creating: false,
                    onNew: () {},
                    onSettings: () {},
                    onSearch: () {},
                    body: Scaffold(
                      appBar: AppBar(title: const Text('Olá, Alex')),
                      body: AppContent(
                        child: ListView(
                          padding: AppLayout.pagePadding(context),
                          children: [
                            BalanceCard(
                              balance: BigInt.from(497050),
                              income: BigInt.from(620000),
                              expense: BigInt.from(122950),
                            ),
                            const SizedBox(height: 24),
                            const AppSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Orçamento de alimentação'),
                                  SizedBox(height: 12),
                                  BudgetProgressBar(
                                    progress: .82,
                                    label: 'Orçamento',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(AdaptiveScaffold),
            matchesGoldenFile('goldens/design_${width}_${brightness.name}.png'),
          );
        },
      );
    }
  }

  testWidgets(
    'resizing retains the selected destination, transaction search and draft amount',
    (tester) async {
      _resize(tester, 393, 852);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'Carteira', type: 'cash'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lançamentos'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'mercado');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      expect(find.text('mercado'), findsOneWidget);
      final add = find.byTooltip('Novo lançamento').hitTestable().first;
      await tester.tap(add);
      await tester.pumpAndSettle();
      final amount = find.widgetWithText(TextField, r'Valor (R$)');
      await tester.enterText(amount, '27,50');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(700, 420);
      await tester.pumpAndSettle();
      expect(find.text('27,50'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    },
  );

  testWidgets('navigation exposes accessible actions at 200% text scale', (
    tester,
  ) async {
    _resize(tester, 320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ocultar valores'), findsOneWidget);
      expect(find.bySemanticsLabel('Planejar'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Planejar'));
      await tester.pumpAndSettle();
      expect(find.text('Orçamentos'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    }
  });
}

void _resize(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
