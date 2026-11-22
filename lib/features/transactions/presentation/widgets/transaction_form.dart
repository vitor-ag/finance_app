import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/amount_keypad.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/record_actions.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../recurrences/domain/entities/recurrence.dart';
import '../../../recurrences/presentation/providers/recurrence_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  Transaction? source,
  bool duplicate = false,
  String type = 'expense',
  ValueChanged<int>? onSaved,
}) async {
  final result = await showAppBottomSheet<_SavedEntry>(
    context: context,
    fullScreen: true,
    builder: (_) =>
        TransactionForm(source: source, duplicate: duplicate, type: type),
  );
  if (!context.mounted || result == null) return;
  if (result.id case final id?) onSaved?.call(id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Lançamento salvo'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'Desfazer', onPressed: result.undo),
    ),
  );
}

typedef _SavedEntry = ({int? id, VoidCallback undo});

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    this.source,
    this.duplicate = false,
    this.type = 'expense',
  });
  final Transaction? source;
  final bool duplicate;
  final String type;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _form = GlobalKey<FormState>();
  final _amountFocus = FocusNode();
  late final TextEditingController _amount, _description, _note, _source;
  late String _type;
  late DateTime _date;
  late String? _photo;
  late bool _paid;
  int? _accountId, _destinationId, _categoryId;
  String? _frequency;
  DateTime? _until;
  bool _saving = false;
  bool? _keypad;

  Transaction? get _editing => widget.duplicate ? null : widget.source;

  @override
  void initState() {
    super.initState();
    final entry = widget.source;
    _type = entry?.type ?? widget.type;
    _date = widget.duplicate ? DateTime.now() : entry?.date ?? DateTime.now();
    _accountId = entry?.accountId;
    _destinationId = entry?.destinationAccountId;
    _categoryId = entry?.categoryId;
    _photo = entry?.photo;
    _paid = entry?.status != 'pending';
    _amount = TextEditingController(
      text: entry == null ? '' : brlInput(entry.amountCents),
    );
    _description = TextEditingController(text: entry?.description);
    _note = TextEditingController(text: entry?.note);
    _source = TextEditingController(text: entry?.incomeSource);
    _amount.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _amount.removeListener(_changed);
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    _source.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate({bool end = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: end ? _until ?? _date : _date,
      firstDate: end ? DateUtils.dateOnly(_date) : DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (mounted && picked != null)
      setState(() {
        if (end) {
          _until = picked;
        } else {
          _date = picked;
          if (_until?.isBefore(DateUtils.dateOnly(_date)) == true)
            _until = null;
        }
      });
  }

  Future<void> _attach() async {
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
        withReadStream: true,
      );
      final file = files?.files.single;
      if (file == null) return;
      if (file.size > 2 * 1024 * 1024 || file.readStream == null) {
        throw StateError('Escolha uma foto de até 2 MB.');
      }
      final data = await file.readStream!
          .expand((bytes) => bytes)
          .take(2 * 1024 * 1024 + 1)
          .toList();
      if (data.length > 2 * 1024 * 1024)
        throw StateError('Escolha uma foto de até 2 MB.');
      if (mounted) setState(() => _photo = base64Encode(data));
    } catch (error) {
      if (mounted)
        showRecordError(context, error, 'Não foi possível anexar a foto.');
    }
  }

  String? _text(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save(int account) async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(transactionRepositoryProvider);
    final schedules = ref.read(recurrenceRepositoryProvider);
    final previous = _editing;
    final entry = Transaction(
      id: _editing?.id,
      type: _type,
      amountCents: parseBrlCents(_amount.text)!,
      date: _date,
      accountId: account,
      destinationAccountId: _type == 'transfer' ? _destinationId : null,
      categoryId: _type == 'transfer' ? null : _categoryId,
      description: _text(_description),
      note: _text(_note),
      photo: _photo,
      incomeSource: _type == 'income' ? _text(_source) : null,
      status: _editing?.status == 'cancelled'
          ? 'cancelled'
          : _paid
          ? 'paid'
          : 'pending',
      recurrenceId: _editing?.recurrenceId,
      createdAt: _editing?.createdAt ?? DateTime.now(),
    );
    try {
      late final Future<void> Function() undo;
      int? savedId;
      if (previous != null) {
        await repo.updateTransaction(entry);
        savedId = previous.id;
        undo = () => repo.updateTransaction(previous);
      } else if (_frequency case final frequency?) {
        final id = await schedules.createRecurrence(
          Recurrence(
            name: entry.description ?? 'Lançamento recorrente',
            type: entry.type,
            amountCents: entry.amountCents,
            accountId: entry.accountId,
            destinationAccountId: entry.destinationAccountId,
            categoryId: entry.categoryId,
            description: entry.description,
            frequency: frequency,
            startDate: entry.date,
            endDate: _until,
            nextOccurrenceDate: entry.date,
            createdAt: entry.createdAt,
          ),
          first: entry,
        );
        undo = () => repo.deleteRecurrenceEntries(id);
      } else {
        final id = await repo.createTransaction(entry);
        savedId = id;
        undo = () => repo.deleteTransaction(id);
      }
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop<_SavedEntry>(context, (
        id: savedId,
        undo: () async {
          try {
            await undo();
          } catch (_) {
            if (messenger.mounted)
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível desfazer o lançamento.'),
                ),
              );
          }
        },
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showRecordError(context, error, 'Não foi possível salvar o lançamento.');
    }
  }

  void _key(String key) {
    final value = _amount.text;
    if (key == '⌫') {
      if (value.isNotEmpty) _amount.text = value.substring(0, value.length - 1);
      return;
    }
    final next = value + key;
    if (RegExp(r'^\d{1,14}([,.]\d{0,2})?$').hasMatch(next)) _amount.text = next;
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
  }

  Future<void> _pickCategory(List<Category> choices) async {
    final selected = await showAppBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Categoria', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in choices)
                    CategoryChip(
                      category: item,
                      selected: item.id == _categoryId,
                      onSelected: (_) => Navigator.pop(context, item.id),
                    ),
                ],
              ),
              if (_categoryId != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, 0),
                  child: const Text('Limpar categoria'),
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted && selected != null)
      setState(() => _categoryId = selected == 0 ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider);
    final list = accounts.valueOrNull ?? <Account>[];
    final transfer = _type == 'transfer';
    final categories = ref.watch(
      allCategoriesProvider(type: _type == 'income' ? 'income' : 'expense'),
    );
    final choices = (categories.valueOrNull ?? <Category>[])
        .where((item) => item.isActive || item.id == _editing?.categoryId)
        .toList();
    final origins = list
        .where((item) => item.isActive || item.id == _editing?.accountId)
        .toList();
    final origin =
        origins.where((item) => item.id == _accountId).firstOrNull ??
        origins.firstOrNull;
    final destinations = list
        .where(
          (item) =>
              item.id != origin?.id &&
              (item.isActive || item.id == _editing?.destinationAccountId),
        )
        .toList();
    final destination = destinations
        .where((item) => item.id == _destinationId)
        .firstOrNull;
    final category = choices
        .where((item) => item.id == _categoryId)
        .firstOrNull;
    final ready =
        (parseBrlCents(_amount.text) ?? 0) > 0 &&
        origin != null &&
        (transfer
            ? destination != null
            : categories.hasValue &&
                  (choices.isEmpty ||
                      category != null ||
                      _editing?.categoryId == null && _editing != null));
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final color = switch (_type) {
      'income' => colors.incomeText,
      'expense' => colors.expenseText,
      _ => theme.colorScheme.primary,
    };
    final keypad =
        _keypad ??
        (theme.platform == TargetPlatform.android ||
            theme.platform == TargetPlatform.iOS);
    final title = widget.duplicate
        ? 'Duplicar lançamento'
        : _editing == null
        ? 'Novo lançamento'
        : 'Editar lançamento';
    final dates = DateFormat.yMd('pt_BR');
    final formFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!transfer && choices.isNotEmpty) ...[
                Text('Categoria', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final option in <Category>{
                      if (category != null) category,
                      ...choices.take(3),
                    })
                      CategoryChip(
                        category: option,
                        selected: _categoryId == option.id,
                        onSelected: (value) => setState(
                          () => _categoryId = value ? option.id : null,
                        ),
                      ),
                    if (choices.length > 3)
                      ActionChip(
                        label: const Text('Todas as categorias'),
                        avatar: const Icon(Symbols.grid_view_rounded, size: 20),
                        onPressed: () => _pickCategory(choices),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              if (!transfer && categories.hasError)
                const Text('Não foi possível carregar as categorias.'),
              if (accounts.hasError)
                const Text('Não foi possível carregar as contas.')
              else if (accounts.isLoading && list.isEmpty)
                const LinearProgressIndicator()
              else if (origins.isEmpty)
                const Text(
                  'Crie uma conta em Ajustes para registrar um lançamento.',
                )
              else
                DropdownButtonFormField<int>(
                  key: ValueKey((transfer, origin?.id)),
                  initialValue: origin?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: transfer ? 'Conta de origem' : 'Conta',
                  ),
                  items: [
                    for (final item in origins)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (id) => setState(() {
                    _accountId = id;
                    if (_destinationId == id) _destinationId = null;
                  }),
                ),
              if (transfer) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey((origin?.id, destination?.id)),
                  initialValue: destination?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Conta de destino',
                  ),
                  items: [
                    for (final item in destinations)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (id) => setState(() => _destinationId = id),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do lançamento'),
                subtitle: Text(dates.format(_date)),
                trailing: const Icon(Symbols.event_rounded),
                onTap: () => _pickDate(),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final (label, offset) in [('Hoje', 0), ('Ontem', -1)])
                    ActionChip(
                      label: Text(label),
                      onPressed: () => setState(() {
                        final now = DateTime.now();
                        _date = DateTime(now.year, now.month, now.day + offset);
                        if (_until?.isBefore(_date) == true) _until = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
              ),
              if (_type == 'income') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _source,
                  decoration: const InputDecoration(
                    labelText: 'Fonte da receita (opcional)',
                  ),
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _photo == null
                      ? Symbols.attach_file_rounded
                      : Symbols.image_rounded,
                ),
                title: Text(_photo == null ? 'Anexar foto' : 'Foto anexada'),
                onTap: _attach,
                trailing: _photo == null
                    ? null
                    : IconButton(
                        tooltip: 'Remover foto',
                        icon: const Icon(Symbols.close_rounded),
                        onPressed: () => setState(() => _photo = null),
                      ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Já foi pago'),
          subtitle: Text(
            _paid ? 'Entra no saldo da conta.' : 'Fica como agendado.',
          ),
          value: _paid,
          onChanged: _editing?.status == 'cancelled'
              ? null
              : (value) => setState(() => _paid = value),
        ),
        if (_editing == null) ...[
          SwitchListTile(
            title: const Text('Repetir'),
            value: _frequency != null,
            onChanged: (value) =>
                setState(() => _frequency = value ? 'monthly' : null),
          ),
          if (_frequency != null) ...[
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequência'),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                DropdownMenuItem(value: 'yearly', child: Text('Anual')),
              ],
              onChanged: (value) => setState(() => _frequency = value),
            ),
            ListTile(
              title: const Text('Término'),
              subtitle: Text(
                _until == null ? 'Sem data final' : dates.format(_until!),
              ),
              onTap: () => _pickDate(end: true),
              trailing: _until == null
                  ? null
                  : IconButton(
                      tooltip: 'Limpar término',
                      onPressed: () => setState(() => _until = null),
                      icon: const Icon(Symbols.close_rounded),
                    ),
            ),
          ],
        ],
      ],
    );
    final amountPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _amount,
          focusNode: _amountFocus,
          keyboardType: keypad
              ? TextInputType.none
              : const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(color: color),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            LengthLimitingTextInputFormatter(17),
          ],
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            hintText: '0,00',
            suffixIcon: IconButton(
              tooltip: keypad
                  ? 'Usar teclado do aparelho'
                  : 'Mostrar teclado de valores',
              icon: const Icon(Symbols.keyboard_rounded),
              onPressed: () => setState(() {
                _keypad = !keypad;
                if (keypad) _amountFocus.requestFocus();
              }),
            ),
          ),
        ),
        if (keypad)
          AmountKeypad(
            onKey: _key,
            onDone: () => setState(() => _keypad = false),
          ),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      style: theme.textTheme.titleLarge!.copyWith(color: color),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      child: Text(title),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final (type, label) in [
                            ('expense', 'Despesa'),
                            ('income', 'Receita'),
                            ('transfer', 'Transferência'),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected: _type == type,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() {
                                    _type = type;
                                    _categoryId = null;
                                  });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, limits) {
                          final columns =
                              (WindowSizeClass.wide(context) ||
                                  MediaQuery.sizeOf(context).height < 480) &&
                              limits.maxWidth >= 460;
                          return columns
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: amountPanel),
                                    const SizedBox(width: 12),
                                    Expanded(child: formFields),
                                  ],
                                )
                              : Column(
                                  children: [
                                    amountPanel,
                                    const SizedBox(height: 12),
                                    formFields,
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: ready && !_saving ? () => _save(origin.id!) : null,
                  child: Text(_saving ? 'Salvando…' : 'Salvar lançamento'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
