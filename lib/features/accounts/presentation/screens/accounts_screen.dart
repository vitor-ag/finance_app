import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/record_actions.dart';
import '../../../credit_cards/presentation/credit_cards_screen.dart';
import '../../domain/entities/account.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _showAccountForm(
    BuildContext context,
    WidgetRef ref, {
    Account? account,
  }) async {
    final form = GlobalKey<FormState>();
    var name = account?.name ?? '';
    var balance = 0;
    var selectedType = account?.type ?? 'digital';
    var saving = false;
    var color = account?.color;
    var icon = account?.icon;
    const types = {
      'digital': 'Conta Digital',
      'checking': 'Conta Corrente',
      'savings': 'Poupança',
      'cash': 'Dinheiro / Carteira',
      'investment': 'Investimentos',
    };
    final repo = ref.read(accountRepositoryProvider);

    await showAppBottomSheet<void>(
      context: context,
      width: 480,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account == null ? 'Nova Conta' : 'Editar Conta',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      onSaved: (value) => name = value!.trim(),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty || text.length > 60) {
                          return 'Digite um nome de 1 a 60 caracteres.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Nome da Conta (ex: Nubank, Carteira)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Conta',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final entry in types.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        if (account != null && !types.containsKey(account.type))
                          DropdownMenuItem(
                            value: account.type,
                            child: Text(account.type),
                          ),
                      ],
                      onChanged: (val) => setState(() => selectedType = val!),
                    ),
                    if (account == null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          final input = value?.trim() ?? '';
                          final parsed = parseBrlCents(input);
                          return input.isEmpty || parsed != null
                              ? null
                              : 'Informe um saldo válido.';
                        },
                        onSaved: (value) => balance = parseBrlCents(value) ?? 0,
                        decoration: const InputDecoration(
                          labelText: 'Saldo Inicial (R\$)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Cor', style: Theme.of(context).textTheme.titleSmall),
                    ColorPalette(
                      value: color,
                      onChanged: (value) => setState(() => color = value),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Ícone da conta'),
                      children: [
                        IconPalette(
                          value: icon,
                          onChanged: (value) => setState(() => icon = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final state = form.currentState!;
                                if (!state.validate()) return;
                                state.save();
                                setState(() => saving = true);
                                try {
                                  if (account == null) {
                                    await repo.createAccount(
                                      Account(
                                        name: name,
                                        type: selectedType,
                                        color: color,
                                        icon: icon,
                                        initialBalanceCents: balance,
                                        currentBalanceCents: balance,
                                        createdAt: DateTime.now(),
                                      ),
                                    );
                                  } else {
                                    await repo.updateAccount(
                                      account.copyWith(
                                        name: name,
                                        type: selectedType,
                                        color: color,
                                        icon: icon,
                                      ),
                                    );
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setState(() => saving = false);
                                  showRecordError(
                                    context,
                                    error,
                                    'Não foi possível salvar a conta.',
                                  );
                                }
                              },
                        child: const Text('Salvar Conta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _archiveAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final repo = ref.read(accountRepositoryProvider);
    final confirmed = await confirmRecordAction(
      context,
      title: 'Arquivar conta?',
      message:
          '${account.name} sairá das opções de novos lançamentos. O histórico será preservado.',
      action: 'Arquivar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await repo.archiveAccount(account.id!);
    } catch (error) {
      if (context.mounted) {
        showRecordError(context, error, 'Não foi possível arquivar a conta.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(allAccountsProvider);
    final theme = Theme.of(context);
    final size = WindowSizeClass.of(context);
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('Minhas contas'),
              actions: [
                IconButton(
                  tooltip: 'Cartões de crédito',
                  icon: const Icon(Symbols.credit_card_rounded),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreditCardsScreen(),
                    ),
                  ),
                ),
              ],
            ),
      body: AppContent(
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível carregar as contas.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(allAccountsProvider),
          ),
          data: (accounts) {
            final active = accounts.where((item) => item.isActive).toList();
            final archived = accounts.where((item) => !item.isActive).toList();
            final total = active.fold(
              BigInt.zero,
              (sum, item) => sum + BigInt.from(item.currentBalanceCents),
            );
            Widget cards(List<Account> items) => LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 3
                    : constraints.maxWidth >= 470
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: AccountCard(
                          account: item,
                          onTap: () =>
                              _showAccountForm(context, ref, account: item),
                          onArchive: item.isActive
                              ? () => _archiveAccount(context, ref, item)
                              : null,
                        ),
                      ),
                  ],
                );
              },
            );
            return ListView(
              key: const PageStorageKey('contas'),
              padding: AppLayout.pagePadding(context).copyWith(bottom: 88),
              children: [
                AppSurface(
                  child: Row(
                    children: [
                      const AppIcon(Symbols.account_balance_wallet_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo das contas ativas',
                              style: theme.textTheme.labelLarge,
                            ),
                            MoneyText.total(total, emphasis: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (active.isEmpty)
                  EmptyState(
                    title: 'Nenhuma conta ativa',
                    compact: true,
                    message: 'Adicione uma conta para acompanhar o saldo e registrar lançamentos.',
                    actionLabel: size == WindowSizeClass.compact
                        ? null
                        : 'Nova conta',
                    onAction: size == WindowSizeClass.compact
                        ? null
                        : () => _showAccountForm(context, ref),
                  )
                else
                  cards(active),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      title: Text('Contas arquivadas (${archived.length})'),
                      childrenPadding: const EdgeInsets.all(12),
                      children: [cards(archived)],
                    ),
                  ),
                ],
                if (size != WindowSizeClass.compact && active.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAccountForm(context, ref),
                      icon: const Icon(Symbols.add_rounded),
                      label: const Text('Nova conta'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: size == WindowSizeClass.compact
          ? FloatingActionButton.extended(
              heroTag: 'nova-conta',
              onPressed: () => _showAccountForm(context, ref),
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Nova conta'),
            )
          : null,
    );
  }
}
