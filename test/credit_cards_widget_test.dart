import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show compactViewport, money, openSettingsPage;

void main() {
  testWidgets('create a card, register a purchase and pay the statement', (
    tester,
  ) async {
    compactViewport(tester);
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
    await openSettingsPage(tester, 'Contas');
    await tester.tap(find.text('Cartões de crédito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo cartão'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome'),
      'Meu cartão',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Limite em R\$'),
      '500',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Dia de fechamento'),
      '20',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Dia de vencimento'),
      '10',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meu cartão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova compra'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Mercado',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor total em R\$'),
      '100',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(money('R\$ 400,00'), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Mercado'), findsOneWidget);
    await tester.tap(find.text('Pagar fatura'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carteira').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar pagamento'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.accounts).getSingle()).currentBalanceCents,
      -10000,
    );
    expect(money('R\$ 500,00'), findsNWidgets(2));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(money('−R\$ 100,00'), findsAtLeastNWidgets(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  });
}
