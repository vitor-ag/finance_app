import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedType = 'expense';
    int? selectedAccountId;
    int? selectedDestinationAccountId;
    int? selectedCategoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
          final categoryType = selectedType == 'income' ? 'income' : 'expense';
          final categories = ref
                  .watch(allCategoriesProvider(type: categoryType))
                  .valueOrNull ??
              [];

          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo Lançamento',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'expense', label: Text('Saída')),
                          ButtonSegment(
                              value: 'income', label: Text('Entrada')),
                          ButtonSegment(
                              value: 'transfer',
                              label: Text('Transferência')),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (selection) => setState(() {
                          selectedType = selection.first;
                          selectedCategoryId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor (R\$)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedAccountId,
                        decoration: InputDecoration(
                          labelText: selectedType == 'transfer'
                              ? 'Conta de Origem'
                              : 'Conta',
                          border: const OutlineInputBorder(),
                        ),
                        items: accounts
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedAccountId = val),
                      ),
                      if (selectedType == 'transfer') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedDestinationAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Conta de Destino',
                            border: OutlineInputBorder(),
                          ),
                          items: accounts
                              .where((a) => a.id != selectedAccountId)
                              .map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(
                              () => selectedDestinationAccountId = val),
                        ),
                      ],
                      if (selectedType != 'transfer') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedCategoryId = val),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Observação (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () async {
                            final amount = double.tryParse(
                                  amountController.text
                                      .replaceAll(',', '.'),
                                ) ??
                                0.0;

                            if (amount <= 0 || selectedAccountId == null) {
                              return;
                            }
                            if (selectedType == 'transfer' &&
                                selectedDestinationAccountId == null) {
                              return;
                            }

                            final newTransaction = Transaction(
                              type: selectedType,
                              amount: amount,
                              date: DateTime.now(),
                              accountId: selectedAccountId!,
                              destinationAccountId: selectedType == 'transfer'
                                  ? selectedDestinationAccountId
                                  : null,
                              categoryId: selectedType != 'transfer'
                                  ? selectedCategoryId
                                  : null,
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              createdAt: DateTime.now(),
                            );

                            await ref
                                .read(transactionRepositoryProvider)
                                .createTransaction(newTransaction);

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Salvar Lançamento'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
    final expenseCategories =
        ref.watch(allCategoriesProvider(type: 'expense')).valueOrNull ?? [];
    final incomeCategories =
        ref.watch(allCategoriesProvider(type: 'income')).valueOrNull ?? [];
    final allCategories = [...expenseCategories, ...incomeCategories];

    String accountName(int id) =>
        accounts.firstWhere((a) => a.id == id,
                orElse: () => Account(
                    name: '-',
                    type: '-',
                    initialBalance: 0,
                    currentBalance: 0,
                    createdAt: DateTime.now()))
            .name;

    String? categoryName(int? id) {
      if (id == null) return null;
      final match = allCategories.where((c) => c.id == id);
      return match.isEmpty ? null : match.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lançamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum lançamento registrado',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionTile(
                  transaction: t,
                  accountName: accountName(t.accountId),
                  categoryName: categoryName(t.categoryId),
                  destinationAccountName: t.destinationAccountId != null
                      ? accountName(t.destinationAccountId!)
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento'),
      ),
    );
  }
}