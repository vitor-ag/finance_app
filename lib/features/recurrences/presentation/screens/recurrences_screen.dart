import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money.dart';
import '../../../../core/calendar.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/recurrence.dart';
import '../providers/recurrence_providers.dart';
import '../widgets/recurrence_tile.dart';

class RecurrencesScreen extends ConsumerWidget {
  const RecurrencesScreen({super.key});

  void _showAddRecurrenceDialog(BuildContext context, WidgetRef ref) {
    var nameInput = '';
    var amountInput = '';
    var limitInput = '';
    var saving = false;
    String selectedType = 'expense';
    String selectedFrequency = 'monthly';
    int? selectedAccountId;
    int? selectedCategoryId;
    DateTime selectedStartDate = calendarDate(DateTime.now());
    DateTime? selectedEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
          final categories =
              ref.watch(allCategoriesProvider()).valueOrNull ?? [];

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
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => nameInput = value,
                        decoration: const InputDecoration(
                          labelText: 'Nome (ex: Salário, Aluguel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'expense', label: Text('Saída')),
                          ButtonSegment(
                            value: 'income',
                            label: Text('Entrada'),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (selection) => setState(() {
                          selectedType = selection.first;
                          selectedCategoryId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
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
                      DropdownButtonFormField<int>(
                        initialValue: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Conta',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .where((account) => account.isActive)
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
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
                            .where(
                              (category) =>
                                  category.isActive &&
                                  category.type == selectedType,
                            )
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'monthly',
                            label: Text('Mensal'),
                          ),
                          ButtonSegment(
                            value: 'weekly',
                            label: Text('Semanal'),
                          ),
                          ButtonSegment(value: 'yearly', label: Text('Anual')),
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
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                          );
                          if (picked != null) {
                            if (!context.mounted) return;
                            setState(() {
                              selectedStartDate = picked;
                              if (selectedEndDate?.isBefore(picked) == true) {
                                selectedEndDate = null;
                              }
                            });
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data final (opcional)'),
                        subtitle: Text(
                          selectedEndDate == null
                              ? 'Sem data final'
                              : '${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}',
                        ),
                        trailing: selectedEndDate == null
                            ? const Icon(Icons.event_outlined)
                            : IconButton(
                                tooltip: 'Remover data final',
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => selectedEndDate = null),
                              ),
                        onTap: () async {
                          final end = await showDatePicker(
                            context: context,
                            firstDate: selectedStartDate,
                            lastDate: DateTime(selectedStartDate.year + 100),
                            initialDate: selectedEndDate ?? selectedStartDate,
                          );
                          if (context.mounted && end != null) {
                            setState(() => selectedEndDate = end);
                          }
                        },
                      ),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Limite de ocorrências (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => limitInput = value,
                      ),
                      const SizedBox(height: 20),
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
                                  final limit = int.tryParse(limitInput.trim());

                                  if (name.isEmpty ||
                                      name.length > 80 ||
                                      amountCents == null ||
                                      amountCents <= 0 ||
                                      selectedAccountId == null ||
                                      (limitInput.trim().isNotEmpty &&
                                          (limit == null || limit < 1))) {
                                    showRecordError(
                                      context,
                                      StateError(
                                        'Preencha os campos com valores válidos.',
                                      ),
                                      '',
                                    );
                                    return;
                                  }
                                  setState(() => saving = true);

                                  final newRecurrence = Recurrence(
                                    name: name,
                                    type: selectedType,
                                    amountCents: amountCents,
                                    accountId: selectedAccountId!,
                                    categoryId: selectedCategoryId,
                                    frequency: selectedFrequency,
                                    dayOfMonth:
                                        selectedFrequency == 'monthly' ||
                                            selectedFrequency == 'yearly'
                                        ? selectedStartDate.day
                                        : null,
                                    weekday: selectedFrequency == 'weekly'
                                        ? selectedStartDate.weekday
                                        : null,
                                    startDate: selectedStartDate,
                                    endDate: selectedEndDate,
                                    maxOccurrences: limit,
                                    nextOccurrenceDate: selectedStartDate,
                                    createdAt: DateTime.now(),
                                  );

                                  try {
                                    await ref
                                        .read(recurrenceRepositoryProvider)
                                        .createRecurrence(newRecurrence);
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    setState(() => saving = false);
                                    showRecordError(
                                      context,
                                      error,
                                      'Não foi possível salvar a recorrência.',
                                    );
                                  }
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
