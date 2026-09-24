import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/bill.dart';
import '../providers/bill_providers.dart';
import '../widgets/bill_tile.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  void _showAddBillDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedBillType = 'fixed';
    int? selectedCategoryId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final categories =
              ref.watch(allCategoriesProvider(type: 'expense')).valueOrNull ??
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
                        'Nova Conta a Pagar',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome (ex: Aluguel, Internet)',
                          border: OutlineInputBorder(),
                        ),
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
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'fixed', label: Text('Fixa')),
                          ButtonSegment(
                              value: 'recurring', label: Text('Recorrente')),
                          ButtonSegment(
                              value: 'eventual', label: Text('Eventual')),
                        ],
                        selected: {selectedBillType},
                        onSelectionChanged: (selection) =>
                            setState(() => selectedBillType = selection.first),
                      ),
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
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data de Vencimento'),
                        subtitle: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
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
                            final name = nameController.text.trim();

                            if (name.isEmpty || amount <= 0) return;

                            final newBill = Bill(
                              name: name,
                              categoryId: selectedCategoryId,
                              amount: amount,
                              dueDate: selectedDate,
                              billType: selectedBillType,
                              createdAt: DateTime.now(),
                            );

                            await ref
                                .read(billRepositoryProvider)
                                .createBill(newBill);

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Salvar Conta'),
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

  void _showMarkAsPaidDialog(BuildContext context, WidgetRef ref, Bill bill) {
    final accounts = ref.read(allAccountsProvider).valueOrNull ?? [];
    int? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Marcar como paga'),
            content: DropdownButtonFormField<int>(
              initialValue: selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Pagar com qual conta?',
                border: OutlineInputBorder(),
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => selectedAccountId = val),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: selectedAccountId == null
                    ? null
                    : () async {
                        await ref.read(billRepositoryProvider).markAsPaid(
                              bill.id!,
                              paymentAccountId: selectedAccountId!,
                            );
                        if (context.mounted) Navigator.pop(ctx);
                      },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(allBillsProvider);
    final expenseCategories =
        ref.watch(allCategoriesProvider(type: 'expense')).valueOrNull ?? [];

    String? categoryName(int? id) {
      if (id == null) return null;
      final match = expenseCategories.where((c) => c.id == id);
      return match.isEmpty ? null : match.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contas a Pagar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma conta a pagar cadastrada',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          final sorted = [...bills]
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final bill = sorted[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BillTile(
                  bill: bill,
                  categoryName: categoryName(bill.categoryId),
                  onMarkAsPaid: () =>
                      _showMarkAsPaidDialog(context, ref, bill),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova Conta'),
      ),
    );
  }
}