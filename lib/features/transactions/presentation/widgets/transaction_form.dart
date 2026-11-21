import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  Transaction? source,
  bool duplicate = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => TransactionForm(source: source, duplicate: duplicate),
  );
}

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.source, this.duplicate = false});

  final Transaction? source;
  final bool duplicate;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late DateTime _date;
  int? _accountId;
  int? _destinationId;
  int? _categoryId;
  int _amount = 0;
  String? _description;
  String? _incomeSource;
  bool _saving = false;

  Transaction? get _editing => widget.duplicate ? null : widget.source;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    _type = source?.type ?? 'expense';
    _date = source?.date ?? DateTime.now();
    _accountId = source?.accountId;
    _destinationId = source?.destinationAccountId;
    _categoryId = source?.categoryId;
  }

  Future<void> _pickDate() async {
    final first = DateTime(1900);
    final last = DateTime(2100, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(first) ? _date : first,
      lastDate: _date.isAfter(last) ? _date : last,
    );
    if (mounted && picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();
    setState(() => _saving = true);
    final repo = ref.read(transactionRepositoryProvider);
    final entry = Transaction(
      id: _editing?.id,
      type: _type,
      amountCents: _amount,
      date: _date,
      accountId: _accountId!,
      destinationAccountId: _type == 'transfer' ? _destinationId : null,
      categoryId: _type == 'transfer' ? null : _categoryId,
      description: _description,
      incomeSource: _type == 'income' ? _incomeSource : null,
      status: _editing?.status ?? 'paid',
      createdAt: _editing?.createdAt ?? DateTime.now(),
    );
    try {
      if (_editing == null) {
        await repo.createTransaction(entry);
      } else {
        await repo.updateTransaction(entry);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showRecordError(context, error, 'Não foi possível salvar o lançamento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
    final categoryType = _type == 'income' ? 'income' : 'expense';
    final categories =
        ref.watch(allCategoriesProvider(type: categoryType)).valueOrNull ?? [];
    final origins = accounts.where(
      (account) => account.isActive || account.id == _editing?.accountId,
    );
    final destinations = accounts.where(
      (account) =>
          account.id != _accountId &&
          (account.isActive || account.id == _editing?.destinationAccountId),
    );
    final choices = categories.where(
      (category) => category.isActive || category.id == _editing?.categoryId,
    );
    final isTransfer = _type == 'transfer';
    final title = switch ((widget.duplicate, _editing != null)) {
      (true, _) => 'Duplicar Lançamento',
      (_, true) => 'Editar Lançamento',
      _ => 'Novo Lançamento',
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Saída')),
                  ButtonSegment(value: 'income', label: Text('Entrada')),
                  ButtonSegment(
                    value: 'transfer',
                    label: Text('Transferência'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => setState(() {
                  _type = selection.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.source == null
                    ? null
                    : brlInput(widget.source!.amountCents),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (text) {
                  final value = parseBrlCents(text);
                  return value == null || value <= 0
                      ? 'Informe um valor maior que zero.'
                      : null;
                },
                onSaved: (text) => _amount = parseBrlCents(text)!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: origins.any((item) => item.id == _accountId)
                    ? _accountId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isTransfer ? 'Conta de Origem' : 'Conta',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final account in origins)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                ],
                validator: (id) => origins.any((item) => item.id == id)
                    ? null
                    : 'Selecione uma conta.',
                onChanged: (id) => setState(() {
                  _accountId = id;
                  if (_destinationId == id) _destinationId = null;
                }),
              ),
              const SizedBox(height: 12),
              if (isTransfer)
                DropdownButtonFormField<int>(
                  key: ValueKey(_accountId),
                  initialValue:
                      destinations.any((item) => item.id == _destinationId)
                      ? _destinationId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Conta de Destino',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final account in destinations)
                      DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                  ],
                  validator: (id) => destinations.any((item) => item.id == id)
                      ? null
                      : 'Selecione uma conta de destino.',
                  onChanged: (id) => setState(() => _destinationId = id),
                )
              else
                DropdownButtonFormField<int>(
                  key: ValueKey(categoryType),
                  initialValue: choices.any((item) => item.id == _categoryId)
                      ? _categoryId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Sem categoria'),
                  items: [
                    const DropdownMenuItem(child: Text('Sem categoria')),
                    for (final category in choices)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (id) => setState(() => _categoryId = id),
                  onSaved: (_) {
                    if (!choices.any((item) => item.id == _categoryId)) {
                      _categoryId = null;
                    }
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.source?.description,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  final text = value!.trim();
                  _description = text.isEmpty ? null : text;
                },
              ),
              if (_type == 'income') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _incomeSource ?? widget.source?.incomeSource,
                  decoration: const InputDecoration(
                    labelText: 'Fonte da receita (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _incomeSource = value,
                  onSaved: (value) => _incomeSource = value?.trim(),
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do lançamento'),
                subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Salvar Lançamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
