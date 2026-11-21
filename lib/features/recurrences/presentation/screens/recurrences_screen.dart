import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/recurrence.dart';
import '../providers/recurrence_providers.dart';
import '../widgets/recurrence_tile.dart';

class RecurrencesScreen extends ConsumerWidget {
  const RecurrencesScreen({super.key});

  void _showAddRecurrenceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'expense';
    String selectedFrequency = 'monthly';
    int? selectedAccountId;
    int? selectedCategoryId;
    DateTime selectedStartDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
          final categories = ref.watch(allCategoriesProvider()).valueOrNull ??
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
                        'Nova Recorrência',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome (ex: Salário, Aluguel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'expense', label: Text('Saída')),
                          ButtonSegment(
                              value: 'income', label: Text('Entrada')),
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
                        decoration: const InputDecoration(
                          labelText: 'Conta',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .where((account) => account.isActive)
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedAccountId = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey(selectedType),
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .where((category) => category.isActive && category.type == selectedType)
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'monthly', label: Text('Mensal')),
                          ButtonSegment(
                              value: 'weekly', label: Text('Semanal')),
                          ButtonSegment(
                              value: 'yearly', label: Text('Anual')),
                        ],
                        selected: {selectedFrequency},
                        onSelectionChanged: (selection) =>
                            setState(() => selectedFrequency = selection.first),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Primeira ocorrência'),
                        subtitle: Text(
                          '${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year}',
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setState(() => selectedStartDate = picked);
                          }
                        },
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
                            final name = nameController.text.trim();

                            if (name.isEmpty ||
                                amount <= 0 ||
                                selectedAccountId == null) {
                              return;
                            }

                            final newRecurrence = Recurrence(
                              name: name,
                              type: selectedType,
                              amount: amount,
                              accountId: selectedAccountId!,
                              categoryId: selectedCategoryId,
                              frequency: selectedFrequency,
                              dayOfMonth: selectedFrequency == 'monthly' ||
                                      selectedFrequency == 'yearly'
                                  ? selectedStartDate.day
                                  : null,
                              weekday: selectedFrequency == 'weekly'
                                  ? selectedStartDate.weekday
                                  : null,
                              startDate: selectedStartDate,
                              nextOccurrenceDate: selectedStartDate,
                              createdAt: DateTime.now(),
                            );

                            await ref
                                .read(recurrenceRepositoryProvider)
                                .createRecurrence(newRecurrence);

                            // Immediately generate any occurrence that's
                            // already due (e.g. start date is today or past).
                            await ref
                                .read(recurrenceRepositoryProvider)
                                .generateDueOccurrences();

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Salvar Recorrência'),
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
    final recurrencesAsync = ref.watch(allRecurrencesProvider);
    final repo = ref.read(recurrenceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recorrências',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: recurrencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (recurrences) {
          if (recurrences.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma recorrência cadastrada',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recurrences.length,
            itemBuilder: (context, index) {
              final r = recurrences[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RecurrenceTile(
                  recurrence: r,
                  onPause: () => repo.pauseRecurrence(r.id!),
                  onResume: () => repo.resumeRecurrence(r.id!),
                  onCancel: () => repo.cancelRecurrence(r.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurrenceDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova Recorrência'),
      ),
    );
  }
}
