import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/calendar.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/recurrence.dart';
import '../providers/recurrence_providers.dart';
import '../widgets/recurrence_tile.dart';
import '../../../bills/presentation/providers/bill_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class RecurrencesScreen extends ConsumerWidget {
  const RecurrencesScreen({super.key, this.embedded = false});

  final bool embedded;

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

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        trailing: const Icon(
                          Symbols.calendar_today_rounded,
                          size: 18,
                        ),
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
                            ? const Icon(Symbols.event_rounded)
                            : IconButton(
                                tooltip: 'Remover data final',
                                icon: const Icon(Symbols.clear_rounded),
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

  Future<void> _edit(BuildContext context, WidgetRef ref, Recurrence item) =>
      showAppBottomSheet<void>(
        context: context,
        builder: (_) => _EditRecurrence(item: item),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(allRecurrencesProvider);
    final bills = ref.watch(allBillsProvider).valueOrNull ?? [];
    final entries = ref.watch(allTransactionsProvider).valueOrNull ?? [];
    final repo = ref.read(recurrenceRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Recorrências')),
      body: AppContent(
        maxWidth: AppLayout.maxReading,
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            title: 'Não foi possível carregar as recorrências.',
            actionLabel: 'Tentar novamente',
            onAction: () => ref.invalidate(allRecurrencesProvider),
          ),
          data: (recurrences) {
            final today = DateUtils.dateOnly(DateTime.now());
            final end = DateTime(today.year, today.month, today.day + 30);
            final upcoming =
                [
                      for (final item in recurrences)
                        if (item.status == 'active')
                          (
                            item.nextOccurrenceDate,
                            item.name,
                            item.amountCents,
                            'Recorrência',
                          ),
                      for (final item in bills)
                        if (item.status == 'pending')
                          (
                            item.dueDate,
                            item.name,
                            item.amountCents,
                            'Conta a pagar',
                          ),
                      for (final item in entries)
                        if (item.status == 'pending')
                          (
                            item.date,
                            item.description ?? 'Lançamento',
                            item.amountCents,
                            'Agendado',
                          ),
                    ]
                    .where(
                      (item) =>
                          !item.$1.isBefore(today) && item.$1.isBefore(end),
                    )
                    .toList()
                  ..sort((a, b) => a.$1.compareTo(b.$1));
            final active = recurrences.where(
              (item) => item.status == 'active' || item.status == 'paused',
            );
            final finished = recurrences.where(
              (item) => item.status != 'active' && item.status != 'paused',
            );
            Widget row(Recurrence item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RecurrenceTile(
                recurrence: item,
                onPause: item.status == 'active'
                    ? () =>
                          _change(context, () => repo.pauseRecurrence(item.id!))
                    : null,
                onResume: item.status == 'paused'
                    ? () => _change(
                        context,
                        () => repo.resumeRecurrence(item.id!),
                      )
                    : null,
                onEdit: item.status == 'active' || item.status == 'paused'
                    ? () => _edit(context, ref, item)
                    : null,
                onCancel: item.status == 'active' || item.status == 'paused'
                    ? () async {
                        final confirmed = await confirmRecordAction(
                          context,
                          title: 'Encerrar recorrência?',
                          message: 'Os lançamentos que já foram gerados serão preservados.',
                          action: 'Encerrar',
                        );
                        if (confirmed && context.mounted)
                          await _change(
                            context,
                            () => repo.cancelRecurrence(item.id!),
                          );
                      }
                    : null,
              ),
            );
            return ListView(
              key: const PageStorageKey('recorrências'),
              padding: AppLayout.pagePadding(context).copyWith(bottom: 88),
              children: [
                Text('Próximos 30 dias', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                AppSurface(
                  child: upcoming.isEmpty
                      ? const Text('Nada agendado para os próximos 30 dias.')
                      : Column(
                          children: [
                            for (final (date, label, cents, source) in upcoming)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat.d('pt_BR').format(date),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      DateFormat.MMM('pt_BR').format(date),
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                                title: Text(label),
                                subtitle: Text(source),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 104,
                                  ),
                                  child: MoneyText(cents),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                Text('Recorrências ativas', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (recurrences.isEmpty)
                  const EmptyState(
                    title: 'Nenhuma recorrência cadastrada',
                    icon: Symbols.event_repeat_rounded,
                    compact: true,
                  )
                else ...[
                  if (active.isEmpty) const Text('Nenhuma recorrência ativa.'),
                  for (final item in active) row(item),
                  if (finished.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Recorrências encerradas'),
                      children: [for (final item in finished) row(item)],
                    ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nova-recorrencia',
        onPressed: () => _showAddRecurrenceDialog(context, ref),
        icon: const Icon(Symbols.add_rounded),
        label: const Text('Nova Recorrência'),
      ),
    );
  }

  Future<void> _change(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted)
        showRecordError(
          context,
          error,
          'Não foi possível atualizar a recorrência.',
        );
    }
  }
}

class _EditRecurrence extends ConsumerStatefulWidget {
  const _EditRecurrence({required this.item});
  final Recurrence item;

  @override
  ConsumerState<_EditRecurrence> createState() => _EditRecurrenceState();
}

class _EditRecurrenceState extends ConsumerState<_EditRecurrence> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.item.name;
  late String _amount = brlInput(widget.item.amountCents);
  late DateTime? _end = widget.item.endDate;
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar recorrência',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              onChanged: (value) => _name = value,
              validator: (value) =>
                  _name.trim().isEmpty ? 'Informe um nome.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _amount,
              decoration: const InputDecoration(labelText: r'Valor (R$)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _amount = value,
              validator: (value) => (parseBrlCents(_amount) ?? 0) <= 0
                  ? 'Informe um valor maior que zero.'
                  : null,
            ),
            ListTile(
              title: const Text('Término'),
              subtitle: Text(
                _end == null
                    ? 'Sem data final'
                    : DateFormat.yMd('pt_BR').format(_end!),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _end ?? widget.item.startDate,
                  firstDate: widget.item.startDate,
                  lastDate: DateTime(2100, 12, 31),
                );
                if (mounted && date != null) setState(() => _end = date);
              },
            ),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _busy = true);
                      try {
                        await ref
                            .read(recurrenceRepositoryProvider)
                            .updateRecurrence(
                              widget.item.copyWith(
                                name: _name.trim(),
                                amountCents: parseBrlCents(_amount),
                                endDate: _end,
                              ),
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (error) {
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        showRecordError(
                          context,
                          error,
                          'Não foi possível atualizar a recorrência.',
                        );
                      }
                    },
              child: const Text('Salvar recorrência'),
            ),
          ],
        ),
      ),
    ),
  );
}
