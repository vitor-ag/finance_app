import 'package:drift/native.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/data/local/database.dart';
import 'package:finance_app/features/salary/salary_payment.dart';
import 'package:finance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'salary plans the net installment and posts it after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(393, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'Banco', type: 'checking'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Salário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar parcela'));
      await tester.pumpAndSettle();

      Future<void> fill(String label, String value) async {
        final field = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await fill('Nome', 'Pagamento final');
      await fill('Bruto desta parcela', '2500');
      await fill('Descontos nesta parcela', '450');
      final repeat = find.widgetWithText(SwitchListTile, 'Repetir todo mês');
      await tester.ensureVisible(repeat);
      await tester.tap(repeat);
      await tester.pumpAndSettle();
      final save = find.text('Salvar parcela');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final first = await db.select(db.transactions).getSingle();
      expect(first.status, 'pending');
      expect(first.amountCents, 205000);
      expect((await db.select(db.accounts).getSingle()).currentBalanceCents, 0);
      final schedule = await db.select(db.recurrences).getSingle();
      expect(schedule.entryStatus, 'pending');
      expect(schedule.amountCents, 205000);

      await tester.tap(find.text('Pagamento final'));
      await tester.pumpAndSettle();
      await fill('Variável desta parcela', '125');
      final received = find.widgetWithText(SwitchListTile, 'Já recebi');
      await tester.ensureVisible(received);
      await tester.tap(received);
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final settled = await db.select(db.transactions).getSingle();
      expect(settled.status, 'paid');
      expect(settled.amountCents, 217500);
      expect(SalaryPayment.fromNote(settled.note)?.variable, 12500);
      expect(
        (await db.select(db.accounts).getSingle()).currentBalanceCents,
        217500,
      );
      expect((await db.select(db.recurrences).getSingle()).amountCents, 205000);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    },
  );
}
