import 'package:finance_app/features/security/data/android_access.dart';
import 'package:finance_app/features/security/domain/local_access.dart';
import 'package:finance_app/features/security/presentation/app_access_gate.dart';
import 'package:finance_app/features/security/presentation/security_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_local_access.dart';

void main() {
  testWidgets('first opening hides the dashboard and checks confirmation', (
    tester,
  ) async {
    final store = FakeAccessStore();
    final access = LocalAccess(store: store, biometrics: FakeAppBiometrics());
    await _pumpApp(tester, access);

    expect(find.text('Crie sua senha'), findsOneWidget);
    expect(find.text('Conteúdo financeiro'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'minha senha');
    await tester.enterText(find.byType(TextFormField).at(1), 'outra senha');
    await tester.tap(find.text('Criar senha'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
    expect(store.record, isNull);
  });

  testWidgets(
    'a brief absence preserves the route and immediate locking removes it',
    (tester) async {
      final store = FakeAccessStore();
      await tester.runAsync(() async {
        final setup = LocalAccess(
          store: store,
          biometrics: FakeAppBiometrics(),
        );
        await setup.load();
        await setup.createPassword('minha senha');
        setup.dispose();
      });
      final access = LocalAccess(store: store, biometrics: FakeAppBiometrics());
      await _pumpApp(tester, access);

      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      expect(find.text('Conteúdo financeiro'), findsNothing);
      await tester.runAsync(() => access.unlockWithPassword('minha senha'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Segurança'));
      await tester.pumpAndSettle();

      _leave(tester);
      await tester.pump();
      expect(find.text('Alterar senha'), findsNothing);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Alterar senha'), findsOneWidget);

      await tester.tap(find.text('30 segundos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imediatamente').last);
      await tester.pumpAndSettle();
      expect(access.lockDelay, Duration.zero);

      _leave(tester);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      expect(find.text('Alterar senha'), findsNothing);
      expect(find.text('Conteúdo financeiro'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _pumpApp(WidgetTester tester, LocalAccess access) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localAccessProvider.overrideWith((_) => access)],
      child: MaterialApp(
        builder: (_, child) => AppAccessGate(child: child!),
        home: Scaffold(
          appBar: AppBar(title: const Text('Conteúdo financeiro')),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('Configurações'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _leave(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
}

void _resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}
