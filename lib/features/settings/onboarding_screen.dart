import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/design/adaptive_scaffold.dart';
import '../../core/design/app_preferences.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/category_style.dart';
import '../../core/design/components.dart';
import '../../core/money.dart';
import '../../core/providers/database_provider.dart';
import '../../core/widgets/record_actions.dart';
import '../accounts/domain/entities/account.dart';
import '../accounts/presentation/providers/account_providers.dart';
import '../categories/domain/entities/category.dart';
import '../categories/presentation/providers/category_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.preferences});
  final AppPreferences preferences;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _balance = TextEditingController();
  int _step = 0;
  bool _saving = false;
  bool _createdAccount = false;
  static const _slides = [
    (
      Symbols.pie_chart_rounded,
      'Suas finanças, do seu jeito',
      'Acompanhe o saldo, registre gastos e planeje o que vem pela frente.',
    ),
    (
      Symbols.lock_rounded,
      'Tudo fica no seu celular',
      'Registre e consulte suas finanças mesmo sem internet. Você escolhe se quer criar ou compartilhar backups.',
    ),
    (
      Symbols.account_balance_wallet_rounded,
      'Vamos começar',
      'Crie a primeira conta para ver seu saldo no Início.',
    ),
  ];

  @override
  void dispose() {
    _name.dispose();
    _account.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skip}) async {
    if (_saving || !skip && !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (!skip && !_createdAccount) {
        final db = ref.read(databaseProvider);
        final accounts = ref.read(accountRepositoryProvider);
        final categories = ref.read(categoryRepositoryProvider);
        final cents = parseBrlCents(_balance.text) ?? 0;
        await db.transaction(() async {
          await accounts.createAccount(
            Account(
              name: _account.text.trim(),
              type: 'cash',
              initialBalanceCents: cents,
              currentBalanceCents: cents,
              createdAt: DateTime.now(),
              icon: 'wallet',
            ),
          );
          if (await (db.select(db.categories)..limit(1)).getSingleOrNull() ==
              null) {
            for (final (index, preset) in defaultExpenseCategories.indexed) {
              await categories.createCategory(
                Category(
                  name: preset.$1,
                  type: 'expense',
                  icon: preset.$2,
                  color: colorHex(AppColors.categoryPalette[index]),
                ),
              );
            }
            await categories.createCategory(
              const Category(name: 'Salário', type: 'income', icon: 'payments'),
            );
          }
        });
        _createdAccount = true;
      }
      await widget.preferences.finishOnboarding(_name.text.trim());
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showRecordError(
        context,
        error,
        'Não foi possível concluir a configuração.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smallHeight = MediaQuery.sizeOf(context).height < 480;
    final wide =
        WindowSizeClass.of(context) != WindowSizeClass.compact || smallHeight;
    final setup = _step >= _slides.length;
    final (icon, title, message) = setup
        ? (
            Symbols.account_balance_wallet_rounded,
            'Sua primeira conta',
            'Use o saldo que a conta tem hoje.',
          )
        : _slides[_step];
    final graphic = Center(
      child: BrandShapes(icon: icon, size: smallHeight ? 112 : 208),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (_step == 1) const PrivacyLabel(),
        if (!setup) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _slides.length; i++) ...[
                Semantics(
                  label: 'Etapa ${i + 1} de ${_slides.length}',
                  selected: i == _step,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    width: i == _step ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppLayout.pill),
                      color: i == _step
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ] else
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome (opcional)',
                  ),
                  maxLength: 40,
                ),
                const InputDecorator(
                  decoration: InputDecoration(labelText: 'Moeda'),
                  child: Text('Real brasileiro (BRL)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _account,
                  decoration: const InputDecoration(labelText: 'Nome da conta'),
                  maxLength: 60,
                  validator: (value) => value?.trim().isEmpty != false
                      ? 'Informe um nome para a conta.'
                      : null,
                ),
                TextFormField(
                  controller: _balance,
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial (R\$)',
                    hintText: '0,00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) =>
                      value?.trim().isNotEmpty == true &&
                          parseBrlCents(value) == null
                      ? 'Informe um saldo válido.'
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: AppContent(
          maxWidth: wide && !setup ? 880 : 480,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: _saving ? null : () => _finish(skip: true),
                    child: Text(setup ? 'Agora não' : 'Pular'),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: wide && !setup
                        ? Row(
                            children: [
                              Expanded(child: graphic),
                              const SizedBox(width: 24),
                              Expanded(child: details),
                            ],
                          )
                        : Column(children: [if (!setup) graphic, details]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : setup
                        ? () => _finish(skip: false)
                        : () => setState(() => _step++),
                    child: Text(
                      _saving
                          ? 'Salvando…'
                          : setup
                          ? 'Criar primeira conta'
                          : 'Continuar',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
