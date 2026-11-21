import 'package:flutter/material.dart';

import '../../../../core/money.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/record_actions.dart';
import '../../domain/entities/account.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

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
    const types = {
      'digital': 'Conta Digital',
      'checking': 'Conta Corrente',
      'savings': 'Poupança',
      'cash': 'Dinheiro / Carteira',
      'investment': 'Investimentos',
    };
    final repo = ref.read(accountRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
    final accountsAsync = ref.watch(allAccountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Contas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Erro ao carregar contas: $error')),
        data: (accounts) {
          final totalBalance = formatBrlTotal(
            accounts
                .where((item) => item.isActive)
                .map((item) => item.currentBalanceCents),
          );

          return CustomScrollView(
            slivers: [
              // Header com Saldo Consolidado
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Consolidado',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalBalance,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${accounts.where((account) => account.isActive).length} conta(s) ativa(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista ou Empty State
              if (accounts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma conta cadastrada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque no botão + para adicionar sua primeira conta.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final account = accounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AccountCard(
                          account: account,
                          onTap: () =>
                              _showAccountForm(context, ref, account: account),
                          onArchive: account.isActive
                              ? () => _archiveAccount(context, ref, account)
                              : null,
                        ),
                      );
                    }, childCount: accounts.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova Conta'),
      ),
    );
  }
}
