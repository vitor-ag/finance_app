import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create a card, register a purchase and pay the statement', (
    tester,
  ) async {
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
    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartões de crédito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartão'));
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
    await tester.tap(find.text('Compra'));
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
    expect(find.text('Limite disponível R\$ 400,00'), findsOneWidget);
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
    expect(find.text('Limite disponível R\$ 500,00'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 100,00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  });
}
