import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';

Future<void> showGoalForm(BuildContext context, {Goal? goal}) =>
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoalForm(goal: goal),
    );

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.goal});

  final Goal? goal;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _form = GlobalKey<FormState>();
  late String _name;
  late String _target;
  String _reserve = '';
  late DateTime? _dueDate;
  late int? _accountId;
  bool _saving = false;
  late String? _icon = widget.goal?.icon;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = goal?.name ?? '';
    _target = goal == null ? '' : brlInput(goal.targetCents);
    _dueDate = goal?.dueDate;
    _accountId = goal?.accountId;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = ref.read(goalRepositoryProvider);
    final goal = Goal(
      id: widget.goal?.id,
      name: _name.trim(),
      targetCents: parseBrlCents(_target)!,
      dueDate: _dueDate,
      icon: _icon,
      savedCents: parseBrlCents(_reserve) ?? 0,
      accountId: _accountId,
    );
    try {
      if (widget.goal == null) {
        await repository.createGoal(goal);
      } else {
        await repository.updateGoal(goal);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showRecordError(context, error, 'Não foi possível salvar a meta.');
    }
  }

  String? _validateTarget(String? text) {
    final cents = parseBrlCents(text);
    return cents == null || cents <= 0
        ? 'Informe um valor-alvo maior que zero.'
        : null;
  }

  String? _validateReserve(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final cents = parseBrlCents(text);
    return cents == null || cents < 0
        ? 'Informe um valor igual ou maior que zero.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
    final eligibleAccounts = accounts.where(
      (account) => account.isActive || account.id == widget.goal?.accountId,
    );
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.goal == null ? 'Nova meta' : 'Editar meta',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                onChanged: (value) => _name = value,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome da meta'),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length == 0 || length > 80
                      ? 'Informe um nome com até 80 caracteres.'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor-alvo (R\$)',
                ),
                onChanged: (value) => _target = value,
                validator: _validateTarget,
              ),
              if (widget.goal == null) ...[
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Já reservado (R\$)',
                  ),
                  onChanged: (value) => _reserve = value,
                  validator: _validateReserve,
                ),
              ],
              const SizedBox(height: 12),
              FormField<DateTime>(
                initialValue: _dueDate,
                builder: (field) {
                  final date = field.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Symbols.event_rounded),
                        title: const Text('Prazo'),
                        trailing: date == null
                            ? null
                            : IconButton(
                                tooltip: 'Remover prazo',
                                icon: const Icon(Symbols.close_rounded),
                                onPressed: () {
                                  _dueDate = null;
                                  field.didChange(null);
                                },
                              ),
                        subtitle: Text(
                          date == null ? 'Selecionar data' : _dateLabel(date),
                        ),
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final initial = date ?? calendarDate(DateTime.now());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(initial.year - 50),
                            lastDate: DateTime(initial.year + 50, 12, 31),
                            helpText: 'Prazo da meta',
                            cancelText: 'Cancelar',
                            confirmText: 'Confirmar prazo',
                          );
                          if (picked != null && field.mounted) {
                            _dueDate = picked;
                            field.didChange(picked);
                          }
                        },
                      ),
                      if (field.errorText case final error?)
                        Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  );
                },
              ),
              DropdownButtonFormField<int>(
                initialValue:
                    eligibleAccounts.any((account) => account.id == _accountId)
                    ? _accountId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Conta de referência (opcional)',
                ),
                hint: const Text('Sem conta vinculada'),
                items: [
                  const DropdownMenuItem(child: Text('Sem conta vinculada')),
                  for (final account in eligibleAccounts)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                ],
                onChanged: (id) => setState(() => _accountId = id),
              ),
              ExpansionTile(
                title: const Text('Ícone da meta'),
                tilePadding: EdgeInsets.zero,
                children: [
                  IconPalette(
                    value: _icon,
                    onChanged: (icon) => setState(() => _icon = icon),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Salvar meta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
