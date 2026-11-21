import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_tile.dart';

enum _EntryAction { edit, duplicate, delete }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showTrash = false;

  Future<void> _openForm({Transaction? source, bool duplicate = false}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransactionForm(source: source, duplicate: duplicate),
    );
  }

  Future<void> _showActions(
    Transaction entry, {
    required bool isBillPayment,
  }) async {
    if (_showTrash) {
      await _changeTrashStatus(entry, restore: true);
      return;
    }
    final action = await showModalBottomSheet<_EntryAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isBillPayment)
              const ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('Pagamento vinculado a uma conta a pagar'),
              ),
            if (!isBillPayment)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(context, _EntryAction.edit),
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicar'),
              onTap: () => Navigator.pop(context, _EntryAction.duplicate),
            ),
            if (!isBillPayment)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Mover para a lixeira'),
                onTap: () => Navigator.pop(context, _EntryAction.delete),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _EntryAction.edit:
        await _openForm(source: entry);
      case _EntryAction.duplicate:
        await _openForm(source: entry, duplicate: true);
      case _EntryAction.delete:
        await _changeTrashStatus(entry, restore: false);
    }
  }

  Future<void> _changeTrashStatus(
    Transaction entry, {
    required bool restore,
  }) async {
    final confirmed = await confirmRecordAction(
      context,
      title: restore
          ? 'Restaurar lançamento?'
          : 'Mover lançamento para a lixeira?',
      message: restore
          ? 'O lançamento volta ao histórico e seu efeito no saldo é reaplicado.'
          : 'O lançamento pode ser restaurado depois. Seu efeito no saldo será estornado.',
      action: restore ? 'Restaurar' : 'Mover para a lixeira',
    );
    if (!confirmed || !mounted) return;
    final repo = ref.read(transactionRepositoryProvider);
    try {
      if (restore) {
        await repo.restoreTransaction(entry.id!);
      } else {
        await repo.deleteTransaction(entry.id!);
      }
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível atualizar o lançamento.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      _showTrash ? deletedTransactionsProvider : allTransactionsProvider,
    );
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
    final categories = ref.watch(allCategoriesProvider()).valueOrNull ?? [];
    final bills = ref.watch(allBillsProvider).valueOrNull ?? [];
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final billPayments = {for (final bill in bills) bill.paidTransactionId};

    return Scaffold(
      appBar: AppBar(
        title: Text(_showTrash ? 'Lixeira' : 'Lançamentos'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _showTrash ? 'Voltar ao histórico' : 'Abrir lixeira',
            icon: Icon(_showTrash ? Icons.history : Icons.delete_outline),
            onPressed: () => setState(() => _showTrash = !_showTrash),
          ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Erro ao carregar lançamentos.')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text(
                _showTrash ? 'Lixeira vazia' : 'Nenhum lançamento registrado',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final entry = transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionTile(
                  transaction: entry,
                  accountName: accountNames[entry.accountId] ?? '-',
                  categoryName: categoryNames[entry.categoryId],
                  destinationAccountName:
                      accountNames[entry.destinationAccountId],
                  onTap: () => _showActions(
                    entry,
                    isBillPayment: billPayments.contains(entry.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _showTrash
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Novo Lançamento'),
            ),
    );
  }
}
