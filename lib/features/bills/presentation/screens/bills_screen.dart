import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/bill.dart';
import '../providers/bill_providers.dart';
import '../widgets/bill_tile.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _showBillForm(
    BuildContext context,
    WidgetRef ref, {
    Bill? bill,
  }) async {
    final repo = ref.read(billRepositoryProvider);
    var nameInput = bill?.name ?? '';
    var amountInput = bill == null ? '' : brlInput(bill.amountCents);
    String selectedBillType = bill?.billType ?? 'fixed';
    int? selectedCategoryId = bill?.categoryId;
    DateTime selectedDate =
        bill?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    var saving = false;

    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                        bill == null
                            ? 'Nova Conta a Pagar'
                            : 'Editar Conta a Pagar',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: nameInput,
                        onChanged: (value) => nameInput = value,
                        decoration: const InputDecoration(
                          labelText: 'Nome (ex: Aluguel, Internet)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: amountInput,
                        onChanged: (value) => amountInput = value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                            value: 'recurring',
                            label: Text('Recorrente'),
                          ),
                          ButtonSegment(
                            value: 'eventual',
                            label: Text('Eventual'),
                          ),
                        ],
                        selected: {selectedBillType},
                        onSelectionChanged: bill?.billType == 'recurring'
                            ? null
                            : (selection) => setState(
                                () => selectedBillType = selection.first,
                              ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue:
                            categories.any(
                              (item) => item.id == selectedCategoryId,
                            )
                            ? selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Sem categoria'),
                        items: [
                          const DropdownMenuItem(child: Text('Sem categoria')),
                          for (final category in categories)
                            if (category.isActive ||
                                category.id == bill?.categoryId)
                              DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                        ],
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
                        trailing: const Icon(
                          Symbols.calendar_today_rounded,
                          size: 18,
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(selectedDate.year - 1),
                            lastDate: DateTime(selectedDate.year + 4),
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
                          onPressed: saving
                              ? null
                              : () async {
                                  final amountCents = parseBrlCents(
                                    amountInput,
                                  );
                                  final name = nameInput.trim();

                                  if (name.isEmpty ||
                                      name.length > 80 ||
                                      amountCents == null ||
                                      amountCents <= 0) {
                                    showRecordError(
                                      context,
                                      StateError(
                                        'Informe um nome e um valor válido.',
                                      ),
                                      '',
                                    );
                                    return;
                                  }
                                  setState(() => saving = true);

                                  final newBill = Bill(
                                    id: bill?.id,
                                    name: name,
                                    categoryId: selectedCategoryId,
                                    amountCents: amountCents,
                                    dueDate: selectedDate,
                                    billType: selectedBillType,
                                    notes: bill?.notes,
                                    createdAt:
                                        bill?.createdAt ?? DateTime.now(),
                                  );

                                  try {
                                    if (bill == null) {
                                      await repo.createBill(newBill);
                                    } else {
                                      await repo.updateBill(newBill);
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
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmBillAction(
    BuildContext context,
    WidgetRef ref,
    Bill bill, {
    required bool stopRepeat,
  }) async {
    final repo = ref.read(billRepositoryProvider);
    final confirmed = await confirmRecordAction(
      context,
      title: stopRepeat ? 'Parar repetição mensal?' : 'Cancelar esta conta?',
      message: stopRepeat ? 'As contas já geradas permanecem na lista.' : 'A conta fica no histórico como cancelada. Uma eventual série mensal continua ativa.',
      action: stopRepeat ? 'Parar repetição' : 'Cancelar conta',
    );
    if (!confirmed || !context.mounted) return;
    try {
      if (stopRepeat) {
        await repo.stopRepeating(bill.id!);
      } else {
        await repo.cancelBill(bill.id!);
      }
    } catch (error) {
      if (context.mounted) {
        showRecordError(context, error, 'Não foi possível atualizar a conta.');
      }
    }
  }

  void _showMarkAsPaidDialog(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
    List<Account> accounts,
  ) {
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
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
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
                        await ref
                            .read(billRepositoryProvider)
                            .markAsPaid(
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
    final accounts = ref
        .watch(allAccountsProvider)
        .valueOrNull
        ?.where((account) => account.isActive)
        .toList();
    final expenseCategories =
        ref.watch(allCategoriesProvider(type: 'expense')).valueOrNull ?? [];

    String? categoryName(int? id) {
      if (id == null) return null;
      final match = expenseCategories.where((c) => c.id == id);
      return match.isEmpty ? null : match.first.name;
    }

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: const Text(
                'Contas a Pagar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
      body: AppContent(maxWidth: AppLayout.maxReading, child: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (bills) {
          if (bills.isEmpty) {
            return const SingleChildScrollView(child: EmptyState(
              title: 'Nenhuma conta a pagar cadastrada', icon: Symbols.event_rounded,
              message: 'Organize seus vencimentos em um só lugar.',
            ));
          }

          final sorted = [...bills]
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return ListView.builder(
            padding: AppLayout.pagePadding(context).copyWith(bottom: 88),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final bill = sorted[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BillTile(
                  bill: bill,
                  categoryName: categoryName(bill.categoryId),
                  onMarkAsPaid: accounts == null
                      ? null
                      : () =>
                            _showMarkAsPaidDialog(context, ref, bill, accounts),
                  onEdit: bill.status == 'pending'
                      ? () => _showBillForm(context, ref, bill: bill)
                      : null,
                  onCancel: bill.status == 'pending'
                      ? () => _confirmBillAction(
                          context,
                          ref,
                          bill,
                          stopRepeat: false,
                        )
                      : null,
                  onStopRepeat: bill.repeatDay != null
                      ? () => _confirmBillAction(
                          context,
                          ref,
                          bill,
                          stopRepeat: true,
                        )
                      : null,
                ),
              );
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'novo-conta-a-pagar',
        onPressed: () => _showBillForm(context, ref),
        icon: const Icon(Symbols.add_rounded),
        label: const Text('Nova Conta'),
      ),
    );
  }
}
